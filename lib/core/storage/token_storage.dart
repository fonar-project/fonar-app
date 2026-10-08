import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/app_exception.dart';

/// Guarda a credencial de autenticação, como texto.
///
/// Desde a US32 o que vai aqui é a credencial do Firebase inteira — tokens e
/// id da conta, em JSON —, e quem a lê e escreve é o `CofreDeCredencial`.
/// Aqui só se cuida de onde ela fica.
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
/// Precisa ficar guardada: sem o SDK do Firebase (ver `FirebaseAuthRest`),
/// é o token de renovação daqui que mantém a sessão entre uma abertura do
/// app e outra, e que deixa o modo offline saber quem entrou por último.
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
