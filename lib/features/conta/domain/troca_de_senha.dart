import '../../auth/domain/conta_autenticada.dart';
import '../../cadastro/domain/cadastro.dart';

/// Troca a senha da conta na sessão, de dentro do app (US45).
///
/// Antes, só pelo e-mail de "Esqueci a senha", fora do app. Aqui o
/// profissional confirma a senha atual e escolhe a nova; a nova passa a
/// valer para entrar em qualquer aparelho e, neste, também sem conexão.
abstract interface class TrocaDeSenha {
  /// Confere [atual] e põe [nova] no lugar, na conta [conta].
  ///
  /// Lança `CredencialInvalida` quando a atual não confere, `SenhaFraca`
  /// quando o Firebase recusa a nova, ou outra `AppException` (rede, conta
  /// pausada por tentativas demais, sessão que não vale mais).
  Future<void> trocar({
    required ContaAutenticada conta,
    required String atual,
    required String nova,
  });
}

enum CampoDaTrocaDeSenha { atual, nova, confirmacao }

enum ProblemaNaTrocaDeSenha {
  atualVazia,
  novaCurta,
  novaIgualAtual,
  senhasDiferentes,
}

/// Confere o formulário antes de ir ao Firebase — um problema por campo.
///
/// A regra da senha nova é a mesma da conta nova ([tamanhoMinimoDaSenha]).
/// A senha não é aparada: espaço pode fazer parte dela.
Map<CampoDaTrocaDeSenha, ProblemaNaTrocaDeSenha> validarTrocaDeSenha({
  required String atual,
  required String nova,
  required String confirmacao,
}) => {
  if (atual.isEmpty)
    CampoDaTrocaDeSenha.atual: ProblemaNaTrocaDeSenha.atualVazia,
  if (nova.length < tamanhoMinimoDaSenha)
    CampoDaTrocaDeSenha.nova: ProblemaNaTrocaDeSenha.novaCurta
  else if (nova == atual)
    CampoDaTrocaDeSenha.nova: ProblemaNaTrocaDeSenha.novaIgualAtual
  else if (confirmacao != nova)
    CampoDaTrocaDeSenha.confirmacao: ProblemaNaTrocaDeSenha.senhasDiferentes,
};
