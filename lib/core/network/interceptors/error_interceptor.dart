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
/// A API de análise manda o motivo da recusa num código estável
/// ([codigoDaApi]); hoje só o `consentimento_ausente` muda o que o app faz.
/// TODO: extrair os campos inválidos para [FalhaDeValidacao.camposComErro],
/// quando alguma tela de formulário falar com a API.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: _mapear(err)));
  }

  AppException _mapear(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => TempoEsgotado(causa: err),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => FalhaDeConexao(causa: err),
      DioExceptionType.cancel => EnvioCancelado(causa: err),
      DioExceptionType.badResponse => _mapearStatus(err),
      DioExceptionType.unknown =>
        err.error is AppException
            ? err.error! as AppException
            : FalhaDesconhecida(causa: err),
    };
  }

  AppException _mapearStatus(DioException err) {
    final status = err.response?.statusCode;
    return switch (status) {
      // 413: arquivo grande demais; 415: não é WAV PCM. Repetir o mesmo
      // envio repetiria a recusa.
      400 || 413 || 415 || 422 => FalhaDeValidacao(causa: err),
      401 => NaoAutorizado(causa: err),
      // A equipe conferiu a inscrição no Crefono e recusou (ADR-015 da API).
      403 when codigoDaApi(err) == 'credencial_recusada' =>
        CredencialRecusada(causa: err),
      403 => Proibido(causa: err),
      404 => NaoEncontrado(causa: err),
      // A API conferiu o consentimento no Firebase e não achou um em vigor.
      409 when codigoDaApi(err) == 'consentimento_ausente' =>
        SemConsentimentoNoServidor(causa: err),
      // O mesmo id com outro conteúdo (`id_ja_existe`, na API) ou uma
      // gravação concorrente no Firestore: tentar sozinho não resolve.
      409 => FalhaDeValidacao(causa: err),
      final int s when s >= 500 => FalhaNoServidor(statusCode: s, causa: err),
      _ => FalhaDesconhecida(causa: err),
    };
  }
}

/// O código da recusa da API de análise, que vem no corpo como
/// `{"detail": {"codigo": "...", "mensagem": "..."}}` — ou `null` quando o
/// corpo não é desse formato (erro do Firestore, de um proxy no caminho).
String? codigoDaApi(DioException err) {
  final corpo = err.response?.data;
  if (corpo is! Map) return null;
  final detalhe = corpo['detail'];
  if (detalhe is! Map) return null;
  final codigo = detalhe['codigo'];
  return codigo is String ? codigo : null;
}
