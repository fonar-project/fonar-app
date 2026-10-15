import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/app.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/design_system/widgets/app_indicador_conexao.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';
import 'package:fonar_app/features/captura/presentation/afericao_controlador.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/guia/data/preferencia_do_guia_local.dart';
import 'package:fonar_app/features/guia/domain/passo_do_guia.dart';
import 'package:fonar_app/features/guia/presentation/alvos_do_guia.dart';
import 'package:fonar_app/features/guia/presentation/widgets/guia_na_tela.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/pacientes_list_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

const _desktop = Size(1440, 900);
const _celular = Size(390, 844);

/// O app inteiro, com o guia ligado como fora dos testes — a não ser que
/// [abreSozinho] diga o contrário.
Future<(ProviderContainer, BancoLocal)> _abrir(
  WidgetTester tester, {
  Size janela = _desktop,
  bool abreSozinho = true,
  ContaAutenticada conta = contaDeTeste,
  BancoLocal? banco,
  bool listaVazia = false,
}) async {
  tester.view.physicalSize = janela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final usado = banco ?? bancoEmMemoria();
  if (banco == null) addTearDown(usado.close);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoLocalProvider.overrideWithValue(usado),
      conexaoOnlineProvider.overrideWithValue(false),
      repositorioFilaProvider.overrideWithValue(RepositorioFilaEmMemoria()),
      sessaoProvider.overrideWith(() => Sessao(conta)),
      tokenStorageProvider.overrideWithValue(TokenStorageEmMemoria()),
      guiaAbreSozinhoProvider.overrideWithValue(abreSozinho),
      if (listaVazia)
        pacientesProvider.overrideWith((ref) => Future.value(const [])),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FonarApp()),
  );
  await tester.pumpAndSettle();
  return (container, usado);
}

// Com a sessão aberta há o relógio do bloqueio: desmontar e descartar ainda
// no corpo, antes de o teste conferir timers — ver bloqueio_test.
Future<void> _fechar(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

final _guia = find.byType(GuiaNaTela);

Finder _titulo(int passo) => find.descendant(
  of: _guia,
  matching: find.text(passosDoGuiaDoInicio[passo].titulo),
);

Future<void> _proximo(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.guiaProximo));
  await tester.pumpAndSettle();
}

/// O retângulo do elemento de [papel], na tela, como o guia o vê.
Rect _ondeOGuiaVe(WidgetTester tester, ProviderContainer c, PapelNoGuia papel) {
  final area = tester.renderObject<RenderBox>(_guia);
  final local = c.read(alvosDoGuiaProvider).onde(papel, area)!;
  return MatrixUtils.transformRect(area.getTransformTo(null), local);
}

/// Onde o véu está aberto, na tela.
Rect _recorteDesenhado(WidgetTester tester) {
  final veu = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_Veu',
  );
  // ignore: avoid_dynamic_calls
  final local =
      (tester.widget<CustomPaint>(veu).painter! as dynamic).recorte as Rect;
  return MatrixUtils.transformRect(
    tester.renderObject<RenderBox>(veu).getTransformTo(null),
    local,
  );
}

bool _focoNoGuia() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<GuiaNaTela>() !=
    null;

bool _focoEm(WidgetTester tester, String rotulo) =>
    Focus.of(tester.element(find.text(rotulo))).hasPrimaryFocus;

double _opacidade(WidgetTester tester, Finder alvo) {
  final fades = tester.widgetList<FadeTransition>(
    find.ancestor(of: alvo, matching: find.byType(FadeTransition)),
  );
  final opacidades = tester.widgetList<Opacity>(
    find.ancestor(of: alvo, matching: find.byType(Opacity)),
  );
  return fades.fold(1.0, (acc, f) => acc * f.opacity.value) *
      opacidades.fold(1.0, (acc, o) => acc * o.opacity);
}

