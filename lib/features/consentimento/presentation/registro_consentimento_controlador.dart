import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_consentimento_local.dart';
import '../domain/consentimento.dart';

/// Os campos do formulário, para dizer qual deles o profissional mexeu.
enum CampoDoConsentimento { quemAutoriza, nomeDoResponsavel, concordancia }

/// Estado do envio do registro de consentimento. Os valores preenchidos ficam
/// na tela, como no cadastro de paciente.
class EstadoRegistro {
  const EstadoRegistro({
    this.registrando = false,
    this.erroQuem,
    this.erroResponsavel,
    this.erroConcordancia,
    this.erroGeral,
  });

  final bool registrando;
  final String? erroQuem;
  final String? erroResponsavel;
  final String? erroConcordancia;
  final String? erroGeral;

  String? erroDe(CampoDoConsentimento campo) => switch (campo) {
    CampoDoConsentimento.quemAutoriza => erroQuem,
    CampoDoConsentimento.nomeDoResponsavel => erroResponsavel,
    CampoDoConsentimento.concordancia => erroConcordancia,
  };

  EstadoRegistro semErroEm(CampoDoConsentimento campo) => EstadoRegistro(
    registrando: registrando,
    erroQuem: campo == CampoDoConsentimento.quemAutoriza ? null : erroQuem,
    erroResponsavel: campo == CampoDoConsentimento.nomeDoResponsavel
        ? null
        : erroResponsavel,
    erroConcordancia: campo == CampoDoConsentimento.concordancia
        ? null
        : erroConcordancia,
    erroGeral: erroGeral,
  );
}

/// Registro de consentimento de UM paciente — o id é o argumento da família,
/// para que dois pacientes nunca dividam o mesmo estado de formulário.
class RegistroConsentimentoControlador extends Notifier<EstadoRegistro> {
  RegistroConsentimentoControlador(this.pacienteId);

  final String pacienteId;

  @override
  EstadoRegistro build() => const EstadoRegistro();

  /// O profissional mexeu em [campo]: o erro dele sai da tela. Não revalida;
  /// volta, se for o caso, no próximo "Registrar".
  void editou(CampoDoConsentimento campo) {
    if (state.erroDe(campo) != null) state = state.semErroEm(campo);
  }

  /// Confere e registra. Devolve `true` se registrou; o motivo de não ter
  /// registrado fica no estado. A navegação fica com a tela.
  Future<bool> registrar({
    required QuemAutoriza? quemAutoriza,
    required String nomeDoResponsavel,
    required bool concordou,
  }) async {
    // Toque duplo registraria duas vezes.
    if (state.registrando) return false;

    final resultado = validarConsentimento(
      quemAutoriza: quemAutoriza,
      nomeDoResponsavel: nomeDoResponsavel,
      concordou: concordou,
    );

    final PedidoDeConsentimento pedido;
    switch (resultado) {
      case ConsentimentoInvalido():
        state = EstadoRegistro(
          erroQuem: _mensagem(resultado.quemAutoriza),
          erroResponsavel: _mensagem(resultado.nomeDoResponsavel),
          erroConcordancia: _mensagem(resultado.concordancia),
        );
        return false;
      case ConsentimentoValido(pedido: final valido):
        pedido = valido;
    }

    state = const EstadoRegistro(registrando: true);
    // Guardado antes da espera — ver o mesmo cuidado no cadastro de paciente:
    // com a tela fechada no meio do registro, o `ref` já foi descartado.
    final container = ref.container;
    var registrou = false;
    EstadoRegistro fim;
    try {
      await ref
          .read(repositorioConsentimentoProvider)
          .registrar(pacienteId, pedido);
      registrou = true;
      fim = const EstadoRegistro();
    } on AppException catch (e) {
      fim = EstadoRegistro(erroGeral: e.mensagem);
    } catch (_) {
      // O contrato é lançar só AppException. Se outra coisa escapar, o pior
      // desfecho é o botão preso em "Registrando…".
      fim = const EstadoRegistro(erroGeral: AppStrings.erroDesconhecido);
    }

    // A tela passa a mostrar "registrado" — inclusive se tiver sido fechada e
    // aberta de novo durante o registro.
    if (registrou) {
      container
        ..invalidate(consentimentoProvider(pacienteId))
        ..invalidate(retiradaEmVigorProvider(pacienteId));
    }

    if (!ref.mounted) return false;
    state = fim;
    return registrou;
  }
}

String? _mensagem(ProblemaNoConsentimento? problema) => switch (problema) {
  null => null,
  ProblemaNoConsentimento.quemAutorizaNaoEscolhido =>
    AppStrings.consentimentoEscolhaQuem,
  ProblemaNoConsentimento.nomeDoResponsavelVazio =>
    AppStrings.consentimentoInformeResponsavel,
  ProblemaNoConsentimento.concordanciaNaoMarcada =>
    AppStrings.consentimentoMarqueConcordancia,
};

final registroConsentimentoProvider = NotifierProvider.autoDispose
    .family<RegistroConsentimentoControlador, EstadoRegistro, String>(
      RegistroConsentimentoControlador.new,
    );
