/// Sexo informado no cadastro, com um único uso: escolher a faixa de
/// referência das medidas.
///
/// As faixas de f0, jitter, shimmer e companhia variam com sexo e idade — ver
/// a pendência clínica no CLAUDE.md. [naoInformado] é resposta válida, não
/// campo esquecido: o paciente pode não querer informar, e aí as medidas
/// aparecem sem classificação, no estado "sem faixa de referência".
///
/// TODO(clínico): confirmar com a orientadora se o catálogo de faixas usa só
/// estas duas categorias e se o rótulo "sexo" é o adequado para o cadastro.
enum SexoDeReferencia { feminino, masculino, naoInformado }

/// O que pode estar errado em cada campo do cadastro.
///
/// É o DOMÍNIO que diz o que está errado; a mensagem que o fonoaudiólogo lê é
/// escolhida na apresentação, a partir daqui. Assim a regra continua testável
/// sem widget e o texto continua todo em `app_strings.dart`.
enum ProblemaNoCadastro {
  nomeVazio,
  nascimentoVazio,

  /// Não é uma data no formato dd/mm/aaaa, ou é uma data que não existe
  /// (31/02, 29/02 fora de ano bissexto).
  nascimentoInvalido,
  nascimentoNoFuturo,

  /// Mais de [NovoPaciente.idadeMaxima] anos: quase certamente erro de
  /// digitação no ano (1924 no lugar de 1994).
  nascimentoImplausivel,
  sexoNaoEscolhido,
  queixaVazia,
}

/// Paciente ainda não salvo, com os dados já conferidos.
///
/// Só existe depois de passar por [validarCadastro]: não há como montar um
/// [NovoPaciente] com nome vazio ou data impossível e mandar para o
/// repositório.
class NovoPaciente {
  const NovoPaciente._({
    required this.nome,
    required this.dataDeNascimento,
    required this.sexo,
    required this.queixa,
  });

  /// Acima disto a data de nascimento é recusada.
  static const idadeMaxima = 120;

  final String nome;

  /// Só a data; a hora é sempre meia-noite.
  final DateTime dataDeNascimento;
  final SexoDeReferencia sexo;

  /// Queixa principal, nas palavras do profissional.
  final String queixa;

  /// Idade em anos completos na data [hoje].
  int idadeEm(DateTime hoje) => idadeEntre(dataDeNascimento, hoje);
}

/// Resultado de [validarCadastro].
sealed class ResultadoDoCadastro {
  const ResultadoDoCadastro();
}

final class CadastroValido extends ResultadoDoCadastro {
  const CadastroValido(this.paciente);

  final NovoPaciente paciente;
}

/// No máximo um problema por campo — o primeiro que impede de seguir.
final class CadastroInvalido extends ResultadoDoCadastro {
  const CadastroInvalido({this.nome, this.nascimento, this.sexo, this.queixa});

  final ProblemaNoCadastro? nome;
  final ProblemaNoCadastro? nascimento;
  final ProblemaNoCadastro? sexo;
  final ProblemaNoCadastro? queixa;
}

/// Confere o formulário como foi digitado.
///
/// [nascimento] chega como texto, "dd/mm/aaaa", porque é assim que o
/// profissional digita — mais rápido que rolar um calendário até 1962 com o
/// paciente esperando. [hoje] vem de fora para o teste não depender do
/// relógio.
ResultadoDoCadastro validarCadastro({
  required String nome,
  required String nascimento,
  required SexoDeReferencia? sexo,
  required String queixa,
  required DateTime hoje,
}) {
  final nomeLimpo = _semEspacoSobrando(nome);
  final queixaLimpa = queixa.trim();
  final data = lerData(nascimento);

  final problemaNome = nomeLimpo.isEmpty ? ProblemaNoCadastro.nomeVazio : null;
  final problemaNascimento = switch (data) {
    _ when nascimento.trim().isEmpty => ProblemaNoCadastro.nascimentoVazio,
    null => ProblemaNoCadastro.nascimentoInvalido,
    final DateTime d when d.isAfter(_soData(hoje)) =>
      ProblemaNoCadastro.nascimentoNoFuturo,
    final DateTime d when idadeEntre(d, hoje) > NovoPaciente.idadeMaxima =>
      ProblemaNoCadastro.nascimentoImplausivel,
    _ => null,
  };
  final problemaSexo = sexo == null
      ? ProblemaNoCadastro.sexoNaoEscolhido
      : null;
  final problemaQueixa = queixaLimpa.isEmpty
      ? ProblemaNoCadastro.queixaVazia
      : null;

  if (problemaNome != null ||
      problemaNascimento != null ||
      problemaSexo != null ||
      problemaQueixa != null) {
    return CadastroInvalido(
      nome: problemaNome,
      nascimento: problemaNascimento,
      sexo: problemaSexo,
      queixa: problemaQueixa,
    );
  }

  return CadastroValido(
    NovoPaciente._(
      nome: nomeLimpo,
      dataDeNascimento: data!,
      sexo: sexo!,
      queixa: queixaLimpa,
    ),
  );
}

/// Lê "dd/mm/aaaa". Devolve `null` se o texto não estiver nesse formato ou se
/// a data não existir.
///
/// O `DateTime` do Dart aceita 31/02 e devolve 03/03 sem reclamar; por isso a
/// data montada é comparada de volta com o que foi digitado.
DateTime? lerData(String texto) {
  final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
  if (partes == null) return null;

  final dia = int.parse(partes.group(1)!);
  final mes = int.parse(partes.group(2)!);
  final ano = int.parse(partes.group(3)!);
  final data = DateTime(ano, mes, dia);

  final existe = data.year == ano && data.month == mes && data.day == dia;
  return existe ? data : null;
}

/// Anos completos entre [nascimento] e [hoje].
int idadeEntre(DateTime nascimento, DateTime hoje) {
  final jaFezAniversario =
      hoje.month > nascimento.month ||
      (hoje.month == nascimento.month && hoje.day >= nascimento.day);
  return hoje.year - nascimento.year - (jaFezAniversario ? 0 : 1);
}

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Tira espaço das pontas e colapsa espaço duplo no meio — "Ana  Maria" com
/// dois espaços, comum no teclado do celular, vira "Ana Maria". Sem isso a
/// busca por "ana maria" não acharia o paciente.
String _semEspacoSobrando(String texto) =>
    texto.trim().replaceAll(RegExp(r'\s+'), ' ');
