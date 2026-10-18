import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licencas.dart';
import 'core/config/app_config.dart';
import 'core/navegador/navegador.dart';
import 'features/auth/data/sessao_mantida.dart';
import 'features/laudo/data/saida_do_laudo.dart';
import 'features/reproducao/data/reprodutor_audioplayers.dart';

Future<void> main() async {
  // No modo de exemplo (ou com a chave do Firebase apagada no build), o app
  // entra com o login de exemplo, que aceita qualquer senha. Em
  // desenvolvimento serve; num build de distribuição seria dado de saúde
  // aberto a quem pegar o aparelho. Melhor não abrir.
  if (kReleaseMode && AppConfig.firebaseApiKey.isEmpty) {
    throw StateError(
      'Build de distribuição no modo de exemplo ou sem '
      'FONAR_FIREBASE_API_KEY (ver README).',
    );
  }
  registrarLicencas();
  WidgetsFlutterBinding.ensureInitialized();
  // O container na raiz hospeda o estado de todos os providers. Criado antes
  // do app para a sessão mantida (US59) abrir antes da primeira tela.
  final container = ProviderContainer();
  await abrirSessaoMantida(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const FonarApp()),
  );
  // O PDF que o compartilhamento do celular deixou no cache (laudo é dado
  // pessoal sensível): sai na abertura seguinte, sem segurar a tela.
  unawaited(limparPdfsCompartilhados());
  // E a gravação baixada para ouvir que o app fechado no meio deixou.
  unawaited(limparGravacoesBaixadas());
  // No navegador (US42), o banco local mora no armazenamento da página, que o
  // navegador pode limpar sozinho quando falta espaço — com gravações que
  // ainda não subiram. Pedir para não limpar.
  if (kIsWeb) unawaited(pedirArmazenamentoPersistente());
}
