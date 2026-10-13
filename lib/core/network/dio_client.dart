import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/fonte_de_token.dart';
import '../config/app_config.dart';
import 'alcance_do_servidor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/log_interceptor.dart';

/// O que todo cliente HTTP do app leva, entre o token e a tradução do erro:
/// o log, só em desenvolvimento, e o alcance do servidor (US06), que alimenta
/// o indicador de conexão. Os três clientes — a API, o Firestore e o login —
/// usam a mesma lista.
List<Interceptor> interceptorsComuns(Ref ref) => [
  if (kDebugMode) LogDeRequisicao(),
  AlcanceInterceptor(() => ref.read(servidorInalcancavelProvider.notifier)),
];

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
  // O error vem por último e é quem traduz tudo para AppException — inclusive
  // a falha do auth quando não há token que sirva.
  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(fonteDeTokenProvider)),
    ...interceptorsComuns(ref),
    const ErrorInterceptor(),
  ]);

  ref.onDispose(dio.close);
  return dio;
});
