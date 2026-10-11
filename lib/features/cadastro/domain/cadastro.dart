/// O cadastro do profissional na API (ADR-015 do `fonar-api`).
///
/// O cadastro é aberto: quem tem e-mail verificado se cadastra pelo app e já
/// usa o sistema como [Credenciamento.pendente]. A equipe confere a inscrição
/// na consulta pública do Crefono e marca [Credenciamento.credenciado] — ou
/// [Credenciamento.recusado], que fecha o acesso. O app só lê a situação:
/// quem a muda é a equipe, por fora.
library;

/// Se a equipe já conferiu a inscrição no Crefono.
enum Credenciamento {
  pendente,
  credenciado,
  recusado;

  /// O valor da API; desconhecido conta como pendente — ninguém conferiu.
  static Credenciamento daApi(Object? valor) => switch (valor) {
    'credenciado' => credenciado,
    'recusado' => recusado,
    _ => pendente,
  };
}

/// O cadastro como a API devolve.
class PerfilProfissional {
  const PerfilProfissional({
    required this.email,
    required this.registro,
    required this.credenciamento,
    this.nome,
    this.crefonoRegiao,
    this.crefonoInscricao,
    this.observacao,
  });

  final String email;

  /// Como vai no laudo: "CRFa 2-12345".
  final String registro;
  final Credenciamento credenciamento;

  /// `null` só em cadastro antigo, do tempo do convite.
  final String? nome;
  final int? crefonoRegiao;
  final String? crefonoInscricao;

  /// O que a equipe escreveu ao decidir; numa recusa, o motivo.
  final String? observacao;

  /// Cadastro antigo, do convite, sem nome nem inscrição separada: o app
  /// pede para completar.
  bool get completo =>
      nome != null && crefonoRegiao != null && crefonoInscricao != null;
}

/// Em que pé está o cadastro de quem acabou de entrar.
sealed class SituacaoDoCadastro {
  const SituacaoDoCadastro();
}

/// Tem cadastro (pendente, credenciado ou recusado).
final class Cadastrado extends SituacaoDoCadastro {
  const Cadastrado(this.perfil);

  final PerfilProfissional perfil;
}

/// Sem cadastro, e o e-mail ainda não foi verificado: a API não aceita o
/// cadastro antes disso.
final class EmailPorVerificar extends SituacaoDoCadastro {
  const EmailPorVerificar();
}

/// E-mail verificado, sem cadastro: falta o formulário.
final class SemCadastro extends SituacaoDoCadastro {
  const SemCadastro();
}

/// A versão dos termos de uso que o formulário mostra. Vai para a API, que
/// grava com a data do aceite.
///
/// TODO(jurídico): o texto dos termos de uso e da política de privacidade
/// ainda não existe — o formulário mostra o resumo provisório
/// (`AppStrings.cadastroTermosTexto`). Ao trocar o texto, mude a versão.
const versaoDosTermos = 'provisorio-2026-10-11';

/// As regiões do Crefono: 1ª a 9ª.
const regioesDoCrefono = [1, 2, 3, 4, 5, 6, 7, 8, 9];

/// Mínimo de caracteres da senha nova. O Firebase aceita 6; o app pede
/// mais, porque a conta abre dado de paciente.
const tamanhoMinimoDaSenha = 8;

/// O que pode estar errado no formulário — um por campo.
enum ProblemaNoRegistro {
  nomeVazio,
  nomeLongo,
  regiaoVazia,
  inscricaoVazia,
  inscricaoInvalida,
  termosNaoAceitos,
  emailVazio,
  emailInvalido,
  senhaCurta,
  senhasDiferentes,
}

/// Nome, região e número, já limpos.
class DadosDoCadastro {
  const DadosDoCadastro({
    required this.nome,
    required this.crefonoRegiao,
    required this.crefonoInscricao,
  });

  final String nome;
  final int crefonoRegiao;
  final String crefonoInscricao;
}

