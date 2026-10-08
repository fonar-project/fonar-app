import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../relogio.dart';
import 'credencial.dart';
import 'firebase_auth_rest.dart';

/// Entrega o token de acesso que vai em cada chamada à API de análise, já
/// renovado quando está para vencer.
///
/// Renovar ANTES, e não depois de um 401: o envio da fila é um WAV em
/// multipart, e um corpo desses não se repete — repetir a requisição depois
/// da recusa obrigaria a montar o envio de novo. Com a [Credencial.folga] de
/// cinco minutos, o token que sai daqui chega válido.
class FonteDeToken {
  FonteDeToken(this._cofre, this._firebase, this._agora);

  final CofreDeCredencial _cofre;

  /// `null` com o login de exemplo: não há o que renovar.
  final FirebaseAuthRest? _firebase;
  final DateTime Function() _agora;

  /// A renovação no ar. Dois envios ao mesmo tempo esperam a mesma, em vez
  /// de gastar o token de renovação duas vezes.
  Future<Credencial>? _renovando;

  /// O token para o cabeçalho `Authorization`, ou `null` com o login de
  /// exemplo.
  ///
  /// Lança [NaoAutorizado] quando não há com que autenticar — ninguém entrou
  /// com senha neste aparelho, ou o Firebase não renova mais — e a
  /// `AppException` da rede quando a renovação não chegou ao Firebase.
  Future<String?> tokenDeAcesso() async {
    final credencial = await _cofre.ler();
    final firebase = _firebase;
    if (firebase == null) return credencial?.idToken;
    if (credencial == null) throw const NaoAutorizado();
    if (!credencial.precisaRenovar(_agora())) return credencial.idToken;
    final renovacao = _renovando ??= _renovar(
      firebase,
      credencial,
    ).whenComplete(() => _renovando = null);
    return (await renovacao).idToken;
  }

  Future<Credencial> _renovar(
    FirebaseAuthRest firebase,
    Credencial credencial,
  ) async {
    final Credencial nova;
    try {
      nova = await firebase.renovar(credencial);
    } on NaoAutorizado {
      // O Firebase não renova mais esta conta: guardada, ela só deixaria o
      // modo offline entrar numa conta que não vale.
      try {
        await _cofre.apagar();
      } on AppException {
        // Fica no cofre; a próxima renovação recusa de novo.
      }
      rethrow;
    }
    // Alguém pode ter saído da conta enquanto a renovação estava no ar:
    // gravar agora devolveria ao cofre a credencial que acabou de sair.
    final atual = await _cofre.ler();
    if (atual?.uid != credencial.uid) throw const NaoAutorizado();
    await _cofre.guardar(nova);
    return nova;
  }
}

final fonteDeTokenProvider = Provider<FonteDeToken>(
  (ref) => FonteDeToken(
    ref.watch(cofreDeCredencialProvider),
    ref.watch(firebaseAuthRestProvider),
    ref.watch(relogioProvider),
  ),
);
