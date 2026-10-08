import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/credencial.dart';
import '../../../core/auth/firebase_auth_rest.dart';
import '../domain/conta_autenticada.dart';
import '../domain/repositorio_autenticacao.dart';
import 'repositorio_autenticacao_placeholder.dart';

/// O Firebase Auth quando o build recebeu a chave; o login de exemplo quando
/// não recebeu (só em desenvolvimento — ver `main.dart`).
final repositorioAutenticacaoProvider = Provider<RepositorioAutenticacao>((
  ref,
) {
  final cofre = ref.watch(cofreDeCredencialProvider);
  final firebase = ref.watch(firebaseAuthRestProvider);
  return firebase == null
      ? RepositorioAutenticacaoPlaceholder(cofre)
      : RepositorioAutenticacaoFirebase(firebase, cofre);
});

/// O app está com o login de exemplo? A tela de entrada avisa.
final loginDeExemploProvider = Provider<bool>(
  (ref) => ref.watch(firebaseAuthRestProvider) == null,
);

/// E-mail e senha conferidos pelo Firebase Auth; a credencial no cofre do
/// sistema.
class RepositorioAutenticacaoFirebase implements RepositorioAutenticacao {
  RepositorioAutenticacaoFirebase(this._firebase, this._cofre);

  final FirebaseAuthRest _firebase;
  final CofreDeCredencial _cofre;

  @override
  Future<ContaAutenticada> entrar({
    required String email,
    required String senha,
  }) async {
    final credencial = await _firebase.entrar(email: email, senha: senha);
    await _cofre.guardar(credencial);
    return ContaAutenticada(uid: credencial.uid, email: credencial.email);
  }

  @override
  Future<ContaAutenticada?> contaGuardada() async {
    final credencial = await _cofre.ler();
    if (credencial == null) return null;
    return ContaAutenticada(uid: credencial.uid, email: credencial.email);
  }

  @override
  Future<void> pedirRedefinicaoDeSenha(String email) =>
      _firebase.pedirRedefinicaoDeSenha(email);

  /// O Firebase não tem "sair" do lado do cliente: a sessão é a credencial,
  /// e sair é apagá-la.
  @override
  Future<void> sair() => _cofre.apagar();
}
