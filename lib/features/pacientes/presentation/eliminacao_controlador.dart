import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/conexao.dart';
import '../../../l10n/app_strings.dart';
import '../../consentimento/data/repositorio_consentimento_local.dart';
import '../../fila/presentation/fila_controlador.dart';
import '../../laudo/data/repositorio_laudos_local.dart';
import '../data/eliminacao_do_paciente.dart';
import '../data/repositorio_pacientes_local.dart';

class EstadoDaEliminacao {
  const EstadoDaEliminacao({this.eliminando = false, this.erro});

  final bool eliminando;
  final String? erro;
}

/// Conduz a eliminação dos dados de um paciente (US43) — o que apaga é
/// [EliminacaoDoPaciente]; aqui, a fila para antes, e as telas leem de novo
/// depois.
class EliminacaoControlador extends Notifier<EstadoDaEliminacao> {
  @override
  EstadoDaEliminacao build() => const EstadoDaEliminacao();

  /// Devolve `true` se eliminou. A pergunta antes, e a navegação depois,
  /// ficam com a tela.
  Future<bool> eliminar(String pacienteId) async {
    if (state.eliminando) return false;
    // O que está no servidor sai junto: sem conexão, não se começa.
    if (AppConfig.apiConfigurada && !ref.read(conexaoOnlineProvider)) {
      state = const EstadoDaEliminacao(
        erro: AppStrings.perfilEliminarExigeConexao,
      );
      return false;
    }
    state = const EstadoDaEliminacao(eliminando: true);
    final container = ref.container;
    try {
      // Nada deste paciente sobe enquanto ele é apagado.
      if (container.exists(filaControladorProvider)) {
        await container
            .read(filaControladorProvider.notifier)
            .pararEnviosDoPaciente(pacienteId);
      }
      await container.read(eliminacaoDoPacienteProvider).eliminar(pacienteId);
    } on AppException catch (e) {
      if (ref.mounted) state = EstadoDaEliminacao(erro: e.mensagem);
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoDaEliminacao(erro: AppStrings.erroDesconhecido);
      }
      return false;
    }
    container
      ..invalidate(pacientesProvider)
      ..invalidate(filaControladorProvider)
      ..invalidate(consentimentoProvider(pacienteId))
      ..invalidate(retiradaEmVigorProvider(pacienteId))
      ..invalidate(laudosDoPacienteProvider(pacienteId));
    if (ref.mounted) state = const EstadoDaEliminacao();
    return true;
  }
}

final eliminacaoControladorProvider =
    NotifierProvider.autoDispose<EliminacaoControlador, EstadoDaEliminacao>(
      EliminacaoControlador.new,
    );
