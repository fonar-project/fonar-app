import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/app.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/design_system/escala_da_interface.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/conta/data/preferencia_de_tamanho_local.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

void main() {
  group('preferência de tamanho da interface', () {
    late BancoLocal banco;
    setUp(() => banco = bancoEmMemoria());
    tearDown(() => banco.close());

    test('sem nada guardado, automático', () async {
      expect(
        await PreferenciaDeTamanhoLocal(banco).ler(),
        TamanhoDaInterface.automatico,
      );
    });

    test('guarda e lê de volta', () async {
      final pref = PreferenciaDeTamanhoLocal(banco);
      await pref.guardar(TamanhoDaInterface.centoETrinta);
      expect(await pref.ler(), TamanhoDaInterface.centoETrinta);
    });

    test('valor desconhecido no banco vira automático', () async {
      await banco
          .into(banco.preferencias)
          .insert(
            PreferenciasCompanion.insert(
              chave: 'tamanhoDaInterface',
              valor: 'gigante',
            ),
          );
      expect(
        await PreferenciaDeTamanhoLocal(banco).ler(),
        TamanhoDaInterface.automatico,
      );
    });
  });

  group('o app segue a escolha', () {
    Future<(ProviderContainer, BancoLocal)> abrir(
      WidgetTester tester, {
      Size janela = const Size(1920, 1080),
      TamanhoDaInterface? guardado,
    }) async {
      tester.view.physicalSize = janela;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      if (guardado != null) {
        await PreferenciaDeTamanhoLocal(banco).guardar(guardado);
      }
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          bancoLocalProvider.overrideWithValue(banco),
          conexaoOnlineProvider.overrideWithValue(false),
          repositorioFilaProvider.overrideWithValue(RepositorioFilaEmMemoria()),
          sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
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
      container.read(routerProvider).goNamed(AppRoutes.contaNome);
      await tester.pumpAndSettle();
      return (container, banco);
    }

    // Com a sessão aberta há o relógio do bloqueio: desmontar e descartar
    // ainda no corpo, antes de o teste conferir timers — ver bloqueio_test.
    Future<void> fechar(WidgetTester tester, ProviderContainer c) async {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }

    double larguraVista(WidgetTester tester) =>
        MediaQuery.sizeOf(tester.element(find.text(AppStrings.contaTamanho)))
            .width;

    testWidgets('Full HD, automático: a interface fica 20% maior', (
      tester,
    ) async {
      final (c, _) = await abrir(tester);

      expect(larguraVista(tester), closeTo(1600, 0.01));
      expect(find.textContaining('agora: 120%'), findsOneWidget);
      await fechar(tester, c);
    });

    testWidgets('escolher 130% amplia na hora e fica guardado', (tester) async {
      final (c, banco) = await abrir(tester);

      final opcao = find.text(AppStrings.contaTamanho130);
      await tester.ensureVisible(opcao);
      await tester.pumpAndSettle();
      await tester.tap(opcao);
      await tester.pumpAndSettle();

      expect(larguraVista(tester), closeTo(1920 / 1.3, 0.01));
      expect(
        await PreferenciaDeTamanhoLocal(banco).ler(),
        TamanhoDaInterface.centoETrinta,
      );
      await fechar(tester, c);
    });

    testWidgets('a escolha guardada vale ao abrir', (tester) async {
      final (c, _) = await abrir(tester, guardado: TamanhoDaInterface.cem);

      expect(larguraVista(tester), closeTo(1920, 0.01));
      await fechar(tester, c);
    });

    testWidgets('no celular, nada muda', (tester) async {
      final (c, _) = await abrir(
        tester,
        janela: const Size(390, 1800),
        guardado: TamanhoDaInterface.centoETrinta,
      );

      expect(larguraVista(tester), 390);
      expect(find.textContaining('agora: 100%'), findsOneWidget);
      await fechar(tester, c);
    });
  });
}
