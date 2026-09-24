import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../fila/presentation/fila_controlador.dart';
import '../data/repositorio_consentimento_local.dart';
import '../domain/consentimento.dart';

/// Os campos do formulário de retirada.
enum CampoDaRetirada { quemPediu, nomeDoResponsavel }

/// Estado do registro da retirada. Os valores preenchidos ficam na tela.
class EstadoDaRetirada {
  const EstadoDaRetirada({
    this.registrando = false,
    this.erroQuem,
    this.erroResponsavel,
    this.erroGeral,
  });

  final bool registrando;
  final String? erroQuem;
  final String? erroResponsavel;
  final String? erroGeral;

  String? erroDe(CampoDaRetirada campo) => switch (campo) {
    CampoDaRetirada.quemPediu => erroQuem,
    CampoDaRetirada.nomeDoResponsavel => erroResponsavel,
  };

  EstadoDaRetirada semErroEm(CampoDaRetirada campo) => EstadoDaRetirada(
    registrando: registrando,
    erroQuem: campo == CampoDaRetirada.quemPediu ? null : erroQuem,
    erroResponsavel: campo == CampoDaRetirada.nomeDoResponsavel
        ? null
        : erroResponsavel,
    erroGeral: erroGeral,
  );
}

/// Retirada do consentimento de UM paciente.
class RetiradaConsentimentoControlador extends Notifier<EstadoDaRetirada> {
  RetiradaConsentimentoControlador(this.pacienteId);

  final String pacienteId;

  @override
  EstadoDaRetirada build() => const EstadoDaRetirada();

  void editou(CampoDaRetirada campo) {
    if (state.erroDe(campo) != null) state = state.semErroEm(campo);
  }

  /// Confere e registra. Devolve `true` se registrou; a navegação fica com a
  /// tela.
  Future<bool> retirar({
    required QuemAutoriza? quemPediu,
    required String nomeDoResponsavel,
  }) async {
    if (state.registrando) return false;

    final PedidoDeRetirada pedido;
    switch (validarRetirada(
      quemPediu: quemPediu,
      nomeDoResponsavel: nomeDoResponsavel,
    )) {
      case RetiradaInvalida(:final quemPediu, :final nomeDoResponsavel):
        state = EstadoDaRetirada(
          erroQuem: quemPediu == null ? null : AppStrings.retiradaEscolhaQuem,
          erroResponsavel: nomeDoResponsavel == null
              ? null
              : AppStrings.consentimentoInformeResponsavel,
        );
        return false;
      case RetiradaValida(pedido: final valido):
        pedido = valido;
    }

    state = const EstadoDaRetirada(registrando: true);
    // Guardado antes da espera: com a tela fechada no meio, o `ref` já foi
    // descartado — e o que vem depois da retirada precisa acontecer mesmo
    // assim.
    final container = ref.container;
    var retirou = false;
    EstadoDaRetirada fim;
    try {
      await ref
          .read(repositorioConsentimentoProvider)
          .retirar(pacienteId, pedido);
      retirou = true;
      fim = const EstadoDaRetirada();
    } on AppException catch (e) {
      fim = EstadoDaRetirada(erroGeral: e.mensagem);
    } catch (_) {
      fim = const EstadoDaRetirada(erroGeral: AppStrings.erroDesconhecido);
    }

    if (retirou) {
      container
        ..invalidate(consentimentoProvider(pacienteId))
        ..invalidate(retiradaEmVigorProvider(pacienteId));
      // A retirada vale já: o que estava na fila não sobe mais.
      await container
          .read(filaControladorProvider.notifier)
          .pararEnviosDoPaciente(pacienteId);
    }

    if (!ref.mounted) return retirou;
    state = fim;
    return retirou;
  }
}

final retiradaConsentimentoProvider = NotifierProvider.autoDispose
    .family<RetiradaConsentimentoControlador, EstadoDaRetirada, String>(
      RetiradaConsentimentoControlador.new,
    );
