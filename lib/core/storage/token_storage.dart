import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/app_exception.dart';

/// Guarda o token de autenticação.
///
/// Abstração proposital: a origem do token vai ser o Firebase Auth, e o
/// `AuthInterceptor` não precisa saber disso.
abstract interface class TokenStorage {
  /// O token guardado, ou `null` — nunca guardado, apagado, ou ilegível.
  Future<String?> lerToken();

  /// Lança só `AppException`.
  Future<void> salvarToken(String token);

  /// Lança só `AppException`: token que não saiu tem de ser dito, e não
  /// fingido — quem sai da conta precisa saber que ele ainda está lá.
  Future<void> limpar();
}

/// O token no cofre do sistema: cifrado com chave do Keystore no Android e
/// com chave guardada no Gerenciador de Credenciais no Windows.
///
/// Nunca em `SharedPreferences` nem em arquivo aberto: é a chave de acesso a
/// dado de saúde. Nada aqui depende de sistema operacional — o pacote escolhe
/// o cofre de cada um.
///
/// TODO(auth): com o Firebase Auth, avaliar se o token precisa mesmo ficar
/// guardado aqui ou se basta pedir ao Firebase a cada requisição
/// (`getIdToken`), que já cuida da própria sessão.
class TokenStorageSeguro implements TokenStorage {
  const TokenStorageSeguro(this._cofre);

  final FlutterSecureStorage _cofre;

  static const chave = 'fonar.token';

  @override
  Future<String?> lerToken() async {
    try {
      return await _cofre.read(key: chave);
    } catch (_) {
      // Ilegível — a chave do cofre mudou, o aparelho foi restaurado de
      // outro. Não há o que recuperar: apaga, e o profissional entra de novo.
      // Tentar enviar com um token corrompido só daria 401 mais adiante.
      try {
        await _cofre.delete(key: chave);
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<void> salvarToken(String token) async {
    try {
      await _cofre.write(key: chave, value: token);
    } catch (e) {
      throw FalhaDesconhecida(causa: e);
    }
  }

  @override
  Future<void> limpar() async {
    try {
      await _cofre.delete(key: chave);
    } catch (e) {
      throw FalhaDesconhecida(causa: e);
    }
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorageSeguro(FlutterSecureStorage()),
);
