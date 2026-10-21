import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';

import '../apoio/banco_em_memoria.dart';
import '../apoio/repositorios_em_memoria.dart';
import '../apoio/sessao_de_teste.dart';

const _p = AppRoutes.paramPacienteId;
const _a = AppRoutes.paramAnaliseId;

/// O paciente e a análise de exemplo — os mesmos da matriz de layout.
const _paciente = 'exemplo-a';
const _analise = 'exemplo-a-4';

/// O voltar do Android (US60), pelo roteador de verdade.
///
/// O voltar chega como o Android o manda: a mensagem `popRoute` no canal de
/// navegação. Quando ninguém no app o segura, o Flutter fecha o app — e é
/// isso que [_App.fechou] anota.
class _App {
  _App(this.container, this.roteador);

  final ProviderContainer container;
  final GoRouter roteador;
  var fechou = false;

  String? get onde => roteador.state.name;
}

/// Desenha sem esperar assentar: a gravação e a prévia do laudo nunca
/// assentam (ver a matriz de layout).
Future<void> _desenhar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<_App> _abrir(WidgetTester tester, {bool comSessao = true}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(true),
      sessaoProvider.overrideWith(
        () => Sessao(comSessao ? contaDeTeste : null),
      ),
      tokenStorageProvider.overrideWithValue(TokenStorageEmMemoria()),
    ],
  );
  addTearDown(container.dispose);
  final app = _App(container, container.read(routerProvider));

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (chamada) async {
      if (chamada.method == 'SystemNavigator.pop') app.fechou = true;
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.claro,
        routerConfig: app.roteador,
      ),
    ),
  );
  await _desenhar(tester);
  return app;
}

/// O botão (ou o gesto) de voltar do Android.
Future<void> _voltar(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await _desenhar(tester);
}

Future<void> _ir(
  WidgetTester tester,
  _App app,
  String nome, [
  Map<String, String> parametros = const {},
]) async {
  app.roteador.goNamed(nome, pathParameters: parametros);
  await _desenhar(tester);
  expect(app.onde, nome, reason: 'a navegação até $nome foi desviada');
}

void main() {
  group('depois de entrar', () {
    testWidgets('na lista de pacientes, o voltar fecha o app', (tester) async {
      final app = await _abrir(tester);
      await _ir(tester, app, AppRoutes.pacientesNome);

      await _voltar(tester);

      expect(app.fechou, isTrue);
    });

    for (final aba in [
      AppRoutes.filaNome,
      AppRoutes.historicoNome,
      AppRoutes.contaNome,
    ]) {
      testWidgets('na aba $aba, o voltar leva à lista, sem fechar o app', (
        tester,
      ) async {
        final app = await _abrir(tester);
        await _ir(tester, app, aba);

        await _voltar(tester);

        expect(app.fechou, isFalse);
        expect(app.onde, AppRoutes.pacientesNome);

        // E da lista, aí sim, fecha.
        await _voltar(tester);
        expect(app.fechou, isTrue);
      });
    }

    testWidgets('nova avaliação volta para a lista', (tester) async {
      final app = await _abrir(tester);
      await _ir(tester, app, AppRoutes.novaAvaliacaoNome);

      await _voltar(tester);

      expect(app.fechou, isFalse);
      expect(app.onde, AppRoutes.pacientesNome);
    });

    testWidgets('as telas de tarefa voltam, uma a uma, até a lista', (
      tester,
    ) async {
      final app = await _abrir(tester);
      await _ir(tester, app, AppRoutes.analiseResultadoNome, {
        _p: _paciente,
        _a: _analise,
      });

      await _voltar(tester);
      expect(app.onde, AppRoutes.pacienteDetalheNome);

      await _voltar(tester);
      expect(app.onde, AppRoutes.pacientesNome);
      expect(app.fechou, isFalse);
    });

    testWidgets('a CAPE-V volta para o resultado', (tester) async {
      final app = await _abrir(tester);
      await _ir(tester, app, AppRoutes.capeVNome, {
        _p: _paciente,
        _a: _analise,
      });

      await _voltar(tester);

      expect(app.onde, AppRoutes.analiseResultadoNome);
      expect(app.fechou, isFalse);
    });
  });

  group('antes de entrar', () {
    testWidgets('na entrada, o voltar fecha o app', (tester) async {
      final app = await _abrir(tester, comSessao: false);
      await _ir(tester, app, AppRoutes.loginNome);

      await _voltar(tester);

      expect(app.fechou, isTrue);
    });

    for (final tela in [
      AppRoutes.criarContaNome,
      AppRoutes.verificarEmailNome,
      AppRoutes.completarCadastroNome,
    ]) {
      testWidgets('em $tela, o voltar leva à entrada', (tester) async {
        final app = await _abrir(tester, comSessao: false);
        await _ir(tester, app, tela);

        await _voltar(tester);

        expect(app.fechou, isFalse);
        expect(app.onde, AppRoutes.loginNome);
      });
    }

    testWidgets('a recuperação de senha, empilhada, desempilha', (
      tester,
    ) async {
      final app = await _abrir(tester, comSessao: false);
      await _ir(tester, app, AppRoutes.loginNome);
      app.roteador.pushNamed(AppRoutes.recuperarSenhaNome);
      await _desenhar(tester);
      expect(app.onde, AppRoutes.recuperarSenhaNome);

      await _voltar(tester);

      expect(app.onde, AppRoutes.loginNome);
      expect(app.fechou, isFalse);
    });
  });
}
