import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/app/app_estrutura.dart';
import 'package:praatico_app/app/router/app_router.dart';
import 'package:praatico_app/app/router/app_routes.dart';
import 'package:praatico_app/design_system/theme/app_theme.dart';
import 'package:praatico_app/design_system/widgets/tela_placeholder.dart';
import 'package:praatico_app/l10n/app_strings.dart';

const _desktop = Size(1440, 900);

Future<void> _pumpar(WidgetTester tester, Widget tela) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.claro, home: tela),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // A convenção documentada em `app_estrutura.dart`: quem decide ter navegação
  // principal é a TELA, no próprio build — o roteador não embrulha ninguém.
  // A documentação dizia isso enquanto o roteador embrulhava as três telas de
  // andaime; estes testes são o que segura a convenção escolhida.
  group('convenção de embrulho', () {
    testWidgets('a tela de andaime com destino se embrulha sozinha', (
      tester,
    ) async {
      await _pumpar(
        tester,
        const TelaPlaceholder(
          titulo: AppStrings.filaTitulo,
          rota: AppRoutes.filaCaminho,
          destino: DestinoPrincipal.fila,
        ),
      );

      expect(find.byType(AppEstrutura), findsOneWidget);
      // A barra lateral do desktop traz todos os destinos.
      for (final destino in DestinoPrincipal.values) {
        expect(find.text(destino.rotulo), findsWidgets, reason: destino.name);
      }
    });

    testWidgets('sem destino, a tela ocupa tudo e não ganha navegação', (
      tester,
    ) async {
      // Gravação, consentimento e resultado são assim: tela inteira.
      await _pumpar(
        tester,
        const TelaPlaceholder(
          titulo: AppStrings.capturaTitulo,
          rota: AppRoutes.capturaCaminho,
        ),
      );

      expect(find.byType(AppEstrutura), findsNothing);
      expect(find.text(AppStrings.navFila), findsNothing);
    });

    testWidgets('as telas de andaime do roteador real trazem navegação', (
      tester,
    ) async {
      // O contrapeso: "a tela se embrulha" e "o roteador embrulha" produzem a
      // mesma imagem, e foi por isso que as duas conviveram sem ninguém
      // notar. Aqui o roteador de verdade é exercitado — se alguém tirar o
      // `destino` da TelaPlaceholder achando que o roteador ainda embrulha, a
      // navegação some destas telas e o teste acusa.
      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final roteador = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.claro,
            routerConfig: roteador,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final (nome, titulo) in [
        (AppRoutes.filaNome, AppStrings.filaTitulo),
        (AppRoutes.contaNome, AppStrings.contaTitulo),
        (AppRoutes.novaAvaliacaoNome, AppStrings.novaAvaliacaoTitulo),
      ]) {
        roteador.goNamed(nome);
        await tester.pumpAndSettle();

        expect(find.text(titulo), findsWidgets, reason: nome);
        expect(find.byType(AppEstrutura), findsOneWidget, reason: nome);
      }
    });
  });
}
