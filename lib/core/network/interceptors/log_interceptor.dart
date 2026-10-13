import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Log de cada requisição, só em desenvolvimento (`kDebugMode`): método,
/// endereço, status e tempo.
///
/// O que NUNCA vai para o log: o token (o cabeçalho `Authorization` não é
/// escrito, só se havia um) e corpo nenhum, de pedido ou de resposta — pode
/// ser dado de paciente.
class LogDeRequisicao extends Interceptor {
  LogDeRequisicao({void Function(String linha)? escrever})
    : _escrever = escrever ?? debugPrint;

  final void Function(String linha) _escrever;

  static const _inicio = 'fonar.inicio';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_inicio] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _escrever(_linha(response.requestOptions, '${response.statusCode}'));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _escrever(_linha(err.requestOptions, status?.toString() ?? err.type.name));
    handler.next(err);
  }

  static String _linha(RequestOptions pedido, String resultado) {
    final inicio = pedido.extra[_inicio];
    final ms = inicio is DateTime
        ? DateTime.now().difference(inicio).inMilliseconds
        : null;
    final comToken = pedido.headers.containsKey('Authorization')
        ? ' [com token]'
        : '';
    // Só caminho e nome dos parâmetros: o valor de um parâmetro pode ser a
    // chave do Firebase ou um e-mail.
    final uri = pedido.uri;
    final parametros = uri.queryParameters.keys.join(',');
    final endereco =
        '${uri.host}${uri.path}${parametros.isEmpty ? '' : '?$parametros'}';
    return '[http] ${pedido.method} $endereco -> $resultado'
        '${ms == null ? '' : ' (${ms}ms)'}$comToken';
  }
}
