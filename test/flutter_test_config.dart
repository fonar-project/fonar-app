import 'dart:async';

import 'package:fonar_app/core/config/app_config.dart';

/// Roda antes de cada arquivo de teste (convenção do `flutter_test` para o
/// `flutter_test_config.dart` na pasta `test/`).
///
/// O app abre no FONAR de verdade — o Firebase e a API de produção. Os testes
/// não: rodam no modo de exemplo, sem rede, como o app rodava antes sem
/// `--dart-define`. Quem testa o caminho de verdade (login, cadastro, API)
/// troca o provider pelo falso, como sempre fez.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.mudarModoDeExemplo(ligado: true);
  await testMain();
}
