import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/credencial.dart';
import '../../../core/auth/firebase_auth_rest.dart';
import '../../../core/auth/fonte_de_token.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/domain/conta_autenticada.dart';

/// Criar a conta no Firebase e verificar o e-mail dela.
///
/// Separado do `RepositorioAutenticacao` de propósito: entrar e sair existem
/// também no login de exemplo; criar conta, só com o Firebase de verdade.
abstract interface class CriacaoDeConta {
  /// Cria a conta, guarda a credencial no cofre e pede o e-mail de
  /// verificação. Se o e-mail não sair, a conta fica criada do mesmo jeito —
  /// a tela seguinte tem "reenviar".
  ///
  /// Lança [EmailIndisponivel], [EmailInvalido], [SenhaFraca],
  /// [MuitasTentativas] ou a `AppException` da rede.
  Future<ContaAutenticada> criarConta({
    required String email,
    required String senha,
  });

  /// Manda de novo o e-mail de verificação para a conta guardada.
  Future<void> reenviarVerificacao();

  /// Pega um token novo, que traz o e-mail verificado — o token guardado é
  /// de antes de o profissional abrir o link.
  Future<void> atualizarVerificacao();
}

class CriacaoDeContaFirebase implements CriacaoDeConta {
  CriacaoDeContaFirebase(this._firebase, this._cofre, this._fonte);

  final FirebaseAuthRest _firebase;
  final CofreDeCredencial _cofre;
  final FonteDeToken _fonte;

  @override
  Future<ContaAutenticada> criarConta({
    required String email,
    required String senha,
  }) async {
    final credencial = await _firebase.criarConta(email: email, senha: senha);
    await _cofre.guardar(credencial);
    try {
      await _firebase.enviarVerificacaoDeEmail(credencial.idToken);
    } on AppException {
      // A conta existe; o e-mail se pede de novo na tela de verificação.
    }
    return ContaAutenticada(uid: credencial.uid, email: credencial.email);
  }

  @override
  Future<void> reenviarVerificacao() async {
    final token = await _fonte.tokenDeAcesso();
    if (token == null || token.isEmpty) throw const NaoAutorizado();
    await _firebase.enviarVerificacaoDeEmail(token);
  }

  @override
  Future<void> atualizarVerificacao() => _fonte.renovarAgora();
}

/// A criação de conta, ou `null` com o login de exemplo — aí a entrada não
/// oferece "Criar conta".
final criacaoDeContaProvider = Provider<CriacaoDeConta?>((ref) {
  final firebase = ref.watch(firebaseAuthRestProvider);
  if (firebase == null) return null;
  return CriacaoDeContaFirebase(
    firebase,
    ref.watch(cofreDeCredencialProvider),
    ref.watch(fonteDeTokenProvider),
  );
});
