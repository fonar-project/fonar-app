import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/app_estrutura.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/design_system/tokens/app_movimento.dart';
import 'package:fonar_app/design_system/widgets/app_cabecalho_de_tarefa.dart';
import 'package:fonar_app/design_system/widgets/app_toque.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/pacientes_list_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../apoio/banco_em_memoria.dart';
import '../apoio/hover.dart';
import '../apoio/repositorios_em_memoria.dart';
import '../apoio/sessao_de_teste.dart';

const _desktop = Size(1440, 900);

void main() {
  // A convenção documentada em `app_estrutura.dart` (US57): o ROTEADOR
  // embrulha, por um `ShellRoute`, e a moldura fica parada entre as telas.
  // Os testes vão pelo roteador de verdade: montar a tela à mão provaria que
  // a `AppEstrutura` funciona, não que o aplicativo a usa assim.
  group('convenção de embrulho', () {
    Future<(ProviderContainer, GoRouter)> abrir(
      WidgetTester tester, {
      Size tamanho = _desktop,
    }) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          bancoDeTeste(),
          conexaoOnlineProvider.overrideWithValue(true),
          sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
          tokenStorageProvider.overrideWithValue(TokenStorageEmMemoria()),
        ],
      );
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
      return (container, roteador);
    }

    testWidgets('as telas de quem entrou ficam na moldura; a entrada, não', (
      tester,
    ) async {
      final (container, roteador) = await abrir(tester);

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

      // E o outro lado: o login vem antes de haver navegação — e só existe
      // sem sessão.
      container.read(sessaoProvider.notifier).encerrar();
      roteador.goNamed(AppRoutes.loginNome);
      await tester.pumpAndSettle();

      expect(find.byType(AppEstrutura), findsNothing);
      expect(find.text(AppStrings.navFila), findsNothing);
    });

    // O ponto da US57: trocar de tela não remonta a moldura — a barra lateral
    // fica parada, e só o conteúdo troca.
    testWidgets('trocar de tela não remonta a moldura', (tester) async {
      final (_, roteador) = await abrir(tester);
      final antes = tester.element(find.byType(AppEstrutura));

      roteador.goNamed(AppRoutes.filaNome);
      await tester.pumpAndSettle();
      roteador.goNamed(
        AppRoutes.pacienteDetalheNome,
        pathParameters: {AppRoutes.paramPacienteId: 'exemplo-a'},
      );
      await tester.pumpAndSettle();

      expect(tester.element(find.byType(AppEstrutura)), same(antes));
    });

    testWidgets('o destaque do destino ativo anda com a transição curta', (
      tester,
    ) async {
      final (_, roteador) = await abrir(tester);

      roteador.goNamed(AppRoutes.filaNome);
      await tester.pump();

      final destaque = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text(AppStrings.navFila),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(destaque.duration, AppMovimento.rapida);
      await tester.pumpAndSettle();
    });

    testWidgets('o modo paciente fica fora da moldura: tela inteira', (
      tester,
    ) async {
      final (_, roteador) = await abrir(tester);

      roteador.goNamed(
        AppRoutes.modoPacienteNome,
        pathParameters: {AppRoutes.paramPacienteId: 'exemplo-a'},
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppEstrutura), findsNothing);
      expect(find.text(AppStrings.navFila), findsNothing);
    });

    // A tabela de navegação e as rotas da moldura andam juntas: rota nova
    // sem linha na tabela cairia num destino qualquer, sem ninguém notar.
    test('toda rota da moldura está na tabela de navegação, e só elas', () {
      final container = ProviderContainer(overrides: [bancoDeTeste()]);
      addTearDown(container.dispose);
      final moldura = container
          .read(routerProvider)
          .configuration
          .routes
          .whereType<ShellRoute>()
          .single;

      Iterable<String> nomes(List<RouteBase> rotas) sync* {
        for (final rota in rotas) {
          if (rota is GoRoute) {
            // Quem abre no navegador de fora (o modo paciente) não fica na
            // moldura.
            if (rota.parentNavigatorKey == null) yield rota.name!;
            yield* nomes(rota.routes);
          }
        }
      }

      expect(nomes(moldura.routes).toSet(), navegacaoDasRotas.keys.toSet());
    });

    test('nenhuma tela se embrulha na AppEstrutura', () {
      final quem = [
        for (final arquivo in Directory(
          'lib/features',
        ).listSync(recursive: true))
          if (arquivo is File &&
              arquivo.path.endsWith('.dart') &&
              arquivo.readAsStringSync().contains('AppEstrutura('))
            arquivo.path,
      ];
      expect(quem, isEmpty);
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

  // No desktop as telas de tarefa ficam ao lado da barra lateral, com o
  // voltar e a trilha; no celular, tela inteira, com o voltar.
  group('telas de tarefa', () {
    Future<void> abrirPerfil(WidgetTester tester, Size tamanho) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          bancoDeTeste(),
          conexaoOnlineProvider.overrideWithValue(true),
          sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
          tokenStorageProvider.overrideWithValue(TokenStorageEmMemoria()),
        ],
      );
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
      roteador.goNamed(
        AppRoutes.pacienteDetalheNome,
        pathParameters: {AppRoutes.paramPacienteId: 'exemplo-a'},
      );
      await tester.pumpAndSettle();
    }

    testWidgets('desktop: barra lateral, voltar e trilha', (tester) async {
      await abrirPerfil(tester, _desktop);

      expect(find.byType(AppEstrutura), findsOneWidget);
      for (final destino in DestinoPrincipal.values) {
        expect(find.text(destino.rotulo), findsWidgets, reason: destino.name);
      }
      // No Windows não há voltar do sistema: a seta fica no cabeçalho.
      expect(find.bySemanticsLabel(AppStrings.voltar), findsOneWidget);

      // O primeiro passo da trilha leva à lista.
      final trilha = find.descendant(
        of: find.byType(AppCabecalhoDeTarefa),
        matching: find.text(AppStrings.navPacientes),
      );
      await tester.tap(trilha);
      await tester.pumpAndSettle();
      expect(find.byType(PacientesListPage), findsOneWidget);
    });

    testWidgets('desktop: a seta volta para a lista', (tester) async {
      await abrirPerfil(tester, _desktop);

      await tester.tap(find.bySemanticsLabel(AppStrings.voltar));
      await tester.pumpAndSettle();
      expect(find.byType(PacientesListPage), findsOneWidget);
    });

    testWidgets('celular: tela inteira, com voltar e sem abas', (tester) async {
      await abrirPerfil(tester, const Size(390, 844));

      expect(find.bySemanticsLabel(AppStrings.voltar), findsOneWidget);
      expect(find.text(AppStrings.navFilaCurto), findsNothing);
    });
  });
}
