import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/credencial.dart';
import '../../../core/auth/firebase_auth_rest.dart';
import '../../../core/auth/senha_sem_rede.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/domain/conta_autenticada.dart';
import '../domain/troca_de_senha.dart';

/// A troca de senha, ou `null` no modo de exemplo — o login de exemplo
/// aceita qualquer senha, e não há o que trocar.
final trocaDeSenhaProvider = Provider<TrocaDeSenha?>((ref) {
  final firebase = ref.watch(firebaseAuthRestProvider);
  if (firebase == null) return null;
  return TrocaDeSenhaFirebase(
    firebase,
    ref.watch(cofreDeCredencialProvider),
    ref.watch(senhaSemRedeProvider),
  );
});

/// A senha trocada no Firebase Authentication, pela API REST (US45).
class TrocaDeSenhaFirebase implements TrocaDeSenha {
  TrocaDeSenhaFirebase(this._firebase, this._cofre, this._senhas);

  final FirebaseAuthRest _firebase;
  final CofreDeCredencial _cofre;
  final SenhaSemRede _senhas;

  @override
  Future<void> trocar({
    required ContaAutenticada conta,
    required String atual,
    required String nova,
  }) async {
    // Conferir a atual é a prova de que quem troca é o dono — o aparelho
    // pode ter ficado aberto — e dá o token recente que o Firebase exige
    // para mudar a senha.
    final conferida = await _firebase.entrar(email: conta.email, senha: atual);
    if (conferida.uid != conta.uid) throw const CredencialInvalida();
    final trocada = await _firebase.trocarSenha(conferida, nova);
    // A senha já mudou no Firebase. O que vem daqui em diante não desfaz
    // isso, então não vira erro na tela.
    try {
      // Os tokens de renovação de antes deixaram de valer: sem guardar o
      // novo, a próxima renovação pediria para entrar de novo.
      await _cofre.guardar(trocada);
    } catch (_) {
      // Fica o token de antes, que o Firebase não renova mais: o app pede
      // para entrar de novo, já com a senha nova.
    }
    // E, sem conexão, neste aparelho, passa a valer a nova.
    await _senhas.lembrar(conta.uid, nova);
  }
}
