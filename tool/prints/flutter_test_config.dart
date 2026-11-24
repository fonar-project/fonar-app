import 'dart:async';

import 'package:fonar_app/core/config/app_config.dart';

/// As prints saem do modo de exemplo, como os testes (ver
/// `test/flutter_test_config.dart`): sem rede, sem login de verdade e só com
/// os dados de exemplo, que aparecem identificados como tal. O guia da
/// primeira vez só abre na print que o mostra, pelo provider.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // ignore: invalid_use_of_visible_for_testing_member
  AppConfig.mudarModoDeExemplo(ligado: true);
  // ignore: invalid_use_of_visible_for_testing_member
  AppConfig.mudarGuiaAbreSozinho(ligado: false);
  await testMain();
}
