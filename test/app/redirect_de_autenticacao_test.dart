import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/presentation/pages/login_page.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/pacientes_list_page.dart';
import 'package:go_router/go_router.dart';

import '../apoio/banco_em_memoria.dart';
import '../apoio/sessao_de_teste.dart';

Future<(GoRouter, ProviderContainer)> _abrir(
  WidgetTester tester, {
  bool aberta = false,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(true),
      repositorioAutenticacaoProvider.overrideWithValue(AutenticacaoFalsa()),
      sessaoProvider.overrideWith(() => Sessao(aberta ? contaDeTeste : null)),
    ],
  );
  addTearDown(container.dispose);
  final roteador = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  await tester.pumpAndSettle();
  return (roteador, container);
}

void main() {
  testWidgets('sem sessão, qualquer rota leva à entrada', (tester) async {
    final (roteador, _) = await _abrir(tester);

    for (final (nome, params) in [
      (AppRoutes.pacientesNome, const <String, String>{}),
      (AppRoutes.filaNome, const <String, String>{}),
      (AppRoutes.contaNome, const <String, String>{}),
      (AppRoutes.pacienteDetalheNome, {AppRoutes.paramPacienteId: 'p1'}),
    ]) {
      roteador.goNamed(nome, pathParameters: params);
      await tester.pumpAndSettle();

      expect(roteador.state.name, AppRoutes.loginNome, reason: nome);
      expect(find.byType(LoginPage), findsOneWidget, reason: nome);
    }
  });

  testWidgets('com sessão, a entrada leva aos pacientes', (tester) async {
    final (roteador, _) = await _abrir(tester, aberta: true);

    roteador.goNamed(AppRoutes.loginNome);
    await tester.pumpAndSettle();

    expect(roteador.state.name, AppRoutes.pacientesNome);
    expect(find.byType(PacientesListPage), findsOneWidget);
  });

  testWidgets('entrar com a senha abre a sessão e chega aos pacientes', (
    tester,
  ) async {
    final (roteador, container) = await _abrir(tester);

    await tester.enterText(find.byType(TextField).at(0), 'fono@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(container.read(sessaoProvider), contaDeTeste);
    expect(roteador.state.name, AppRoutes.pacientesNome);
  });
}
