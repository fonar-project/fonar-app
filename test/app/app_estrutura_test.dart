import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/app_estrutura.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/design_system/widgets/app_toque.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../apoio/banco_em_memoria.dart';
import '../apoio/hover.dart';

const _desktop = Size(1440, 900);

void main() {
  // A convenção documentada em `app_estrutura.dart`: quem decide ter navegação
  // principal é a TELA, no próprio build — o roteador não embrulha ninguém.
  // A documentação dizia isso enquanto o roteador embrulhava as três telas de
  // andaime; estes testes são o que segura a convenção escolhida.
  group('convenção de embrulho', () {
    // O contrapeso: "a tela se embrulha" e "o roteador embrulha" produzem a
    // mesma imagem, e foi por isso que as duas conviveram sem ninguém notar.
    // Por isso o teste é sobre o roteador DE VERDADE, e não sobre uma tela de
    // mentira montada aqui: montar a tela à mão provaria que a `AppEstrutura`
    // funciona, não que as telas do aplicativo a usam.
    testWidgets('as telas de destino trazem navegação; as outras, não', (
      tester,
    ) async {
      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(overrides: [bancoDeTeste()]);
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
        // A barra lateral do desktop traz todos os destinos.
        for (final destino in DestinoPrincipal.values) {
          expect(find.text(destino.rotulo), findsWidgets, reason: destino.name);
        }
      }

      // E o outro lado: a maioria das telas não tem navegação principal, e o
      // login vem antes de haver navegação.
      roteador.goNamed(AppRoutes.loginNome);
      await tester.pumpAndSettle();

      expect(find.byType(AppEstrutura), findsNothing);
      expect(find.text(AppStrings.navFila), findsNothing);
    });
  });

  // Achado da revisão de 24/09: o véu de hover escurece o fundo e o rótulo do
  // destino inativo continuava com o tom de creme — 4,35:1, abaixo de AA.
  // Ver `app_colors_test.dart` e a documentação do `AppToque`.
  group('contraste da navegação no hover', () {
    Future<void> abrir(WidgetTester tester, Size tamanho) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppEstrutura(
              destino: DestinoPrincipal.pacientes,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('celular: o rótulo do destino inativo troca de tom', (
      tester,
    ) async {
      await abrir(tester, const Size(390, 844));
      // Inativo: o ativo é roxo, e roxo sobre creme passa com folga.
      const inativo = AppStrings.navHistorico;

      expect(corDoTexto(tester, inativo), AppColors.secundarioSobreCreme);

      await passarOMouse(
        tester,
        find.ancestor(of: find.text(inativo), matching: find.byType(AppToque)),
      );

      expect(corDoTexto(tester, inativo), AppColors.secundarioSobreLavanda);
    });
  });
}
