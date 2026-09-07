import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'health_check_repository.dart';

/// Provider que executa o health check sob demanda.
///
/// Uso recomendado: `ref.watch(healthCheckProvider)` retorna `AsyncValue`, e
/// `ref.invalidate(healthCheckProvider)` força uma nova verificação.
///
/// O `autoDispose` garante que não mantemos polling em background — a
/// verificação só acontece enquanto alguém está escutando (a tela de
/// diagnóstico aberta, por exemplo).
final healthCheckProvider =
    FutureProvider.autoDispose<HealthCheckResult>((ref) {
  return ref.watch(healthCheckRepositoryProvider).verificar();
});
