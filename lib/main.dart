import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licencas.dart';

void main() {
  registrarLicencas();
  // ProviderScope na raiz: é ele que hospeda o estado de todos os providers.
  runApp(const ProviderScope(child: FonarApp()));
}
