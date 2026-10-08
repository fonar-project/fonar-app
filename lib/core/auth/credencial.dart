import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../storage/token_storage.dart';

/// O que o Firebase Auth devolve quando a senha confere, e o que se guarda
/// no aparelho para continuar falando com a API sem pedir a senha de novo.
///
/// - [idToken] é o que vai no cabeçalho `Authorization` da API de análise.
///   Vale uma hora.
/// - [refreshToken] troca o [idToken] vencido por outro, sem senha. Não
///   vence sozinho: deixa de valer quando a senha muda ou a conta é
///   desativada.
class Credencial {
  const Credencial({
    required this.uid,
    required this.email,
    required this.idToken,
    required this.refreshToken,
    required this.expiraEm,
  });

  /// O id da conta no Firebase. É ele que diz de quem é cada envio da fila.
  final String uid;
  final String email;
  final String idToken;
  final String refreshToken;
  final DateTime expiraEm;

  /// Renova antes de vencer: um envio de WAV leva minutos, e o token não
  /// pode vencer no meio do caminho entre sair daqui e chegar à API.
  static const folga = Duration(minutes: 5);

  bool precisaRenovar(DateTime agora) =>
      !agora.isBefore(expiraEm.subtract(folga));

  Credencial renovada({
    required String idToken,
    required String refreshToken,
    required DateTime expiraEm,
  }) => Credencial(
    uid: uid,
    email: email,
    idToken: idToken,
    refreshToken: refreshToken,
    expiraEm: expiraEm,
  );

  Map<String, Object> paraJson() => {
    'uid': uid,
    'email': email,
    'idToken': idToken,
    'refreshToken': refreshToken,
    'expiraEm': expiraEm.toUtc().toIso8601String(),
  };

  /// `null` quando o que está guardado não é uma credencial inteira.
  static Credencial? deJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final uid = json['uid'];
    final email = json['email'];
    final idToken = json['idToken'];
    final refreshToken = json['refreshToken'];
    final expiraEm = DateTime.tryParse('${json['expiraEm']}');
    if (uid is! String ||
        uid.isEmpty ||
        email is! String ||
        idToken is! String ||
        refreshToken is! String ||
        expiraEm == null) {
      return null;
    }
    return Credencial(
      uid: uid,
      email: email,
      idToken: idToken,
      refreshToken: refreshToken,
      expiraEm: expiraEm,
    );
  }
}

/// A [Credencial] no cofre do sistema, pelo [TokenStorage].
///
/// Uma entrada só, em JSON: os dois tokens e o dono precisam ficar juntos.
/// Guardados em separado, uma falha no meio deixaria o token de uma conta
/// com o id de outra.
class CofreDeCredencial {
  const CofreDeCredencial(this._tokens);

  final TokenStorage _tokens;

  /// A credencial guardada, ou `null` — nunca guardada, apagada, ou num
  /// formato que não se lê (o "token" solto de antes da US32, por exemplo).
  Future<Credencial?> ler() async {
    final texto = await _tokens.lerToken();
    if (texto == null || texto.isEmpty) return null;
    Credencial? credencial;
    try {
      credencial = Credencial.deJson(jsonDecode(texto));
    } on FormatException {
      credencial = null;
    }
    if (credencial == null) {
      // Não há o que aproveitar: apaga, e o profissional entra de novo.
      try {
        await _tokens.limpar();
      } on AppException {
        // Fica lá, ilegível — e continua sendo lido como nenhuma.
      }
    }
    return credencial;
  }

  /// Lança só `AppException`.
  Future<void> guardar(Credencial credencial) =>
      _tokens.salvarToken(jsonEncode(credencial.paraJson()));

  /// Lança só `AppException`.
  Future<void> apagar() => _tokens.limpar();
}

final cofreDeCredencialProvider = Provider<CofreDeCredencial>(
  (ref) => CofreDeCredencial(ref.watch(tokenStorageProvider)),
);
