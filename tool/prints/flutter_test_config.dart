import 'dart:async';

import 'package:fonar_app/core/config/app_config.dart';

/// As prints saem do modo de exemplo, como os testes (ver
/// `test/flutter_test_config.dart`): sem rede, sem login de verdade e só com
/// os dados de exemplo, que aparecem identificados como tal. O guia da
/// primeira vez só abre na print que o mostra, pelo provider.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.mudarModoDeExemplo(ligado: true);
  AppConfig.mudarGuiaAbreSozinho(ligado: false);
  await testMain();
}
