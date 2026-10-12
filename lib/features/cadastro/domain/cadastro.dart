/// O cadastro do profissional na API (ADR-015 do `fonar-api`, o
/// autocadastro).
///
/// Quem tem e-mail verificado se cadastra pelo app e já usa o sistema como
/// [Credenciamento.pendente]. A equipe confere a inscrição na consulta
/// pública do Crefono e marca [Credenciamento.credenciado]. A situação não
/// bloqueia nada: o app só a mostra, e quem a muda é a equipe, por fora.
library;

/// Se a equipe já conferiu a inscrição no Crefono — a `situacao` da API.
enum Credenciamento {
  pendente,
  credenciado;

  /// O valor da API; desconhecido conta como pendente — ninguém conferiu.
  static Credenciamento daApi(Object? valor) =>
      valor == 'credenciado' ? credenciado : pendente;
}

/// O cadastro como a API devolve.
class PerfilProfissional {
  const PerfilProfissional({
    required this.email,
    required this.credenciamento,
    required this.completo,
    this.registro,
    this.nome,
    this.crefonoRegiao,
    this.crefonoNumero,
  });

  final String email;
  final Credenciamento credenciamento;

  /// Como vai no laudo: "CRFa 2-12345". Em cadastro antigo, do convite, o
  /// texto livre de então.
  final String? registro;

  /// `null` só em cadastro antigo, do tempo do convite.
  final String? nome;
  final int? crefonoRegiao;
  final String? crefonoNumero;

  /// O `cadastro_completo` da API. Falso no cadastro antigo, do convite, sem
  /// nome, inscrição ou aceite dos termos: o app pede o que falta, e o mesmo
  /// `POST` do cadastro completa.
  final bool completo;
}

/// Em que pé está o cadastro de quem acabou de entrar.
sealed class SituacaoDoCadastro {
  const SituacaoDoCadastro();
}

/// Tem cadastro (pendente ou credenciado; completo ou não).
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

/// As regiões do Crefono e os estados de cada uma — a mesma tabela da API
/// (`REGIOES_CREFONO`, em `domain/models.py` do `fonar-api`), como o
/// Conselho Federal publica (fonoaudiologia.org.br, "Conselhos Regionais",
/// consultado em 11/10/2026). Os estados ajudam a achar a região; o que vai
/// para a API é só o número.
const regioesDoCrefono = <int, String>{
  1: 'RJ',
  2: 'SP',
  3: 'PR, SC',
  4: 'AL, BA, PB, PE, SE',
  5: 'DF, GO, MS, MT, TO',
  6: 'ES, MG',
  7: 'RS',
  8: 'CE, MA, PI, RN',
  9: 'AC, AM, AP, PA, RO, RR',
};

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
    required this.crefonoNumero,
  });

  final String nome;
  final int crefonoRegiao;
  final String crefonoNumero;
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

// O número como o conselho o publica: algarismos, e às vezes letra, ponto,
// barra ou hífen; até 20, com pelo menos um algarismo. É a regra da API
// (`validar_numero`), que também tira os espaços e põe em maiúsculas.
final _numero = RegExp(r'^[0-9A-Za-z./-]{1,20}$');
final _algarismo = RegExp('[0-9]');
// "CRFa" no número é a pessoa digitando o registro inteiro: a região já é
// um campo, e o laudo sairia "CRFa 2-CRFA2-12345".
final _prefixoDoConselho = RegExp('crf', caseSensitive: false);
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Confere nome, região, número e aceite como foram digitados — as mesmas
/// regras da API, para o erro aparecer no campo antes de ir à rede.
///
/// Espaços sobrando saem do nome ("Ana   Souza " vira "Ana Souza"); do
/// número saem todos, e as letras vão em maiúsculas, como a API grava. O
/// número é só o número: "CRFa 2-12345" é recusado, porque a região já é um
/// campo.
ConferenciaDoRegistro validarRegistro({
  required String nome,
  required int? regiao,
  required String inscricao,
  required bool aceitouTermos,
}) {
  final problemas = <CampoDoRegistro, ProblemaNoRegistro>{};
  final nomeLimpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
  final inscricaoLimpa = inscricao.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (nomeLimpo.isEmpty) {
    problemas[CampoDoRegistro.nome] = ProblemaNoRegistro.nomeVazio;
  } else if (nomeLimpo.length > 200) {
    problemas[CampoDoRegistro.nome] = ProblemaNoRegistro.nomeLongo;
  }
  if (regiao == null || !regioesDoCrefono.containsKey(regiao)) {
    problemas[CampoDoRegistro.regiao] = ProblemaNoRegistro.regiaoVazia;
  }
  if (inscricaoLimpa.isEmpty) {
    problemas[CampoDoRegistro.inscricao] = ProblemaNoRegistro.inscricaoVazia;
  } else if (!_numero.hasMatch(inscricaoLimpa) ||
      !_algarismo.hasMatch(inscricaoLimpa) ||
      _prefixoDoConselho.hasMatch(inscricaoLimpa)) {
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
      crefonoNumero: inscricaoLimpa,
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
