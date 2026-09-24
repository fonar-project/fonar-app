import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/relogio.dart';
import '../../../l10n/app_strings.dart';
import '../../fila/data/repositorio_fila_local.dart';
import '../../fila/presentation/fila_controlador.dart';
import '../../reproducao/presentation/reproducao_controlador.dart';
import '../data/gravador_record.dart';
import '../data/repositorio_amostras_local.dart';
import '../domain/amostra.dart';
import '../domain/sessao_nao_enviada.dart';

/// As sessões de um paciente que ficaram no aparelho sem ir para a análise —
/// ver [SessaoNaoEnviada].
final sessoesNaoEnviadasProvider = FutureProvider.autoDispose
    .family<List<SessaoNaoEnviada>, String>((ref, pacienteId) async {
      final agora = ref.watch(relogioProvider)();
      final fila = ref.watch(repositorioFilaProvider);
      final todas = await ref
          .watch(repositorioAmostrasProvider)
          .doPaciente(pacienteId);
      // Sem gravação nenhuma, a fila nem precisa ser lida.
      if (todas.isEmpty) return const [];
      return sessoesNaoEnviadas(
        amostrasDoPaciente: todas,
        sessoesNaFila: {for (final i in await fila.listar()) i.sessaoId},
        agora: agora,
      );
    });

/// O que está acontecendo com as sessões na tela.
class EstadoDaLimpeza {
  const EstadoDaLimpeza({this.confirmando, this.ocupada, this.erro});

  /// A sessão cujo descarte espera confirmação.
  final String? confirmando;

  /// A sessão sendo descartada ou posta na fila agora.
  final String? ocupada;

  /// O que deu errado, e em qual sessão.
  final ({String sessaoId, String mensagem})? erro;
}

/// Descartar e enviar as sessões não enviadas de UM paciente.
class LimpezaControlador extends Notifier<EstadoDaLimpeza> {
  LimpezaControlador(this.pacienteId);

  final String pacienteId;

  @override
  EstadoDaLimpeza build() => const EstadoDaLimpeza();

  /// Primeiro toque em "Descartar": pede confirmação, na própria sessão.
  void pedirDescarte(String sessaoId) {
    if (state.ocupada != null) return;
    state = EstadoDaLimpeza(confirmando: sessaoId);
  }

  void manter() {
    if (state.ocupada != null) return;
    state = const EstadoDaLimpeza();
  }

  /// Apaga os arquivos e o registro da sessão. Devolve `true` se apagou.
  ///
  /// Os arquivos saem ANTES do registro: se um arquivo não sair, o registro
  /// fica, e a sessão continua na lista para tentar de novo — em vez de um
  /// WAV de paciente sobrar no disco sem ninguém saber dele.
  Future<bool> descartar(SessaoNaoEnviada sessao) async {
    if (state.ocupada != null || state.confirmando != sessao.sessaoId) {
      return false;
    }
    state = EstadoDaLimpeza(ocupada: sessao.sessaoId);
    // Guardado antes das esperas: o que foi apagado precisa sumir da lista
    // mesmo com a tela fechada no meio.
    final container = ref.container;
    // Nada tocando o arquivo que vai ser apagado.
    if (container.exists(reproducaoControladorProvider)) {
      await container.read(reproducaoControladorProvider.notifier).parar();
    }
    final arquivos = container.read(arquivosDeAmostraProvider);
    final repositorio = container.read(repositorioAmostrasProvider);
    String? falha;
    try {
      for (final amostra in sessao.amostras.values) {
        await arquivos.apagar(amostra.caminho);
      }
      await repositorio.descartarSessao(sessao.sessaoId);
    } on AppException catch (e) {
      falha = e.mensagem;
    } catch (_) {
      falha = AppStrings.naoEnviadasErroDescartar;
    }
    container.invalidate(sessoesNaoEnviadasProvider(pacienteId));
    if (ref.mounted) {
      state = EstadoDaLimpeza(
        erro: falha == null
            ? null
            : (sessaoId: sessao.sessaoId, mensagem: falha),
      );
    }
    return falha == null;
  }

  /// Põe a sessão completa na fila de envio. Devolve `true` se pôs.
  Future<bool> enviar(
    SessaoNaoEnviada sessao, {
    required String nomeDoPaciente,
  }) async {
    if (state.ocupada != null || !sessao.completa) return false;
    state = EstadoDaLimpeza(ocupada: sessao.sessaoId);
    final container = ref.container;
    var enviou = false;
    try {
      await container
          .read(filaControladorProvider.notifier)
          .enfileirar(
            pacienteId: pacienteId,
            nomeDoPaciente: nomeDoPaciente,
            sessaoId: sessao.sessaoId,
            amostras: [
              for (final t in TarefaDeGravacao.values) sessao.amostras[t]!,
            ],
          );
      enviou = true;
    } catch (_) {}
    container.invalidate(sessoesNaoEnviadasProvider(pacienteId));
    if (ref.mounted) {
      state = EstadoDaLimpeza(
        erro: enviou
            ? null
            : (
                sessaoId: sessao.sessaoId,
                mensagem: AppStrings.naoEnviadasErroEnviar,
              ),
      );
    }
    return enviou;
  }
}

final limpezaControladorProvider = NotifierProvider.autoDispose
    .family<LimpezaControlador, EstadoDaLimpeza, String>(
      LimpezaControlador.new,
    );
