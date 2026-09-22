import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  // ProviderScope na raiz: é ele que hospeda o estado de todos os providers.
  runApp(const ProviderScope(child: FonarApp()));
}
