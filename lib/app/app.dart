import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../features/fila/presentation/fila_controlador.dart';
import '../l10n/app_strings.dart';
import 'router/app_router.dart';

/// Raiz do aplicativo.
class FonarApp extends ConsumerWidget {
  const FonarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acorda a fila de sincronização na abertura e a mantém viva: o que ficou
    // pendente sobe sem o profissional precisar abrir a tela da fila.
    // `listen`, não `watch`, para a raiz não se reconstruir a cada envio.
    ref.listen(filaControladorProvider, (_, _) {});

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      // A identidade do FONAR só define paleta clara. Enquanto não houver
      // variante escura desenhada e com contraste verificado, o aplicativo
      // ignora a preferência do sistema de propósito — ver [AppTheme.escuro].
      //
      // TODO: desenhar o tema escuro e, junto dele, permitir que o usuário
      // force claro/escuro. Consultório costuma ter luz forte; a escolha do
      // sistema nem sempre serve.
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
