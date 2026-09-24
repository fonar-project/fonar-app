import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_campo_texto.dart';
import 'package:fonar_app/features/auth/data/bloqueio_por_inatividade.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_placeholder.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/auth/domain/repositorio_autenticacao.dart';
import 'package:fonar_app/features/conta/data/repositorio_da_conta_placeholder.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';
import 'package:fonar_app/features/auth/presentation/pages/login_page.dart';
import 'package:fonar_app/features/auth/presentation/pages/tela_de_bloqueio.dart';
import 'package:fonar_app/features/auth/presentation/widgets/vigia_de_inatividade.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

const _limite = Duration(minutes: 5);

/// Aceita só a senha "certa".
class _Autenticacao implements RepositorioAutenticacao {
  final pedidos = <(String, String)>[];

  @override
  Future<void> entrar({required String email, required String senha}) async {
    pedidos.add((email, senha));
    if (senha != 'certa') throw const CredencialInvalida();
  }
}

class _ContaQueNaoSai implements RepositorioDaConta {
  @override
  Future<void> salvar(Profissional profissional) async {}

  @override
  Future<void> sair() => Future.error(const FalhaDesconhecida());
}

class _Cena {
  _Cena(this.container, this.autenticacao);
  final ProviderContainer container;
  final _Autenticacao autenticacao;
  var agora = DateTime(2026, 9, 24, 10);

  bool get bloqueado => container.read(bloqueioPorInatividadeProvider);
}

/// Avança o relógio do app e os timers juntos.
Future<void> _passar(WidgetTester tester, _Cena c, Duration d) async {
  c.agora = c.agora.add(d);
  await tester.pump(d);
}

Future<_Cena> _abrir(
  WidgetTester tester, {
  bool online = true,
  bool saidaFalha = false,
  Size tamanho = const Size(390, 844),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final autenticacao = _Autenticacao();
  late _Cena cena;
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(online),
      sessaoAbertaProvider.overrideWith(() => Sessao(true)),
      relogioProvider.overrideWithValue(() => cena.agora),
      limiteDeInatividadeProvider.overrideWithValue(_limite),
      repositorioAutenticacaoProvider.overrideWithValue(autenticacao),
      // O cofre do sistema não existe no teste.
      tokenStorageProvider.overrideWithValue(TokenStorageEmMemoria()),
      if (saidaFalha)
        repositorioDaContaProvider.overrideWithValue(_ContaQueNaoSai()),
      pacientesProvider.overrideWith(
        (ref) async => const [
          Paciente(
            id: 'p1',
            nome: 'Ana de Teste',
            queixa: 'rouquidão',
            direcaoAvqi: DirecaoDaMedida.semComparacao,
          ),
        ],
      ),
    ],
  );
  cena = _Cena(container, autenticacao);
  _aberta = container;
  final roteador = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.claro,
        routerConfig: roteador,
        builder: (_, filho) => VigiaDeInatividade(child: filho!),
      ),
    ),
  );
  roteador.goNamed(AppRoutes.novaAvaliacaoNome);
  await tester.pumpAndSettle();
  return cena;
}

Finder _campo(String rotulo) => find.descendant(
  of: find.widgetWithText(AppCampoTexto, rotulo),
  matching: find.byType(TextField),
);

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto).last);
  await tester.pumpAndSettle();
}

ProviderContainer? _aberta;