void main() {
  group('preferência do guia', () {
    late BancoLocal banco;
    setUp(() => banco = bancoEmMemoria());
    tearDown(() => banco.close());

    test('por conta: marcar uma não marca a outra', () async {
      final pref = PreferenciaDoGuiaLocal(banco);
      expect(
        await pref.jaViu(
          PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid),
        ),
        isFalse,
      );

      await pref.marcarVisto(
        PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid),
      );

      expect(
        await pref.jaViu(
          PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid),
        ),
        isTrue,
      );
      expect(
        await pref.jaViu(PreferenciaDoGuiaLocal.chaveDoInicio(outraConta.uid)),
        isFalse,
      );
    });

    test('a chave tem versão, para um guia novo depois de atualizar', () {
      expect(PreferenciaDoGuiaLocal.chaveDoInicio('abc'), 'guia.inicio.v1.abc');
    });
  });

  group('primeira vez', () {
    testWidgets('abre sozinho, no passo da Nova avaliação', (tester) async {
      final (c, _) = await _abrir(tester);

      expect(_guia, findsOneWidget);
      expect(_titulo(0), findsOneWidget);
      expect(find.text(AppStrings.guiaPasso(1, 6).toUpperCase()), findsOne);
      expect(find.text(AppStrings.guiaPular), findsOneWidget);
      // O balão fica embaixo do botão que ele explica.
      final botao = tester.getRect(
        find.widgetWithText(FilledButton, AppStrings.navNovaAvaliacao),
      );
      expect(tester.getRect(_titulo(0)).top, greaterThan(botao.bottom));
      await _fechar(tester, c);
    });

    testWidgets('em 1440 px, a Ajuda cabe no cabeçalho sem empurrar o botão', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);

      final busca = tester.getCenter(find.byType(TextField));
      final botao = tester.getCenter(
        find.widgetWithText(FilledButton, AppStrings.navNovaAvaliacao),
      );
      final ajuda = tester.getRect(find.text(AppStrings.ajuda));
      expect(botao.dy, closeTo(busca.dy, 1));
      expect(ajuda.center.dy, closeTo(busca.dy, 1));
      expect(ajuda.left, greaterThan(botao.dx));
      await _fechar(tester, c);
    });

    testWidgets('Pular guarda que esta conta viu, e ele não volta', (
      tester,
    ) async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final (c, _) = await _abrir(tester, banco: banco);

      await tester.tap(find.text(AppStrings.guiaPular));
      await tester.pumpAndSettle();

      expect(_guia, findsNothing);
      expect(
        await PreferenciaDoGuiaLocal(banco)
            .jaViu(PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid)),
        isTrue,
      );
      await _fechar(tester, c);

      // Abrir o app de novo no mesmo aparelho.
      final (c2, _) = await _abrir(tester, banco: banco);
      expect(find.byType(PacientesListPage), findsOneWidget);
      expect(_guia, findsNothing);
      await _fechar(tester, c2);
    });

    testWidgets('outra conta no mesmo aparelho também vê', (tester) async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      await PreferenciaDoGuiaLocal(banco)
          .marcarVisto(PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid));

      final (c, _) = await _abrir(tester, banco: banco, conta: outraConta);

      expect(_titulo(0), findsOneWidget);
      await _fechar(tester, c);
    });

    testWidgets('desligado, como nos outros testes, não abre', (tester) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);

      expect(find.byType(PacientesListPage), findsOneWidget);
      expect(_guia, findsNothing);
      await _fechar(tester, c);
    });

    testWidgets('Esc fecha, e também guarda', (tester) async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final (c, _) = await _abrir(tester, banco: banco);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_guia, findsNothing);
      expect(
        await PreferenciaDoGuiaLocal(banco)
            .jaViu(PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid)),
        isTrue,
      );
      await _fechar(tester, c);
    });
  });

  group('os passos', () {
    testWidgets('Próximo percorre os seis, cada um dizendo o que é', (
      tester,
    ) async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final (c, _) = await _abrir(tester, banco: banco);

      for (var i = 0; i < passosDoGuiaDoInicio.length; i++) {
        expect(_titulo(i), findsOneWidget, reason: 'passo ${i + 1}');
        expect(
          find.descendant(
            of: _guia,
            matching: find.text(passosDoGuiaDoInicio[i].texto),
          ),
          findsOneWidget,
        );
        // Voltar só existe depois do primeiro.
        expect(
          find.text(AppStrings.guiaAnterior),
          i == 0 ? findsNothing : findsOneWidget,
        );
        if (i < passosDoGuiaDoInicio.length - 1) await _proximo(tester);
      }

      expect(find.text(AppStrings.guiaProximo), findsNothing);
      await tester.tap(find.text(AppStrings.guiaConcluir));
      await tester.pumpAndSettle();

      expect(_guia, findsNothing);
      expect(
        await PreferenciaDoGuiaLocal(banco)
            .jaViu(PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid)),
        isTrue,
      );
      await _fechar(tester, c);
    });

    testWidgets('Anterior volta um passo', (tester) async {
      final (c, _) = await _abrir(tester);
      await _proximo(tester);
      await _proximo(tester);

      await tester.tap(find.text(AppStrings.guiaAnterior));
      await tester.pumpAndSettle();

      expect(_titulo(1), findsOneWidget);
      await _fechar(tester, c);
    });

    testWidgets('no desktop, fila, conta e conexão são da barra lateral', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester);
      await _proximo(tester);
      await _proximo(tester);

      // O recorte é o item "Fila de envio", e o balão fica à direita dele.
      final fila = _ondeOGuiaVe(tester, c, PapelNoGuia.fila);
      expect(
        // `first`: o título do balão repete o nome; o item vem antes.
        fila.contains(tester.getCenter(find.text(AppStrings.navFila).first)),
        isTrue,
      );
      expect(tester.getRect(_titulo(2)).left, greaterThan(fila.right));

      await _proximo(tester);
      final conta = _ondeOGuiaVe(tester, c, PapelNoGuia.conta);
      expect(
        conta.contains(tester.getCenter(find.text(AppStrings.navConta).first)),
        isTrue,
      );

      await _proximo(tester);
      final conexao = _ondeOGuiaVe(tester, c, PapelNoGuia.conexao);
      expect(
        conexao.contains(tester.getCenter(find.byType(AppIndicadorConexao))),
        isTrue,
      );
      await _fechar(tester, c);
    });

    testWidgets('no celular, a fila é a aba de baixo, e o balão fica em cima', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, janela: _celular);
      await _proximo(tester);
      await _proximo(tester);

      final aba = tester.getCenter(find.text(AppStrings.navFilaCurto));
      final fila = _ondeOGuiaVe(tester, c, PapelNoGuia.fila);
      expect(fila.contains(aba), isTrue);
      expect(tester.getRect(_titulo(2)).bottom, lessThan(fila.top));
      await _fechar(tester, c);
    });

    testWidgets('a janela muda de tamanho: o recorte vai junto', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester);
      await _proximo(tester);
      await _proximo(tester);

      // Do item da barra lateral para a aba de baixo.
      tester.view.physicalSize = _celular;
      await tester.pumpAndSettle();

      final aba = tester.getCenter(find.text(AppStrings.navFilaCurto));
      expect(_ondeOGuiaVe(tester, c, PapelNoGuia.fila).contains(aba), isTrue);
      // E é ali que o véu está aberto.
      expect(_recorteDesenhado(tester).contains(aba), isTrue);
      await _fechar(tester, c);
    });

    testWidgets(
      'a janela estreita no desktop: a Ajuda anda, o recorte vai junto',
      (tester) async {
        final (c, _) = await _abrir(tester, janela: const Size(1920, 1080));
        for (var i = 0; i < 5; i++) {
          await _proximo(tester);
        }
        expect(_titulo(5), findsOneWidget);

        // A mesma escala (120%), o canto direito mais perto.
        tester.view.physicalSize = const Size(1700, 1080);
        await tester.pumpAndSettle();

        final ajuda = tester.getCenter(find.text(AppStrings.ajuda).first);
        expect(_recorteDesenhado(tester).contains(ajuda), isTrue);
        await _fechar(tester, c);
      },
    );

    testWidgets(
      'lista vazia: aponta o "Cadastrar paciente" e explica a lista',
      (tester) async {
        final (c, _) = await _abrir(tester, listaVazia: true);

        final cadastrar = tester.getRect(
          find.widgetWithText(FilledButton, AppStrings.pacientesCadastrar),
        );
        final recorte = _ondeOGuiaVe(tester, c, PapelNoGuia.novaAvaliacao);
        expect(recorte.center.dx, closeTo(cadastrar.center.dx, 0.5));
        expect(recorte.center.dy, closeTo(cadastrar.center.dy, 0.5));

        await _proximo(tester);
        expect(
          find.descendant(
            of: _guia,
            matching: find.text(AppStrings.guiaListaVaziaTexto),
          ),
          findsOneWidget,
        );
        expect(
          c
              .read(alvosDoGuiaProvider)
              .onde(PapelNoGuia.lista, tester.renderObject<RenderBox>(_guia)),
          isNull,
        );
        await _fechar(tester, c);
      },
    );

    testWidgets('o recorte segue a escala da interface (Full HD, 120%)', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, janela: const Size(1920, 1080));

      final botao = tester.getRect(
        find.widgetWithText(FilledButton, AppStrings.navNovaAvaliacao),
      );
      final visto = _ondeOGuiaVe(tester, c, PapelNoGuia.novaAvaliacao);
      expect(visto.left, closeTo(botao.left, 0.5));
      expect(visto.top, closeTo(botao.top, 0.5));
      expect(visto.width, closeTo(botao.width, 0.5));
      expect(visto.height, closeTo(botao.height, 0.5));
      await _fechar(tester, c);
    });
  });

  group('teclado e leitor de tela', () {
    testWidgets('o foco começa no Próximo e continua nele', (tester) async {
      final (c, _) = await _abrir(tester);

      expect(_focoEm(tester, AppStrings.guiaProximo), isTrue);
      // Enter aciona o botão em foco.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(_titulo(1), findsOneWidget);
      expect(_focoEm(tester, AppStrings.guiaProximo), isTrue);
      await _fechar(tester, c);
    });

    testWidgets('Tab circula dentro do balão', (tester) async {
      final (c, _) = await _abrir(tester);
      await _proximo(tester);

      // Pular, Anterior e Próximo: dez Tabs dão mais de três voltas.
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focoNoGuia(), isTrue, reason: 'Tab $i');
      }
      await _fechar(tester, c);
    });

    testWidgets('cada passo é anunciado, com o número e o texto', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester);
      final passo = passosDoGuiaDoInicio.first;

      expect(
        tester.takeAnnouncements(),
        contains(
          isAccessibilityAnnouncement(
            '${AppStrings.guiaPasso(1, 6)}. ${passo.titulo}. ${passo.texto}',
          ),
        ),
      );

      await _proximo(tester);
      final segundo = passosDoGuiaDoInicio[1];
      expect(
        tester.takeAnnouncements(),
        contains(
          isAccessibilityAnnouncement(
            '${AppStrings.guiaPasso(2, 6)}. ${segundo.titulo}. '
            '${segundo.texto}',
          ),
        ),
      );
      await _fechar(tester, c);
    });

    testWidgets('com movimento reduzido, o passo novo aparece pronto', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final (c, _) = await _abrir(tester);

      await tester.tap(find.text(AppStrings.guiaProximo));
      await tester.pump();

      expect(_opacidade(tester, _titulo(1)), 1);
      await _fechar(tester, c);
    });

    testWidgets('sem movimento reduzido, o texto novo entra', (tester) async {
      final (c, _) = await _abrir(tester);

      await tester.tap(find.text(AppStrings.guiaProximo));
      await tester.pump();

      expect(_titulo(0), findsNothing);
      expect(_opacidade(tester, _titulo(1)), lessThan(1));
      await tester.pumpAndSettle();
      await _fechar(tester, c);
    });
  });

  group('Ajuda', () {
    for (final (nome, rota) in [
      ('Conta', AppRoutes.contaNome),
      ('Fila', AppRoutes.filaNome),
      ('Histórico', AppRoutes.historicoNome),
      ('Nova avaliação', AppRoutes.novaAvaliacaoNome),
    ]) {
      testWidgets('no desktop, no cabeçalho da tela $nome', (tester) async {
        final (c, _) = await _abrir(tester, abreSozinho: false);
        c.read(routerProvider).goNamed(rota);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.ajuda), findsOneWidget);
        await _fechar(tester, c);
      });
    }

    testWidgets('no celular, só no topo da lista de pacientes', (tester) async {
      final (c, _) = await _abrir(tester, janela: _celular, abreSozinho: false);
      expect(find.text(AppStrings.ajuda), findsOneWidget);

      c.read(routerProvider).goNamed(AppRoutes.contaNome);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ajuda), findsNothing);
      await _fechar(tester, c);
    });

    for (final (nome, janela) in [
      ('desktop', _desktop),
      ('celular', _celular),
    ]) {
      testWidgets('Rever o guia abre o guia ($nome)', (tester) async {
        final (c, _) = await _abrir(tester, janela: janela, abreSozinho: false);

        await tester.tap(find.text(AppStrings.ajuda));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.ajudaReverGuia));
        await tester.pumpAndSettle();

        expect(_titulo(0), findsOneWidget);
        await _fechar(tester, c);
      });
    }

    testWidgets('Rever o guia, da Conta, leva à lista e abre lá', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);
      c.read(routerProvider).goNamed(AppRoutes.contaNome);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.ajuda));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.ajudaReverGuia));
      await tester.pumpAndSettle();

      expect(find.byType(PacientesListPage), findsOneWidget);
      expect(_titulo(0), findsOneWidget);
      // Já na lista, o recorte é o botão de verdade, e não onde ele estava
      // no meio da transição.
      final botao = tester.getRect(
        find.widgetWithText(FilledButton, AppStrings.navNovaAvaliacao),
      );
      final visto = _ondeOGuiaVe(tester, c, PapelNoGuia.novaAvaliacao);
      expect(visto.top, closeTo(botao.top, 0.5));
      await _fechar(tester, c);
    });

    testWidgets('num cadastro com alteração, pergunta antes; ficar cancela', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);
      c.read(routerProvider).goNamed(AppRoutes.novaAvaliacaoNome);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Maria');
      await tester.pumpAndSettle();

      Future<void> reverGuia() async {
        await tester.tap(find.text(AppStrings.ajuda));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.ajudaReverGuia));
        await tester.pumpAndSettle();
      }

      await reverGuia();
      expect(find.text(AppStrings.saidaTitulo), findsOneWidget);
      await tester.tap(find.text(AppStrings.saidaContinuar));
      await tester.pumpAndSettle();
      expect(find.byType(PacientesListPage), findsNothing);
      expect(c.read(pedidoDoGuiaProvider), isFalse);

      // Mais tarde, à lista por outro caminho: o guia não aparece.
      await tester.tap(find.text(AppStrings.navPacientes).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saidaDescartar));
      await tester.pumpAndSettle();
      expect(find.byType(PacientesListPage), findsOneWidget);
      expect(_guia, findsNothing);
      await _fechar(tester, c);
    });

    testWidgets('num cadastro com alteração, descartar leva ao guia', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);
      c.read(routerProvider).goNamed(AppRoutes.novaAvaliacaoNome);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Maria');
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.ajuda));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.ajudaReverGuia));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saidaDescartar));
      await tester.pumpAndSettle();

      expect(find.byType(PacientesListPage), findsOneWidget);
      expect(_titulo(0), findsOneWidget);
      await _fechar(tester, c);
    });

    testWidgets('pelo teclado: o menu recebe o foco', (tester) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);

      await tester.tap(find.text(AppStrings.ajuda));
      await tester.pumpAndSettle();

      expect(_focoEm(tester, AppStrings.ajudaReverGuia), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ajudaReverGuia), findsNothing);
      await _fechar(tester, c);
    });

    testWidgets('Atalhos de teclado: os que existem, e Esc fecha', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);

      await tester.tap(find.text(AppStrings.ajuda));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.ajudaAtalhos));
      await tester.pumpAndSettle();

      for (final tecla in [
        AppStrings.atalhosTab,
        AppStrings.atalhosEspaco,
        AppStrings.atalhosR,
        AppStrings.atalhosSetas,
        AppStrings.atalhosMais,
        AppStrings.atalhosZero,
      ]) {
        expect(find.text(tecla), findsOneWidget, reason: tecla);
      }
      expect(_focoEm(tester, AppStrings.atalhosFechar), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.atalhosEspacoTexto), findsNothing);
      await _fechar(tester, c);
    });
  });

  group('dicas por tela', () {
    const paciente = 'exemplo-a';
    const analise = 'exemplo-a-4';
    final telas = <(DicaDeTela, String, Map<String, String>)>[
      (
        DicaDeTela.gravacao,
        AppRoutes.capturaNome,
        {AppRoutes.paramPacienteId: paciente},
      ),
      (
        DicaDeTela.resultado,
        AppRoutes.analiseResultadoNome,
        {
          AppRoutes.paramPacienteId: paciente,
          AppRoutes.paramAnaliseId: analise,
        },
      ),
      (
        DicaDeTela.capeV,
        AppRoutes.capeVNome,
        {
          AppRoutes.paramPacienteId: paciente,
          AppRoutes.paramAnaliseId: analise,
        },
      ),
      (
        DicaDeTela.laudo,
        AppRoutes.laudoNome,
        {
          AppRoutes.paramPacienteId: paciente,
          AppRoutes.paramAnaliseId: analise,
        },
      ),
    ];

    /// `pump` limitado: o medidor e a prévia do laudo nunca assentam — ver
    /// a matriz de layout.
    Future<void> desenhar(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    /// O app com o guia da lista já visto, para só a dica abrir.
    Future<(ProviderContainer, BancoLocal)> irPara(
      WidgetTester tester,
      String rota,
      Map<String, String> parametros, {
      Size janela = _desktop,
      BancoLocal? banco,
    }) async {
      final usado = banco ?? bancoEmMemoria();
      if (banco == null) addTearDown(usado.close);
      await PreferenciaDoGuiaLocal(usado)
          .marcarVisto(PreferenciaDoGuiaLocal.chaveDoInicio(contaDeTeste.uid));
      final (c, _) = await _abrir(tester, janela: janela, banco: usado);
      c.read(routerProvider).goNamed(rota, pathParameters: parametros);
      await desenhar(tester);
      return (c, usado);
    }

    Finder dica(DicaDeTela d) =>
        find.descendant(of: _guia, matching: find.text(d.passo.titulo));

    for (final (d, rota, parametros) in telas) {
      for (final (nome, janela) in [
        ('desktop', _desktop),
        ('celular', _celular),
      ]) {
        testWidgets('${d.name} ($nome): abre uma vez, sobre o elemento', (
          tester,
        ) async {
          final banco = bancoEmMemoria();
          addTearDown(banco.close);
          final (c, _) = await irPara(
            tester,
            rota,
            parametros,
            janela: janela,
            banco: banco,
          );

          expect(dica(d), findsOneWidget);
          // Um balão só: sem número de passo e sem "Pular".
          expect(find.text(AppStrings.guiaPular), findsNothing);
          expect(find.text(AppStrings.dicaEntendi), findsOneWidget);
          expect(_focoEm(tester, AppStrings.dicaEntendi), isTrue);
          if (d != DicaDeTela.laudo || janela == _desktop) {
            expect(
              c
                  .read(alvosDoGuiaProvider)
                  .onde(d.passo.papel, tester.renderObject<RenderBox>(_guia)),
              isNotNull,
              reason: 'o elemento de ${d.name} está na tela',
            );
          }

          await tester.tap(find.text(AppStrings.dicaEntendi));
          await desenhar(tester);
          expect(_guia, findsNothing);
          expect(
            await PreferenciaDoGuiaLocal(banco)
                .jaViu(PreferenciaDoGuiaLocal.chaveDaDica(d, contaDeTeste.uid)),
            isTrue,
          );

          // Sair e voltar: não abre de novo.
          c.read(routerProvider).goNamed(AppRoutes.pacientesNome);
          await desenhar(tester);
          c.read(routerProvider).goNamed(rota, pathParameters: parametros);
          await desenhar(tester);
          expect(_guia, findsNothing);
          await _fechar(tester, c);
        });
      }
    }

    testWidgets('gravação: aponta o "Medir ruído ambiente"', (tester) async {
      final (c, _) = await irPara(tester, AppRoutes.capturaNome, {
        AppRoutes.paramPacienteId: paciente,
      });

      final medir = tester.getRect(
        find.widgetWithText(FilledButton, AppStrings.afericaoMedir),
      );
      final visto = _ondeOGuiaVe(tester, c, PapelNoGuia.afericao);
      expect(visto.center.dx, closeTo(medir.center.dx, 0.5));
      expect(visto.center.dy, closeTo(medir.center.dy, 0.5));
      await _fechar(tester, c);
    });

    testWidgets('gravação: Espaço com a dica aberta fecha a dica, e não mede', (
      tester,
    ) async {
      final (c, _) = await irPara(tester, AppRoutes.capturaNome, {
        AppRoutes.paramPacienteId: paciente,
      });
      expect(dica(DicaDeTela.gravacao), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await desenhar(tester);

      expect(_guia, findsNothing);
      // O Espaço foi do "Entendi", que tinha o foco — não da gravação.
      expect(c.read(afericaoControladorProvider), isA<AfericaoNaoIniciada>());
      expect(find.text(AppStrings.afericaoMedir), findsOneWidget);
      await _fechar(tester, c);
    });

    testWidgets('desligadas, como nos outros testes, não abrem', (
      tester,
    ) async {
      final (c, _) = await _abrir(tester, abreSozinho: false);
      for (final (_, rota, parametros) in telas) {
        c.read(routerProvider).goNamed(rota, pathParameters: parametros);
        await desenhar(tester);
        expect(_guia, findsNothing, reason: rota);
      }
      await _fechar(tester, c);
    });

    test('a chave de cada dica é por tela e por conta', () {
      expect(
        PreferenciaDoGuiaLocal.chaveDaDica(DicaDeTela.laudo, 'abc'),
        'dica.laudo.v1.abc',
      );
      expect(
        DicaDeTela.values.map((d) => d.passo.papel).toSet(),
        hasLength(DicaDeTela.values.length),
      );
    });
  });

  group('quem abre', () {
    List<String> quemUsa(String widget) =>
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .map((f) => (f.path.replaceAll(r'\', '/'), f.readAsStringSync()))
            // A própria declaração não conta.
            .where((f) => !f.$1.startsWith('lib/features/guia/'))
            .where((f) => f.$2.contains('$widget('))
            .map((f) => f.$1)
            .toList();

    test('o guia, só a lista de pacientes: nunca a gravação nem o modo '
        'paciente', () {
      expect(quemUsa('AberturaDoGuia'), [
        'lib/features/pacientes/presentation/pages/pacientes_list_page.dart',
      ]);
    });

    test('as dicas, só as quatro telas — e o modo paciente nunca', () {
      expect(
        quemUsa('AberturaDaDica'),
        unorderedEquals([
          'lib/features/captura/presentation/widgets/gravacao_guiada.dart',
          'lib/features/analise/presentation/pages/analise_resultado_page.dart',
          'lib/features/cape_v/presentation/pages/cape_v_page.dart',
          'lib/features/laudo/presentation/pages/laudo_page.dart',
        ]),
      );
    });
  });
}
