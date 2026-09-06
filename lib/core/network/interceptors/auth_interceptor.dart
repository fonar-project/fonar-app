import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Injeta o token de autenticação em toda requisição.
///
/// Não decide o que fazer quando o token falha — só limpa o token inválido e
/// deixa o erro seguir. A reação (mandar para o login) é da camada de
/// apresentação.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  /// Rotas que não levam token. TODO: ajustar quando a API existir.
  static const _rotasPublicas = <String>{'/auth/login', '/health'};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_rotasPublicas.contains(options.path)) {
      return handler.next(options);
    }

    final token = await _tokenStorage.lerToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // TODO: tentar renovar o token pelo Firebase Auth e repetir a requisição
      // uma única vez antes de desistir. Cuidado com laço infinito: a repetição
      // não pode passar de novo por este interceptor sem uma marca no
      // `options.extra`.
      await _tokenStorage.limpar();
    }

    return handler.next(err);
  }
}
