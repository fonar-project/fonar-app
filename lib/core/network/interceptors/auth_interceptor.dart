import 'package:dio/dio.dart';

import '../../auth/fonte_de_token.dart';
import '../../error/app_exception.dart';

/// Injeta o token de autenticação em toda requisição à API de análise.
///
/// O token vem da [FonteDeToken], que o renova antes de vencer. Quando não
/// há token que sirva — ninguém entrou com senha, ou o Firebase não renova
/// mais —, a requisição nem sai: falha com `NaoAutorizado`, e a fila marca o
/// envio como esperando login.
///
/// Um 401 da API não é tratado aqui: com o token renovado antes de sair, a
/// recusa quer dizer acesso revogado, e o `ErrorInterceptor` já a traduz
/// para `NaoAutorizado`. Repetir a requisição não adiantaria — e o corpo do
/// envio, um WAV em multipart, nem se repete.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._fonte);

  final FonteDeToken _fonte;

  /// Rotas que não levam token. TODO: ajustar quando a API existir.
  static const _rotasPublicas = <String>{'/health'};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_rotasPublicas.contains(options.path)) {
      return handler.next(options);
    }

    final String? token;
    try {
      token = await _fonte.tokenDeAcesso();
    } on AppException catch (falha) {
      // A falha já é uma `AppException`: quem chamou a lê no `error`, como
      // as que o `ErrorInterceptor` traduz.
      return handler.reject(
        DioException(requestOptions: options, error: falha),
      );
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }
}
