import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../features/auth/presentation/widgets/vigia_de_inatividade.dart';
import '../features/conta/data/preferencia_de_tema_local.dart';
import '../features/conta/domain/tema_escolhido.dart';
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
      darkTheme: AppTheme.escuro,
      // A escolha da tela Conta; enquanto carrega, a do sistema.
      themeMode: switch (ref.watch(temaEscolhidoProvider).value) {
        TemaEscolhido.claro => ThemeMode.light,
        TemaEscolhido.escuro => ThemeMode.dark,
        TemaEscolhido.sistema || null => ThemeMode.system,
      },
      // Troca de tema sem transição: é mudança de ajuste, não animação.
      themeAnimationDuration: Duration.zero,
      routerConfig: ref.watch(routerProvider),
      // Por cima do roteador: o bloqueio vale para qualquer tela.
      builder: (context, filho) =>
          VigiaDeInatividade(child: filho ?? const SizedBox.shrink()),
    );
  }
}
