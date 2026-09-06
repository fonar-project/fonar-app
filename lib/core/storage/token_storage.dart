import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guarda o token de autenticação.
///
/// Abstração proposital: a origem do token vai ser o Firebase Auth, e o
/// `AuthInterceptor` não precisa saber disso.
abstract interface class TokenStorage {
  Future<String?> lerToken();
  Future<void> salvarToken(String token);
  Future<void> limpar();
}

/// PLACEHOLDER — mantém o token só na memória do processo.
///
/// TODO: substituir antes de qualquer build distribuível. Token de acesso a
/// dado de saúde não pode ficar em `SharedPreferences`; usar armazenamento
/// seguro da plataforma (Keystore no Android, DPAPI no Windows) ou obter o
/// token do Firebase Auth sob demanda, sem persistir nada.
class TokenStorageEmMemoria implements TokenStorage {
  String? _token;

  @override
  Future<String?> lerToken() async => _token;

  @override
  Future<void> salvarToken(String token) async => _token = token;

  @override
  Future<void> limpar() async => _token = null;
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorageEmMemoria(),
);
