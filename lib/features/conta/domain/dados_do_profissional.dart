import '../../auth/domain/profissional.dart';

/// O que pode impedir salvar os dados do profissional.
enum ProblemaNosDados { nomeVazio, registroVazio }

sealed class ResultadoDosDados {
  const ResultadoDosDados();
}

final class DadosValidos extends ResultadoDosDados {
  const DadosValidos(this.profissional);

  final Profissional profissional;
}

/// No máximo um problema por campo.
final class DadosInvalidos extends ResultadoDosDados {
  const DadosInvalidos({this.nome, this.registro});

  final ProblemaNosDados? nome;
  final ProblemaNosDados? registro;
}

/// Confere nome e registro como foram digitados.
///
/// Os dois vão impressos na assinatura do laudo, e laudo sem quem assina não
/// serve. Espaços sobrando saem: "Ana   Souza " vira "Ana Souza".
///
/// TODO(clínico): conferir o formato do registro no conselho (ex.:
/// "CRFa 2-12345") e se vale validar a região. Hoje só se exige que exista.
ResultadoDosDados validarDados({
  required Profissional atual,
  required String nome,
  required String registro,
}) {
  String limpar(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
  final nomeLimpo = limpar(nome);
  final registroLimpo = limpar(registro);

  if (nomeLimpo.isEmpty || registroLimpo.isEmpty) {
    return DadosInvalidos(
      nome: nomeLimpo.isEmpty ? ProblemaNosDados.nomeVazio : null,
      registro: registroLimpo.isEmpty ? ProblemaNosDados.registroVazio : null,
    );
  }
  return DadosValidos(
    Profissional(nome: nomeLimpo, registro: registroLimpo, email: atual.email),
  );
}

/// Onde os dados do profissional ficam, e como sair da conta.
abstract interface class RepositorioDaConta {
  /// Lança só `AppException`.
  Future<void> salvar(Profissional profissional);

  /// Encerra a sessão neste aparelho.
  Future<void> sair();
}
