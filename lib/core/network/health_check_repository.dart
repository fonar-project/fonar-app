import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// Resposta do endpoint de health check da API.
class HealthCheckResult {
  const HealthCheckResult({
    required this.online,
    required this.tempoRespostaMs,
    this.versaoApi,
  });

  /// Se o servidor respondeu com sucesso (status 2xx).
  final bool online;

  /// Tempo de ida e volta da requisição, em milissegundos.
  final int tempoRespostaMs;

  /// Versão da API, se retornada pelo servidor.
  final String? versaoApi;
}

/// Repositório que verifica a saúde da API Python no Cloud Run.
///
/// O endpoint `/health` é público: não exige autenticação (ver
/// `AuthInterceptor._rotasPublicas`). Ideal para validar que a conexão de rede
/// e o servidor estão funcionando antes de qualquer operação clínica.
final healthCheckRepositoryProvider = Provider<HealthCheckRepository>((ref) {
  return HealthCheckRepository(ref.watch(dioProvider));
});

class HealthCheckRepository {
  const HealthCheckRepository(this._dio);

  final Dio _dio;

  /// Faz `GET /health` e retorna o resultado.
  ///
  /// Não lança exceção: erros de rede são capturados e devolvidos como
  /// [HealthCheckResult] com `online = false`. Isso simplifica o consumo na
  /// camada de apresentação — basta checar o booleano.
  Future<HealthCheckResult> verificar() async {
    final cronometro = Stopwatch()..start();

    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      cronometro.stop();

      return HealthCheckResult(
        online: true,
        tempoRespostaMs: cronometro.elapsedMilliseconds,
        versaoApi: response.data?['version'] as String?,
      );
    } on DioException {
      cronometro.stop();

      return HealthCheckResult(
        online: false,
        tempoRespostaMs: cronometro.elapsedMilliseconds,
      );
    }
  }
}