/// O resultado de conferir o formulário.
sealed class ConferenciaDoRegistro {
  const ConferenciaDoRegistro();
}

final class RegistroValido extends ConferenciaDoRegistro {
  const RegistroValido(this.dados);

  final DadosDoCadastro dados;
}

final class RegistroInvalido extends ConferenciaDoRegistro {
  const RegistroInvalido(this.problemas);

  /// No máximo um problema por campo.
  final Map<CampoDoRegistro, ProblemaNoRegistro> problemas;
}

/// Os campos dos formulários de conta e de cadastro.
enum CampoDoRegistro {
  nome,
  regiao,
  inscricao,
  termos,
  email,
  senha,
  confirmacao,
}

final _inscricao = RegExp(r'^[0-9]+([.-][0-9]+)*$');
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Confere nome, região, número e aceite como foram digitados — as mesmas
/// regras da API, para o erro aparecer no campo antes de ir à rede.
///
/// Espaços sobrando saem do nome ("Ana   Souza " vira "Ana Souza"). O número
/// é só o número: "CRFa 2-12345" é recusado, porque a região já é um campo.
ConferenciaDoRegistro validarRegistro({
  required String nome,
  required int? regiao,
  required String inscricao,
  required bool aceitouTermos,
}) {
  final problemas = <CampoDoRegistro, ProblemaNoRegistro>{};
  final nomeLimpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
  final inscricaoLimpa = inscricao.trim();
  if (nomeLimpo.isEmpty) {
    problemas[CampoDoRegistro.nome] = ProblemaNoRegistro.nomeVazio;
  } else if (nomeLimpo.length > 200) {
    problemas[CampoDoRegistro.nome] = ProblemaNoRegistro.nomeLongo;
  }
  if (regiao == null || !regioesDoCrefono.contains(regiao)) {
    problemas[CampoDoRegistro.regiao] = ProblemaNoRegistro.regiaoVazia;
  }
  if (inscricaoLimpa.isEmpty) {
    problemas[CampoDoRegistro.inscricao] = ProblemaNoRegistro.inscricaoVazia;
  } else if (inscricaoLimpa.length > 20 ||
      !_inscricao.hasMatch(inscricaoLimpa)) {
    problemas[CampoDoRegistro.inscricao] = ProblemaNoRegistro.inscricaoInvalida;
  }
  if (!aceitouTermos) {
    problemas[CampoDoRegistro.termos] = ProblemaNoRegistro.termosNaoAceitos;
  }
  if (problemas.isNotEmpty) return RegistroInvalido(problemas);
  return RegistroValido(
    DadosDoCadastro(
      nome: nomeLimpo,
      crefonoRegiao: regiao!,
      crefonoInscricao: inscricaoLimpa,
    ),
  );
}

/// Confere e-mail, senha e a repetição dela — os campos da conta nova.
Map<CampoDoRegistro, ProblemaNoRegistro> validarConta({
  required String email,
  required String senha,
  required String confirmacao,
}) {
  final emailLimpo = email.trim();
  return {
    if (emailLimpo.isEmpty)
      CampoDoRegistro.email: ProblemaNoRegistro.emailVazio
    else if (!_email.hasMatch(emailLimpo))
      CampoDoRegistro.email: ProblemaNoRegistro.emailInvalido,
    // A senha não é aparada: espaço pode fazer parte dela.
    if (senha.length < tamanhoMinimoDaSenha)
      CampoDoRegistro.senha: ProblemaNoRegistro.senhaCurta
    else if (confirmacao != senha)
      CampoDoRegistro.confirmacao: ProblemaNoRegistro.senhasDiferentes,
  };
}

/// A API recusou o cadastro porque o e-mail ainda não foi verificado: o app
/// volta para a tela de confirmação.
///
/// Não é `AppException`: não é falha para mostrar, é um passo que falta.
class EmailAindaNaoVerificado implements Exception {
  const EmailAindaNaoVerificado();
}
