import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/app.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/design_system/tokens/app_cores.dart';
import 'package:fonar_app/design_system/widgets/app_moldura_de_imagem.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/conta/data/preferencia_de_tema_local.dart';
import 'package:fonar_app/features/conta/domain/tema_escolhido.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../core/migracoes/schema.dart';

void main() {
  group('migração do banco para a versão 3', () {
    final verificador = SchemaVerifier(GeneratedHelper());

    for (final de in [1, 2]) {
      test('da versão $de para a 3, igual a um banco novo', () async {
        final conexao = await verificador.startAt(de);
        final banco = BancoLocal(conexao);
        addTearDown(banco.close);

        await verificador.migrateAndValidate(banco, 3);
      });
    }
  });

  group('preferência de tema', () {
    late BancoLocal banco;
    setUp(() => banco = bancoEmMemoria());
    tearDown(() => banco.close());

    test('sem nada guardado, segue o sistema', () async {
      expect(await PreferenciaDeTemaLocal(banco).ler(), TemaEscolhido.sistema);
    });

    test('guarda, troca e lê de volta', () async {
      final pref = PreferenciaDeTemaLocal(banco);
      await pref.guardar(TemaEscolhido.escuro);
      expect(await pref.ler(), TemaEscolhido.escuro);
      await pref.guardar(TemaEscolhido.claro);
      expect(await pref.ler(), TemaEscolhido.claro);
    });

    test('valor desconhecido no banco vira "do sistema"', () async {
      await banco
          .into(banco.preferencias)
          .insert(PreferenciasCompanion.insert(chave: 'tema', valor: 'sepia'));
      expect(await PreferenciaDeTemaLocal(banco).ler(), TemaEscolhido.sistema);
    });
  });

  group('o app segue a escolha', () {
    Future<ProviderContainer> abrir(
      WidgetTester tester, {
      TemaEscolhido? guardado,
      Brightness sistema = Brightness.light,
      bool naConta = false,
    }) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.platformBrightnessTestValue = sistema;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      if (guardado != null) {
        await PreferenciaDeTemaLocal(banco).guardar(guardado);
      }
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          bancoLocalProvider.overrideWithValue(banco),
          conexaoOnlineProvider.overrideWithValue(false),
          repositorioFilaProvider.overrideWithValue(RepositorioFilaEmMemoria()),
          sessaoAbertaProvider.overrideWith(() => Sessao(naConta)),
          tokenStorageProvider.overrideWithValue(TokenStorageEmMemoria()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FonarApp(),
        ),
      );
      await tester.pumpAndSettle();
      if (naConta) {
        container.read(routerProvider).goNamed(AppRoutes.contaNome);
        await tester.pumpAndSettle();
      }
      return container;
    }

    Color fundoDaTela(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(Scaffold).first))
            .scaffoldBackgroundColor;

    testWidgets('sem escolha, sistema escuro: tema escuro', (tester) async {
      await abrir(tester, sistema: Brightness.dark);
      expect(fundoDaTela(tester), AppColors.escuroFundo);
    });

    testWidgets('sem escolha, sistema claro: tema claro', (tester) async {
      await abrir(tester);
      expect(fundoDaTela(tester), AppColors.creme);
    });

    testWidgets('"Claro" vale mesmo com o sistema escuro', (tester) async {
      await abrir(
        tester,
        guardado: TemaEscolhido.claro,
        sistema: Brightness.dark,
      );
      expect(fundoDaTela(tester), AppColors.creme);
    });

    testWidgets('escolher "Escuro" na Conta troca na hora e fica guardado', (
      tester,
    ) async {
      final container = await abrir(tester, naConta: true);
      expect(find.text(AppStrings.contaAparencia), findsOneWidget);
      expect(fundoDaTela(tester), AppColors.creme);

      final opcao = find.text(AppStrings.contaTemaEscuro);
      await tester.ensureVisible(opcao);
      await tester.pumpAndSettle();
      await tester.tap(opcao);
      await tester.pumpAndSettle();

      expect(fundoDaTela(tester), AppColors.escuroFundo);
      expect(
        await container.read(preferenciaDeTemaProvider).ler(),
        TemaEscolhido.escuro,
      );

      // Com a sessão aberta há o relógio do bloqueio: desmontar e descartar
      // ainda no corpo, antes de o teste conferir timers — ver bloqueio_test.
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });

  group('moldura do espectrograma', () {
    Future<void> montar(WidgetTester tester, ThemeData tema) =>
        tester.pumpWidget(
          MaterialApp(
            theme: tema,
            home: const AppMolduraDeImagem(child: SizedBox(key: Key('img'))),
          ),
        );

    testWidgets('no claro, nenhuma moldura', (tester) async {
      await montar(tester, AppTheme.claro);
      expect(
        find.ancestor(
          of: find.byKey(const Key('img')),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('no escuro, moldura clara em volta', (tester) async {
      await montar(tester, AppTheme.escuro);
      final caixa = tester.widget<DecoratedBox>(
        find.ancestor(
          of: find.byKey(const Key('img')),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (caixa.decoration as BoxDecoration).color,
        AppCores.escuro.molduraDeImagem,
      );
    });
  });
}
