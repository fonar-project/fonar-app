import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licencas.dart';
import 'core/config/app_config.dart';

void main() {
  // Sem a chave do Firebase, o app entra com o login de exemplo, que aceita
  // qualquer senha. Em desenvolvimento serve; num build de distribuição seria
  // dado de saúde aberto a quem pegar o aparelho. Melhor não abrir.
  if (kReleaseMode && AppConfig.firebaseApiKey.isEmpty) {
    throw StateError(
      'Build de distribuição sem FONAR_FIREBASE_API_KEY (ver README).',
    );
  }
  registrarLicencas();
  // ProviderScope na raiz: é ele que hospeda o estado de todos os providers.
  runApp(const ProviderScope(child: FonarApp()));
}
