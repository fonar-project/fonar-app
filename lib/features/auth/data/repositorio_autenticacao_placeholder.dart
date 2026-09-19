import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositorio_autenticacao.dart';

/// TODO(auth): trocar pelo repositório do Firebase Auth.
final repositorioAutenticacaoProvider = Provider<RepositorioAutenticacao>(
  (ref) => const RepositorioAutenticacaoPlaceholder(),
);

/// PLACEHOLDER — aceita qualquer e-mail e senha.
///
/// Existe só para a tela de login ser navegável enquanto o Firebase Auth não
/// está configurado. Nenhum build distribuível pode sair com esta classe
/// ligada no [repositorioAutenticacaoProvider].
///
/// A espera imita o tempo de ida e volta de uma autenticação real, para o
/// estado "Entrando…" aparecer durante o desenvolvimento em vez de ser
/// testado só no dia em que o backend subir.
class RepositorioAutenticacaoPlaceholder implements RepositorioAutenticacao {
  const RepositorioAutenticacaoPlaceholder();

  @override
  Future<void> entrar({required String email, required String senha}) =>
      Future.delayed(const Duration(milliseconds: 900));
}
