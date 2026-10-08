import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/offline/pacientes_em_cache.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_placeholder.dart';
import 'package:fonar_app/features/auth/domain/repositorio_autenticacao.dart';
import 'package:fonar_app/features/auth/presentation/pages/login_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Repositório controlável pelo teste.
class _RepositorioFalso implements RepositorioAutenticacao {
  _RepositorioFalso({this.erro, this.espera});

  /// Lançado em [entrar], se preenchido.
  final AppException? erro;

  /// Segura a autenticação até o teste completar, para observar "Entrando…".
  final Completer<void>? espera;

  int chamadas = 0;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    chamadas++;
    await espera?.future;
    if (erro case final erro?) throw erro;
  }
}

const _celular = Size(390, 844);
const _desktop = Size(1440, 900);
const _telaDePacientes = 'tela de pacientes (teste)';

Future<void> _abrir(
  WidgetTester tester, {
  bool online = true,
  int pacientesEmCache = 0,
  RepositorioAutenticacao? repositorio,
  Size tamanho = _celular,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final roteador = GoRouter(
    initialLocation: AppRoutes.loginCaminho,
    routes: [
      GoRoute(
        name: AppRoutes.loginNome,
        path: AppRoutes.loginCaminho,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        name: AppRoutes.pacientesNome,
        path: AppRoutes.pacientesCaminho,
        builder: (_, _) => const Scaffold(body: Text(_telaDePacientes)),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        conexaoOnlineProvider.overrideWithValue(online),
        pacientesEmCacheProvider.overrideWith((ref) => pacientesEmCache),
        repositorioAutenticacaoProvider.overrideWithValue(
          repositorio ?? _RepositorioFalso(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
}

Future<void> _preencher(WidgetTester tester) async {
  final campos = find.byType(TextField);
  await tester.enterText(campos.at(0), 'fono@exemplo.com');
  await tester.enterText(campos.at(1), 'senha');
}

Future<void> _tocarEntrar(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

void main() {
  group('online', () {
    testWidgets('entra e vai para a lista de pacientes', (tester) async {
      await _abrir(tester);
      await _preencher(tester);
      await _tocarEntrar(tester);

      expect(find.text(_telaDePacientes), findsOneWidget);
    });

    // Achado 5.4 da revisão de 24/09: este aviso era o único `SnackBar` do
    // aplicativo — flutuava, sumia sozinho e vinha fora da paleta.
    testWidgets('"Esqueci a senha" avisa na própria tela, e o aviso fica', (
      tester,
    ) async {
      await _abrir(tester);

      expect(find.text(AppStrings.loginRecuperacaoIndisponivel), findsNothing);

      await tester.tap(find.text(AppStrings.loginEsqueciSenha));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.loginRecuperacaoIndisponivel),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.loginRecuperacaoIndisponivelTexto),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      // Não sai sozinho: quem lê devagar não perde o aviso.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.loginRecuperacaoIndisponivel),
        findsOneWidget,
      );
    });

    testWidgets('campos vazios não chegam ao servidor', (tester) async {
      final repositorio = _RepositorioFalso();
      await _abrir(tester, repositorio: repositorio);
      await _tocarEntrar(tester);

      expect(find.text(AppStrings.loginInformeEmail), findsOneWidget);
      expect(find.text(AppStrings.loginInformeSenha), findsOneWidget);
      expect(repositorio.chamadas, 0);
    });

    testWidgets('credencial recusada fica na tela com a mensagem', (
      tester,
    ) async {
      await _abrir(
        tester,
        repositorio: _RepositorioFalso(erro: const CredencialInvalida()),
      );
      await _preencher(tester);
      await _tocarEntrar(tester);

      expect(find.text(AppStrings.erroCredencialInvalida), findsOneWidget);
      expect(find.text(_telaDePacientes), findsNothing);
    });

    testWidgets('falha de rede aparece como erro geral, não de campo', (
      tester,
    ) async {
      await _abrir(
        tester,
        repositorio: _RepositorioFalso(erro: const FalhaDeConexao()),
      );
      await _preencher(tester);
      await _tocarEntrar(tester);

      expect(find.text(AppStrings.erroConexao), findsOneWidget);
      expect(find.text(AppStrings.erroCredencialInvalida), findsNothing);
    });

    testWidgets('mostra "Entrando…" e ignora o segundo toque', (tester) async {
      final espera = Completer<void>();
      final repositorio = _RepositorioFalso(espera: espera);
      await _abrir(tester, repositorio: repositorio);
      await _preencher(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.text(AppStrings.loginBotaoEntrando), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(repositorio.chamadas, 1);

      espera.complete();
      await tester.pumpAndSettle();
      expect(find.text(_telaDePacientes), findsOneWidget);
    });
  });

  group('durante a tentativa', () {
    testWidgets('campos não aceitam edição enquanto espera a resposta', (
      tester,
    ) async {
      // Enviou A, editou para B durante a espera: a resposta de A apareceria
      // junto dos valores B.
      final espera = Completer<void>();
      await _abrir(
        tester,
        repositorio: _RepositorioFalso(
          espera: espera,
          erro: const CredencialInvalida(),
        ),
      );
      await _preencher(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      for (final campo in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(campo.readOnly, isTrue);
      }

      espera.complete();
      await tester.pumpAndSettle();
      // Resposta chegou: dá para corrigir a senha.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).readOnly,
        isFalse,
      );
    });
  });

  group('teclado', () {
    // Botão: o Focus é ancestral do rótulo. Campo de texto: o nó de foco é do
    // próprio EditableText.
    bool focado(WidgetTester tester, Finder alvo) =>
        Focus.of(tester.element(alvo)).hasPrimaryFocus;
    bool campoFocado(WidgetTester tester, int indice) => tester
        .widget<EditableText>(find.byType(EditableText).at(indice))
        .focusNode
        .hasPrimaryFocus;

    testWidgets('Tab percorre e-mail, senha, entrar, esqueci a senha', (
      tester,
    ) async {
      await _abrir(tester, tamanho: _desktop);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(campoFocado(tester, 0), isTrue, reason: 'e-mail');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(campoFocado(tester, 1), isTrue, reason: 'senha');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        // No desktop "Entrar" também é o título da tela.
        focado(
          tester,
          find.descendant(
            of: find.byType(FilledButton),
            matching: find.text(AppStrings.loginBotaoEntrar),
          ),
        ),
        isTrue,
        reason: 'entrar',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        focado(tester, find.text(AppStrings.loginEsqueciSenha)),
        isTrue,
        reason: 'esqueci a senha',
      );
    });

    testWidgets('"Esqueci a senha" desenha anel de foco visível', (
      tester,
    ) async {
      // O teste lê o que foi DESENHADO, não o estilo declarado: o `Material`
      // do botão recebe a forma já com o lado resolvido para o estado atual.
      // Conferir só a `WidgetStateProperty` provava que a regra existe, não
      // que ela é aplicada quando o foco chega — e é o foco que o profissional
      // precisa enxergar ao navegar por teclado no Windows.
      BorderSide anelDesenhado() {
        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(TextButton),
            matching: find.byType(Material),
          ),
        );
        return (material.shape! as OutlinedBorder).side;
      }

      await _abrir(tester, tamanho: _desktop);
      expect(
        anelDesenhado(),
        BorderSide.none,
        reason: 'sem foco não existe anel',
      );

      // Quatro Tab: e-mail, senha, entrar, esqueci a senha.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(
        focado(tester, find.text(AppStrings.loginEsqueciSenha)),
        isTrue,
        reason: 'o Tab precisa ter chegado ao botão',
      );
      await tester.pumpAndSettle();

      final anel = anelDesenhado();
      expect(anel.color, AppColors.foco);
      expect(anel.width, 3);
      expect(anel.style, BorderStyle.solid);
    });
  });

  group('texto ampliado pelo sistema', () {
    // Fonte em 200% é configuração comum entre profissionais mais velhos, e
    // o teste falha se qualquer coisa estourar a largura do celular.
    for (final (nome, online, cache) in [
      ('online', true, 0),
      ('offline com pacientes', false, 5),
      ('offline sem pacientes', false, 0),
    ]) {
      testWidgets('celular $nome em 200% não estoura', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _abrir(tester, online: online, pacientesEmCache: cache);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    // No desktop o painel roxo da marca tem altura de janela e não rolava:
    // em 200% ele estourava 297 px em 1440×900.
    for (final tamanho in [const Size(1440, 900), const Size(1024, 768)]) {
      testWidgets(
        'desktop ${tamanho.width.round()}×${tamanho.height.round()} em 200% '
        'não estoura',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _abrir(tester, online: true, tamanho: tamanho);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('sem conexão', () {
    testWidgets('com pacientes no aparelho, entra em modo offline', (
      tester,
    ) async {
      // Celular pequeno de propósito. Com o aviso embaixo do formulário, o
      // botão caía abaixo da dobra e o toque não o alcançava — e é o botão
      // que importa no consultório sem sinal.
      await _abrir(
        tester,
        online: false,
        pacientesEmCache: 5,
        tamanho: const Size(360, 640),
      );

      expect(find.text(AppStrings.loginOfflineComCacheTitulo), findsOneWidget);
      expect(find.text(AppStrings.loginEsqueciSenha), findsNothing);

      await tester.tap(find.text(AppStrings.loginEntrarOffline));
      await tester.pumpAndSettle();
      expect(find.text(_telaDePacientes), findsOneWidget);
    });

    testWidgets('sem pacientes no aparelho, não há como entrar', (
      tester,
    ) async {
      await _abrir(tester, online: false);

      expect(find.text(AppStrings.loginOfflineSemCacheTitulo), findsOneWidget);
      // O motivo aparece em texto, não só como botão apagado.
      expect(find.text(AppStrings.loginOfflineSemCacheTexto), findsOneWidget);
      expect(find.text(AppStrings.loginEntrarExigeConexao), findsOneWidget);

      for (final botao in tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      )) {
        expect(botao.onPressed, isNull);
      }
      for (final campo in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(campo.enabled, isFalse);
      }
    });
  });

  group('layout por largura', () {
    testWidgets('desktop mostra o painel da marca com a descrição', (
      tester,
    ) async {
      await _abrir(tester, tamanho: _desktop);
      expect(find.text(AppStrings.loginDescricao), findsOneWidget);
    });

    testWidgets('celular deixa a descrição de fora', (tester) async {
      await _abrir(tester);
      expect(find.text(AppStrings.loginDescricao), findsNothing);
    });

    for (final (nome, tamanho) in [
      ('celular', _celular),
      ('desktop', _desktop),
    ]) {
      testWidgets('$nome sempre avisa que é apoio à decisão', (tester) async {
        // O sistema nunca emite diagnóstico, e a primeira tela diz isso.
        await _abrir(tester, tamanho: tamanho);
        expect(find.text(AppStrings.avisoApoioDecisao), findsOneWidget);
      });

      testWidgets('$nome sempre mostra o estado da rede', (tester) async {
        await _abrir(tester, online: false, tamanho: tamanho);
        expect(find.text(AppStrings.conexaoOffline), findsOneWidget);
      });
    }
  });
}
