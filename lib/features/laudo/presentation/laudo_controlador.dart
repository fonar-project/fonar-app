import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/banco/novo_id.dart';
import '../../../core/relogio.dart';
import '../../analise/domain/resultado_da_analise.dart';
import '../../../design_system/tokens/app_cores.dart';
import '../data/repositorio_laudos_local.dart';
import '../domain/conteudo_do_laudo.dart';
import '../domain/laudo.dart';
import 'pdf_do_laudo.dart';
import 'sincronizacao_dos_laudos_controlador.dart';

class EstadoDoLaudo {
  const EstadoDoLaudo({
    this.laudo,
    this.anteriores = const [],
    this.gerando = false,
    this.falhou = false,
  });

  /// O laudo vigente desta análise — o emitido por último —, ou `null` se
  /// nunca foi emitido.
  final Laudo? laudo;

  /// Os que o vigente substituiu, do mais recente ao mais antigo. Continuam
  /// guardados como foram emitidos (US38).
  final List<Laudo> anteriores;
  final bool gerando;

  /// A última tentativa de gerar não deu certo.
  final bool falhou;

  EstadoDoLaudo copiar({bool? gerando, bool? falhou}) => EstadoDoLaudo(
    laudo: laudo,
    anteriores: anteriores,
    gerando: gerando ?? this.gerando,
    falhou: falhou ?? this.falhou,
  );
}

/// O que a tela precisa saber para montar o documento de uma emissão.
typedef Emissao = ({String id, DateTime geradoEm, Laudo? anterior});

/// O laudo de UMA análise.
class LaudoControlador extends AsyncNotifier<EstadoDoLaudo> {
  LaudoControlador(this.analiseId);

  final String analiseId;

  @override
  Future<EstadoDoLaudo> build() async {
    final emitidos = await ref
        .read(repositorioLaudosProvider)
        .emitidosDaAnalise(analiseId);
    return EstadoDoLaudo(
      laudo: emitidos.firstOrNull,
      anteriores: emitidos.skip(1).toList(),
    );
  }

  /// Emite um laudo novo com a [conclusao] de agora: gera o PDF e o
  /// registra, sem tocar nos anteriores. Devolve o laudo, ou `null` se não
  /// deu.
  ///
  /// [montar] recebe o código do documento, a hora da emissão e o laudo que
  /// o novo substitui — tudo vai impresso — e devolve o conteúdo.
  ///
  /// Quem confere se PODE gerar é a tela, com `conferirLaudo`, antes de
  /// chamar — o botão fica desabilitado, dizendo por quê.
  Future<Laudo?> gerar({
    required String pacienteId,
    required String conclusao,
    required Future<ConteudoDoLaudo> Function(Emissao emissao) montar,
  }) async {
    final atual = state.value;
    if (atual == null || atual.gerando) return null;
    state = AsyncData(atual.copiar(gerando: true, falhou: false));
    try {
      // Lidos antes das esperas: com a tela fechada no meio da geração, o
      // `ref` deste controlador já foi descartado (revisão de 23/09).
      final container = ref.container;
      final repositorio = ref.read(repositorioLaudosProvider);
      final gerador = ref.read(geradorDePdfProvider);
      final geradoEm = ref.read(relogioProvider)();
      final anterior = atual.laudo;
      final id = novoId();
      final conteudo = await montar((
        id: id,
        geradoEm: geradoEm,
        anterior: anterior,
      ));
      // A conferência vale aqui também, e não só no botão da tela: laudo de
      // um paciente não sai com o conteúdo de outro.
      if (conteudo.pacienteId != pacienteId) {
        throw const AnaliseDeOutroPaciente();
      }
      final pdf = await gerador(conteudo);
      final laudo = Laudo(
        id: id,
        analiseId: analiseId,
        pacienteId: pacienteId,
        conclusao: conclusao.trim(),
        geradoEm: geradoEm,
        pdf: pdf,
        substitui: anterior?.id,
      );
      await repositorio.registrar(laudo);
      // O perfil do paciente, embaixo na pilha, passa a mostrar o laudo.
      container.invalidate(laudosDoPacienteProvider(pacienteId));
      // A cópia sobe para a API quando der. Quem mantém a sincronização viva
      // é o `FonarApp`; sem ele (num teste da tela), não há o que pedir.
      if (container.exists(sincronizacaoDosLaudosControladorProvider)) {
        container
            .read(sincronizacaoDosLaudosControladorProvider.notifier)
            .pedir();
      }
      if (ref.mounted) {
        state = AsyncData(
          EstadoDoLaudo(
            laudo: laudo,
            anteriores: [?anterior, ...atual.anteriores],
          ),
        );
      }
      return laudo;
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(atual.copiar(gerando: false, falhou: true));
      }
      return null;
    }
  }
}

final laudoControladorProvider = AsyncNotifierProvider.autoDispose
    .family<LaudoControlador, EstadoDoLaudo, String>(LaudoControlador.new);

/// Quem transforma o conteúdo em PDF. Trocável nos testes de tela, que não
/// precisam montar o documento de verdade — ele tem teste próprio.
final geradorDePdfProvider =
    Provider<Future<Uint8List> Function(ConteudoDoLaudo)>(
      (ref) => gerarPdfDoLaudo,
    );

/// A pré-visualização A4 do desktop.
///
/// É o próprio PDF, rasterizado pelo `printing` — o que se vê é o que sai, e
/// não uma imitação em widgets que poderia divergir do documento. Trocável
/// nos testes, onde não há o rasterizador nativo.
final previaDoPdfProvider =
    Provider<Widget Function(Future<Uint8List> Function() gerar)>(
      (ref) =>
          (gerar) => Builder(
            builder: (context) => PdfPreview(
              build: (_) => gerar(),
              useActions: false,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 640,
              // A folha continua branca; em volta dela, a cor do tema.
              scrollViewDecoration: BoxDecoration(color: context.cores.borda),
            ),
          ),
    );
