/// Quem deu a autorização.
///
/// Nem sempre é o próprio paciente: criança, por exemplo, é autorizada pelo
/// responsável legal. Registrar QUEM autorizou é parte do registro — um
/// consentimento sem essa informação não serve de prova de nada.
///
/// TODO(jurídico): confirmar com orientação jurídica quando o responsável é
/// obrigatório e se o registro precisa de mais dados dele (documento,
/// parentesco).
///
/// TODO(equipe): o termo diz que o consentimento pode ser retirado a qualquer
/// momento, e o aplicativo ainda não tem como registrar a retirada. Ela
/// precisa existir antes de o termo ir para produção — e, retirado o
/// consentimento, o bloqueio do roteador volta a valer sozinho.
enum QuemAutoriza { paciente, responsavelLegal }

/// Consentimento registrado para um paciente.
///
/// Enquanto não existir um destes para o paciente, a gravação fica bloqueada
/// no roteador — ver `app_router.dart`. Áudio de voz vinculado a paciente é
/// dado pessoal sensível pela LGPD.
class Consentimento {
  const Consentimento({
    required this.pacienteId,
    required this.registradoEm,
    required this.versaoDoTermo,
    required this.quemAutoriza,
    this.nomeDoResponsavel,
  });

  final String pacienteId;
  final DateTime registradoEm;

  /// Qual texto do termo foi apresentado. O termo vai mudar — o texto atual é
  /// provisório — e cada registro precisa continuar dizendo com o que a
  /// pessoa concordou naquele dia.
  final String versaoDoTermo;
  final QuemAutoriza quemAutoriza;

  /// Preenchido só quando [quemAutoriza] é [QuemAutoriza.responsavelLegal].
  final String? nomeDoResponsavel;
}

/// O que pode impedir o registro.
enum ProblemaNoConsentimento {
  quemAutorizaNaoEscolhido,
  nomeDoResponsavelVazio,

  /// A caixa de concordância não foi marcada. Registrar sem ela seria
  /// registrar uma autorização que ninguém deu.
  concordanciaNaoMarcada,
}

/// Pedido de registro já conferido. Só sai de [validarConsentimento].
class PedidoDeConsentimento {
  const PedidoDeConsentimento._({
    required this.quemAutoriza,
    this.nomeDoResponsavel,
  });

  final QuemAutoriza quemAutoriza;
  final String? nomeDoResponsavel;
}

sealed class ResultadoDoConsentimento {
  const ResultadoDoConsentimento();
}

final class ConsentimentoValido extends ResultadoDoConsentimento {
  const ConsentimentoValido(this.pedido);

  final PedidoDeConsentimento pedido;
}

/// No máximo um problema por campo.
final class ConsentimentoInvalido extends ResultadoDoConsentimento {
  const ConsentimentoInvalido({
    this.quemAutoriza,
    this.nomeDoResponsavel,
    this.concordancia,
  });

  final ProblemaNoConsentimento? quemAutoriza;
  final ProblemaNoConsentimento? nomeDoResponsavel;
  final ProblemaNoConsentimento? concordancia;
}

/// Confere o formulário de consentimento como foi preenchido.
///
/// [nomeDoResponsavel] só é exigido — e só é guardado — quando quem autoriza
/// é o responsável legal. Se o profissional digitou um nome e depois trocou
/// para "o próprio paciente", o nome é descartado: guardar dado pessoal de
/// quem não participou do registro é justamente o que a LGPD pede para não
/// fazer.
ResultadoDoConsentimento validarConsentimento({
  required QuemAutoriza? quemAutoriza,
  required String nomeDoResponsavel,
  required bool concordou,
}) {
  final nome = nomeDoResponsavel.trim().replaceAll(RegExp(r'\s+'), ' ');
  final exigeNome = quemAutoriza == QuemAutoriza.responsavelLegal;

  final problemaQuem = quemAutoriza == null
      ? ProblemaNoConsentimento.quemAutorizaNaoEscolhido
      : null;
  final problemaNome = exigeNome && nome.isEmpty
      ? ProblemaNoConsentimento.nomeDoResponsavelVazio
      : null;
  final problemaConcordancia = concordou
      ? null
      : ProblemaNoConsentimento.concordanciaNaoMarcada;

  if (problemaQuem != null ||
      problemaNome != null ||
      problemaConcordancia != null) {
    return ConsentimentoInvalido(
      quemAutoriza: problemaQuem,
      nomeDoResponsavel: problemaNome,
      concordancia: problemaConcordancia,
    );
  }

  return ConsentimentoValido(
    PedidoDeConsentimento._(
      quemAutoriza: quemAutoriza!,
      nomeDoResponsavel: exigeNome ? nome : null,
    ),
  );
}