/// Um teste do bloqueio. O app é desmontado no fim do corpo, e não num
/// `addTearDown`: o relógio do bloqueio precisa ser desarmado antes de o
/// teste conferir que não sobrou timer pendente.
void _testar(String nome, Future<void> Function(WidgetTester) corpo) {
  testWidgets(nome, (tester) async {
    try {
      await corpo(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      _aberta?.dispose();
      _aberta = null;
    }
  });
}

void main() {
  _testar('sem uso pelo tempo todo, bloqueia; um segundo antes, não', (
    tester,
  ) async {
    final c = await _abrir(tester);

    await _passar(tester, c, _limite - const Duration(seconds: 1));
    expect(c.bloqueado, isFalse);

    await _passar(tester, c, const Duration(seconds: 1));
    await tester.pump();
    expect(c.bloqueado, isTrue);
    expect(find.byType(TelaDeBloqueio), findsOneWidget);
  });

  _testar('tocar na tela conta como uso e adia o bloqueio', (tester) async {
    final c = await _abrir(tester);

    await _passar(tester, c, const Duration(minutes: 3));
    await tester.tap(find.text(AppStrings.cadastroTitulo).first);
    await _passar(tester, c, const Duration(minutes: 3));
    expect(c.bloqueado, isFalse);

    await _passar(tester, c, const Duration(minutes: 2));
    await tester.pump();
    expect(c.bloqueado, isTrue);
  });

  _testar('bloqueado, esconde o que estava na tela do leitor de tela e '
      'do toque', (tester) async {
    final semantica = tester.ensureSemantics();
    final c = await _abrir(tester);
    expect(find.semantics.byLabel(AppStrings.cadastroCampoNome), findsWidgets);

    await _passar(tester, c, _limite);
    await tester.pump();

    expect(find.semantics.byLabel(AppStrings.cadastroCampoNome), findsNothing);
    expect(find.semantics.byLabel(AppStrings.bloqueioTitulo), findsWidgets);
    semantica.dispose();
  });

  _testar('senha em branco ou errada não desbloqueia, e diz por quê', (
    tester,
  ) async {
    final c = await _abrir(tester);
    await _passar(tester, c, _limite);
    await tester.pump();

    await _tocar(tester, AppStrings.bloqueioDesbloquear);
    expect(find.text(AppStrings.bloqueioInformeSenha), findsOneWidget);
    expect(c.autenticacao.pedidos, isEmpty);

    await tester.enterText(_campo(AppStrings.loginCampoSenha), 'errada');
    await _tocar(tester, AppStrings.bloqueioDesbloquear);
    expect(find.text(AppStrings.bloqueioSenhaNaoConfere), findsOneWidget);
    expect(c.bloqueado, isTrue);
  });

  _testar('a senha certa desbloqueia, e a tela volta como estava', (
    tester,
  ) async {
    final c = await _abrir(tester);
    await tester.enterText(
      _campo(AppStrings.cadastroCampoNome),
      'Caio de Teste',
    );
    await _passar(tester, c, _limite);
    await tester.pump();

    await tester.enterText(_campo(AppStrings.loginCampoSenha), 'certa');
    await _tocar(tester, AppStrings.bloqueioDesbloquear);

    expect(c.bloqueado, isFalse);
    expect(find.byType(TelaDeBloqueio), findsNothing);
    // Conferida com o e-mail de quem está na sessão.
    expect(c.autenticacao.pedidos.single.$1, isNotEmpty);
    // O cadastro pela metade continua lá.
    expect(
      tester
          .widget<TextField>(_campo(AppStrings.cadastroCampoNome))
          .controller!
          .text,
      'Caio de Teste',
    );
  });

  _testar('bloqueia de novo depois de desbloquear', (tester) async {
    final c = await _abrir(tester);
    for (var vez = 0; vez < 2; vez++) {
      await _passar(tester, c, _limite);
      await tester.pump();
      expect(c.bloqueado, isTrue, reason: 'vez $vez');
      await tester.enterText(_campo(AppStrings.loginCampoSenha), 'certa');
      await _tocar(tester, AppStrings.bloqueioDesbloquear);
      expect(c.bloqueado, isFalse, reason: 'vez $vez');
    }
    expect(tester.takeException(), isNull);
  });

  _testar('sem conexão: diz que não confere a senha, como o login '
      'offline', (tester) async {
    final c = await _abrir(tester, online: false);
    await _passar(tester, c, _limite);
    await tester.pump();

    expect(find.text(AppStrings.bloqueioOfflineTitulo), findsOneWidget);
    expect(_campo(AppStrings.loginCampoSenha), findsNothing);

    await _tocar(tester, AppStrings.bloqueioContinuarOffline);
    expect(c.bloqueado, isFalse);
    expect(c.autenticacao.pedidos, isEmpty);
  });

  _testar('"Sair da conta" fecha a sessão e vai para o login', (tester) async {
    final c = await _abrir(tester);
    await _passar(tester, c, _limite);
    await tester.pump();

    await _tocar(tester, AppStrings.bloqueioSair);

    expect(c.container.read(sessaoAbertaProvider), isFalse);
    expect(c.bloqueado, isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TelaDeBloqueio), findsNothing);
  });

  _testar('sair que falha ainda vai para o login: a tela de baixo não '
      'reaparece', (tester) async {
    final c = await _abrir(tester, saidaFalha: true);
    await tester.enterText(
      _campo(AppStrings.cadastroCampoNome),
      'Caio de Teste',
    );
    await _passar(tester, c, _limite);
    await tester.pump();

    await _tocar(tester, AppStrings.bloqueioSair);

    expect(c.container.read(sessaoAbertaProvider), isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Caio de Teste'), findsNothing);
  });

  _testar('sem sessão aberta, nunca bloqueia', (tester) async {
    final c = await _abrir(tester);
    c.container.read(sessaoAbertaProvider.notifier).encerrar();
    await tester.pump();

    await _passar(tester, c, _limite * 3);
    await tester.pump();

    expect(c.bloqueado, isFalse);
  });

  _testar('voltando do segundo plano depois do prazo, bloqueia na hora', (
    tester,
  ) async {
    final c = await _abrir(tester);

    // O sistema segurou o app: o relógio de verdade andou, os timers não.
    c.agora = c.agora.add(_limite * 2);
    c.container.read(bloqueioPorInatividadeProvider.notifier).conferir();
    await tester.pump();

    expect(c.bloqueado, isTrue);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 700)),
    ('desktop', const Size(1440, 900)),
  ]) {
    _testar('$nome em 200% não estoura', (tester) async {
      final c = await _abrir(tester, tamanho: tamanho, escala: 2);
      await _passar(tester, c, _limite);
      await tester.pump();

      expect(find.byType(TelaDeBloqueio), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
