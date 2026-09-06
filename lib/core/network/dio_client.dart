import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Cliente HTTP único do app.
///
/// Toda chamada à API Python (análise acústica) passa por aqui. Repositórios
/// devem depender deste provider, nunca instanciar o próprio `Dio`.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.timeoutConexao,
      receiveTimeout: AppConfig.timeoutRecebimento,
      sendTimeout: AppConfig.timeoutEnvio,
      headers: const {'Accept': 'application/json'},
      // Não lançamos por status: deixamos o ErrorInterceptor classificar.
      responseType: ResponseType.json,
    ),
  );

  // A ORDEM IMPORTA.
  //
  // Em `onRequest` os interceptors rodam na ordem da lista: o auth injeta o
  // token antes de a requisição sair.
  //
  // Em `onError` também: por isso o auth vem primeiro e ainda vê o
  // `DioException` cru, com `statusCode` legível, para decidir sobre o 401. O
  // error vem por último e é quem traduz tudo para AppException — depois dele
  // o status já não é o que interessa.
  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(tokenStorageProvider)),
    const ErrorInterceptor(),
  ]);

  // TODO: adicionar log de requisição só em debug, com o header Authorization
  // ocultado. Nada de corpo de resposta em log: pode conter dado de paciente.

  ref.onDispose(dio.close);
  return dio;
});
