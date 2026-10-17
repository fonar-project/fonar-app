import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';
import 'package:fonar_app/features/auth/domain/repositorio_autenticacao.dart';
import 'package:fonar_app/features/auth/presentation/pages/recuperar_senha_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Só o pedido de redefinição importa aqui.
class _RepositorioFalso implements RepositorioAutenticacao {
  _RepositorioFalso({this.erro});

  /// Lançado em [pedirRedefinicaoDeSenha], se preenchido.
  AppException? erro;

  final pedidos = <String>[];

  @override
  Future<void> pedirRedefinicaoDeSenha(String email) async {
    pedidos.add(email);
    if (erro case final e?) throw e;
  }

  @override
  Future<ContaAutenticada> entrar({
    required String email,
    required String senha,
  }) => throw UnimplementedError();

  @override
  Future<ContaAutenticada?> contaGuardada() async => null;

  @override
  Future<void> sair() async {}
}

const _telaDeEntrada = 'tela de entrada (teste)';

/// Abre a tela de recuperação direto pelo endereço — como na web, sem a
/// entrada embaixo. O caminho pela entrada está em `login_page_test.dart`.
Future<_RepositorioFalso> _abrir(
  WidgetTester tester, {
  _RepositorioFalso? repositorio,
  bool online = true,
  bool deExemplo = false,
  String? email,
  Size tamanho = const Size(390, 844),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = repositorio ?? _RepositorioFalso();
  final roteador = GoRouter(
    initialLocation: AppRoutes.recuperarSenhaCaminho,
    initialExtra: email,
    routes: [
      GoRoute(
        name: AppRoutes.loginNome,
        path: AppRoutes.loginCaminho,
        builder: (_, _) => const Scaffold(body: Text(_telaDeEntrada)),
      ),
      GoRoute(
        name: AppRoutes.recuperarSenhaNome,
        path: AppRoutes.recuperarSenhaCaminho,
        builder: (_, estado) =>
            RecuperarSenhaPage(emailInicial: estado.extra as String?),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        conexaoOnlineProvider.overrideWithValue(online),
        repositorioAutenticacaoProvider.overrideWithValue(repo),
        loginDeExemploProvider.overrideWithValue(deExemplo),
      ],
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Finder get _campo => find.byType(TextField);

Future<void> _enviar(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.recuperarEnviar));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pede o link e troca o formulário pela confirmação', (
    tester,
  ) async {
    final repositorio = await _abrir(tester, email: 'fono@exemplo.com');
    expect(find.text(AppStrings.recuperarTitulo), findsOneWidget);
    expect(
      tester.widget<TextField>(_campo).controller!.text,
      'fono@exemplo.com',
    );

    await tester.enterText(_campo, ' outra@exemplo.com ');
    await _enviar(tester);

    expect(repositorio.pedidos, ['outra@exemplo.com']);
    expect(
      find.text(AppStrings.loginRecuperacaoEnviadaTitulo),
      findsOneWidget,
    );
    // A mesma resposta exista ou não a conta: não diz quem usa o FONAR.
    expect(find.text(AppStrings.loginRecuperacaoEnviadaTexto), findsOneWidget);
    expect(
      find.text(AppStrings.recuperarPedidoPara('outra@exemplo.com')),
      findsOneWidget,
    );
    expect(_campo, findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    // Não sai sozinha: quem lê devagar não perde a confirmação.
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.loginRecuperacaoEnviadaTitulo),
      findsOneWidget,
    );
  });

  testWidgets('sem e-mail, o erro é do campo e nada é pedido', (tester) async {
    final repositorio = await _abrir(tester);
    await _enviar(tester);

    expect(repositorio.pedidos, isEmpty);
    expect(find.text(AppStrings.recuperarInformeEmail), findsOneWidget);

    // Digitar tira o erro.
    await tester.enterText(_campo, 'f');
    await tester.pump();
    expect(find.text(AppStrings.recuperarInformeEmail), findsNothing);
  });

  testWidgets('e-mail que o Firebase recusa: o erro é do campo', (
    tester,
  ) async {
    final repositorio = await _abrir(
      tester,
      repositorio: _RepositorioFalso(erro: const CredencialInvalida()),
      email: 'fono@',
    );
    await _enviar(tester);

    expect(repositorio.pedidos, ['fono@']);
    expect(find.text(AppStrings.loginRecuperacaoEmailInvalido), findsOneWidget);
    expect(find.text(AppStrings.loginRecuperacaoEnviadaTitulo), findsNothing);
  });

  testWidgets('falha de rede: o motivo aparece, e dá para tentar de novo', (
    tester,
  ) async {
    final repositorio = _RepositorioFalso(erro: const FalhaDeConexao());
    await _abrir(tester, repositorio: repositorio, email: 'fono@exemplo.com');
    await _enviar(tester);

    expect(find.text(AppStrings.erroConexao), findsOneWidget);
    expect(find.text(AppStrings.loginRecuperacaoEnviadaTitulo), findsNothing);

    repositorio.erro = null;
    await _enviar(tester);
    expect(repositorio.pedidos, hasLength(2));
    expect(
      find.text(AppStrings.loginRecuperacaoEnviadaTitulo),
      findsOneWidget,
    );
  });

  testWidgets('"Enviar de novo" repete o pedido; "Usar outro e-mail" volta', (
    tester,
  ) async {
    final repositorio = await _abrir(tester, email: 'fono@exemplo.com');
    await _enviar(tester);

    await tester.tap(find.text(AppStrings.recuperarEnviarDeNovo));
    await tester.pumpAndSettle();
    expect(repositorio.pedidos, ['fono@exemplo.com', 'fono@exemplo.com']);

    await tester.tap(find.text(AppStrings.recuperarOutroEmail));
    await tester.pumpAndSettle();
    expect(_campo, findsOneWidget);
    expect(find.text(AppStrings.loginRecuperacaoEnviadaTitulo), findsNothing);
  });

  testWidgets('sem conexão, o botão para e diz por quê', (tester) async {
    final repositorio = await _abrir(
      tester,
      online: false,
      email: 'fono@exemplo.com',
    );
    expect(find.text(AppStrings.recuperarExigeConexao), findsOneWidget);

    await _enviar(tester);
    expect(repositorio.pedidos, isEmpty);
  });

  testWidgets('modo de exemplo: avisa que não há e-mail, e não pede', (
    tester,
  ) async {
    final repositorio = await _abrir(
      tester,
      deExemplo: true,
      email: 'fono@exemplo.com',
    );
    expect(find.text(AppStrings.loginRecuperacaoIndisponivel), findsOneWidget);

    await _enviar(tester);
    expect(repositorio.pedidos, isEmpty);
  });

  testWidgets('aberta direto pelo endereço, voltar leva à entrada', (
    tester,
  ) async {
    await _abrir(tester);
    await tester.tap(find.text(AppStrings.recuperarVoltar));
    await tester.pumpAndSettle();
    expect(find.text(_telaDeEntrada), findsOneWidget);
  });

  testWidgets('depois da confirmação, o botão principal volta à entrada', (
    tester,
  ) async {
    await _abrir(tester, email: 'fono@exemplo.com');
    await _enviar(tester);
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.recuperarVoltar),
    );
    await tester.pumpAndSettle();
    expect(find.text(_telaDeEntrada), findsOneWidget);
  });

  testWidgets('no desktop também cabe, com a marca ao lado', (tester) async {
    await _abrir(tester, tamanho: const Size(1440, 900));
    expect(find.text(AppStrings.recuperarTitulo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
