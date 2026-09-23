import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/relogio.dart';
import '../../analise/domain/resultado_da_analise.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../data/repositorio_laudos_em_memoria.dart';
import '../domain/conteudo_do_laudo.dart';
import '../domain/laudo.dart';
import 'pdf_do_laudo.dart';

class EstadoDoLaudo {
  const EstadoDoLaudo({this.laudo, this.gerando = false, this.falhou = false});

  /// O último laudo gerado desta análise, ou `null` se nunca foi gerado.
  final Laudo? laudo;
  final bool gerando;

  /// A última tentativa de gerar não deu certo.
  final bool falhou;
}

/// O laudo de UMA análise.
class LaudoControlador extends AsyncNotifier<EstadoDoLaudo> {
  LaudoControlador(this.analiseId);

  final String analiseId;

  @override
  Future<EstadoDoLaudo> build() async => EstadoDoLaudo(
    laudo: await ref.read(repositorioLaudosProvider).daAnalise(analiseId),
  );

  /// Gera o PDF com a [conclusao] de agora e registra o laudo. Devolve o
  /// laudo, ou `null` se não deu.
  ///
  /// [montar] recebe a hora da geração, que vai impressa no documento.
  ///
  /// Quem confere se PODE gerar é a tela, com `conferirLaudo`, antes de
  /// chamar — o botão fica desabilitado, dizendo por quê.
  Future<Laudo?> gerar({
    required String pacienteId,
    required String conclusao,
    required ConteudoDoLaudo Function(DateTime geradoEm) montar,
  }) async {
    final atual = state.value;
    if (atual == null || atual.gerando) return null;
    state = AsyncData(EstadoDoLaudo(laudo: atual.laudo, gerando: true));
    try {
      // Lidos antes das esperas: com a tela fechada no meio da geração, o
      // `ref` deste controlador já foi descartado (revisão de 23/09).
      final repositorio = ref.read(repositorioLaudosProvider);
      final gerador = ref.read(geradorDePdfProvider);
      final geradoEm = ref.read(relogioProvider)();
      final conteudo = montar(geradoEm);
      // A conferência vale aqui também, e não só no botão da tela: laudo de
      // um paciente não sai com o conteúdo de outro.
      if (conteudo.pacienteId != pacienteId) {
        throw const AnaliseDeOutroPaciente();
      }
      final pdf = await gerador(conteudo);
      final laudo = Laudo(
        analiseId: analiseId,
        pacienteId: pacienteId,
        conclusao: conclusao.trim(),
        geradoEm: geradoEm,
        pdf: pdf,
      );
      await repositorio.registrar(laudo);
      if (ref.mounted) state = AsyncData(EstadoDoLaudo(laudo: laudo));
      return laudo;
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(EstadoDoLaudo(laudo: atual.laudo, falhou: true));
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
          (gerar) => PdfPreview(
            build: (_) => gerar(),
            useActions: false,
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            maxPageWidth: 640,
            scrollViewDecoration: const BoxDecoration(
              color: AppColors.lavandaClaro,
            ),
          ),
    );
