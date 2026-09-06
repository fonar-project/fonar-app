import 'package:dio/dio.dart';

import '../../error/app_exception.dart';

/// Converte `DioException` em [AppException].
///
/// Depois deste interceptor, nenhuma camada acima precisa importar o Dio nem
/// olhar código de status. O [AppException] resultante viaja no campo
/// `error` da exceção — quem captura faz:
///
/// ```dart
/// on DioException catch (e) {
///   final falha = e.error;
///   if (falha is AppException) { /* falha.mensagem já está em pt-BR */ }
/// }
/// ```
///
/// TODO: quando o contrato de erro da API estiver definido, extrair do corpo
/// da resposta a mensagem e os campos inválidos para alimentar
/// [FalhaDeValidacao.camposComErro].
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(
      err.copyWith(error: _mapear(err)),
    );
  }

  AppException _mapear(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        TempoEsgotado(causa: err),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate =>
        FalhaDeConexao(causa: err),
      DioExceptionType.cancel => EnvioCancelado(causa: err),
      DioExceptionType.badResponse => _mapearStatus(err),
      DioExceptionType.unknown => err.error is AppException
          ? err.error! as AppException
          : FalhaDesconhecida(causa: err),
    };
  }

  AppException _mapearStatus(DioException err) {
    final status = err.response?.statusCode;
    return switch (status) {
      400 || 422 => FalhaDeValidacao(causa: err),
      401 => NaoAutorizado(causa: err),
      403 => Proibido(causa: err),
      404 => NaoEncontrado(causa: err),
      final int s when s >= 500 => FalhaNoServidor(statusCode: s, causa: err),
      _ => FalhaDesconhecida(causa: err),
    };
  }
}
