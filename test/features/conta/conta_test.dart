import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/app_estrutura.dart';
import 'package:fonar_app/app/licencas.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/data/profissional_atual.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/repositorio_autenticacao.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/auth/presentation/pages/login_page.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/conta/data/repositorio_da_conta_local.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';
import 'package:fonar_app/features/conta/presentation/conta_controlador.dart';
import 'package:fonar_app/features/conta/presentation/pages/conta_page.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/presentation/pages/fila_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

const _perfil = Profissional(nome: 'Fon.ª Teste', registro: 'CRFa 0-00000');

/// O perfil e a autenticação ao mesmo tempo: a Conta salva num e sai pelo
/// outro.
class _Conta implements RepositorioDaConta, RepositorioAutenticacao {
  _Conta({this.falha = false, this.guardado = _perfil});
  final bool falha;
  final Profissional? guardado;
  final salvos = <(String, Profissional)>[];
  var saiu = false;

  @override
  Future<Profissional?> perfil(String uid) async => guardado;

  @override
  Future<void> salvar(String uid, Profissional profissional) async {
    if (falha) throw const FalhaDeConexao();
    salvos.add((uid, profissional));
  }

  @override
  Future<void> sair() async => saiu = true;

  @override
  Future<ContaAutenticada> entrar({
    required String email,
    required String senha,
  }) async => contaDeTeste;

  @override
  Future<ContaAutenticada?> contaGuardada() async => saiu ? null : contaDeTeste;

  @override
  Future<void> pedirRedefinicaoDeSenha(String email) async {}
}

ItemDaFila _envio(String id) => ItemDaFila(
  id: 'envio-$id',
  pacienteId: 'p1',
  nomeDoPaciente: 'Ana de Teste',
  sessaoId: id,
  criadoEm: DateTime(2026, 9, 23, 10),
  amostras: [
    Amostra(
      id: 'a-$id',
      pacienteId: 'p1',
      sessaoId: id,
      tarefa: TarefaDeGravacao.vogalSustentada,
      caminho: '/amostras/p1/a-$id.wav',
      gravadaEm: DateTime(2026, 9, 23, 9, 50),
      duracao: const Duration(seconds: 3),
      taxaDeAmostragem: 44100,
      canais: 1,
      problemas: const [],
    ),
  ],
);

Future<(GoRouter, _Conta, ProviderContainer)> _abrir(
  WidgetTester tester, {
  _Conta? conta,
  int envios = 0,
  Size tamanho = const Size(390, 1800),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final fila = RepositorioFilaEmMemoria();
  for (var i = 0; i < envios; i++) {
    await fila.adicionar(_envio('s$i'));
  }
  final c = conta ?? _Conta();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      // Sem rede: a fila não tenta enviar, e os envios ficam pendentes.
      conexaoOnlineProvider.overrideWithValue(false),
      bancoDeTeste(),
      repositorioFilaProvider.overrideWithValue(fila),
      repositorioDaContaProvider.overrideWithValue(c),
      repositorioAutenticacaoProvider.overrideWithValue(c),
      sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
    ],
  );
  addTearDown(container.dispose);
  final roteador = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  roteador.goNamed(AppRoutes.contaNome);
  await tester.pumpAndSettle();
  return (roteador, c, container);
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

String _texto(WidgetTester tester, String rotulo) =>
    tester.widget<TextField>(_campo(rotulo)).controller!.text;

bool _habilitado(WidgetTester tester, String rotulo) {
  final botao = find.ancestor(
    of: find.text(rotulo),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(botao.first).onPressed != null;
}

void main() {
  group('validarDados', () {
    const atual = Profissional(
      nome: 'Antes',
      registro: 'CRFa 0',
      email: 'a@b.invalid',
    );

    test('apara e junta espaços; o e-mail não muda', () {
      final r = validarDados(
        atual: atual,
        nome: '  Ana   Souza ',
        registro: ' CRFa  2-12345 ',
      );
      expect(r, isA<DadosValidos>());
      final p = (r as DadosValidos).profissional;
      expect(p.nome, 'Ana Souza');
      expect(p.registro, 'CRFa 2-12345');
      expect(p.email, 'a@b.invalid');
    });

    test('nome e registro em branco apontam cada campo', () {
      final r = validarDados(atual: atual, nome: ' ', registro: '');
      expect(r, isA<DadosInvalidos>());
      r as DadosInvalidos;
      expect(r.nome, ProblemaNosDados.nomeVazio);
      expect(r.registro, ProblemaNosDados.registroVazio);
    });
  });

  test('a licença da Urbanist aparece junto das dos pacotes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registrarLicencas();
    final pacotes = await LicenseRegistry.licenses
        .expand((l) => l.packages)
        .toList();
    expect(pacotes, contains('Urbanist'));
  });

  group('tela', () {
    testWidgets('mostra os dados da conta; sem mudança, nada a salvar', (
      tester,
    ) async {
      await _abrir(tester);

      expect(find.byType(ContaPage), findsOneWidget);
      expect(find.byType(AppEstrutura), findsOneWidget);
      expect(find.text(contaDeTeste.email), findsOneWidget);
      expect(_texto(tester, AppStrings.contaCampoNome), _perfil.nome);
      expect(_habilitado(tester, AppStrings.contaSalvar), isFalse);
      expect(find.text(AppStrings.contaNadaMudou), findsOneWidget);
    });

    testWidgets('primeira entrada no aparelho: perfil vazio, e a barra lateral '
        'mostra o e-mail e pede os dados', (tester) async {
      final (_, conta, _) = await _abrir(
        tester,
        conta: _Conta(guardado: null),
        tamanho: const Size(1440, 1200),
      );

      expect(_texto(tester, AppStrings.contaCampoNome), isEmpty);
      expect(_texto(tester, AppStrings.contaCampoRegistro), isEmpty);
      expect(find.text(AppStrings.contaPerfilIncompleto), findsOneWidget);
      // O e-mail no lugar do nome, na barra lateral e nos dados da conta.
      expect(find.text(contaDeTeste.email), findsNWidgets(2));

      await tester.enterText(_campo(AppStrings.contaCampoNome), 'Ana Souza');
      await tester.enterText(_campo(AppStrings.contaCampoRegistro), 'CRFa 1');
      await tester.pumpAndSettle();
      await _tocar(tester, find.text(AppStrings.contaSalvar));

      expect(conta.salvos.single.$2.nome, 'Ana Souza');
      expect(find.text(AppStrings.contaPerfilIncompleto), findsNothing);
      expect(find.text('Ana Souza'), findsWidgets);
    });

    testWidgets('nome em branco: erro no campo, com o que fazer', (
      tester,
    ) async {
      final (_, conta, _) = await _abrir(tester);

      await tester.enterText(_campo(AppStrings.contaCampoNome), '   ');
      await tester.pumpAndSettle();
      await _tocar(tester, find.text(AppStrings.contaSalvar));

      expect(find.text(AppStrings.contaInformeNome), findsOneWidget);
      expect(conta.salvos, isEmpty);

      // Mexer no campo tira o erro.
      await tester.enterText(_campo(AppStrings.contaCampoNome), 'A');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.contaInformeNome), findsNothing);
    });

    testWidgets('salvar atualiza quem assina — e a barra lateral', (
      tester,
    ) async {
      final (_, conta, container) = await _abrir(
        tester,
        tamanho: const Size(1440, 1200),
      );

      await tester.enterText(
        _campo(AppStrings.contaCampoRegistro),
        ' CRFa 2-12345 ',
      );
      await tester.pumpAndSettle();
      await _tocar(tester, find.text(AppStrings.contaSalvar));

      expect(find.text(AppStrings.contaSalvo), findsOneWidget);
      expect(conta.salvos.single.$2.registro, 'CRFa 2-12345');
      // Guardado na conta de quem está com a sessão aberta.
      expect(conta.salvos.single.$1, contaDeTeste.uid);
      expect(
        container.read(profissionalAtualProvider).registro,
        'CRFa 2-12345',
      );
      // Rodapé da barra lateral.
      expect(find.text('CRFa 2-12345'), findsWidgets);
    });

    testWidgets('falha ao salvar é dita, e nada muda', (tester) async {
      final (_, _, container) = await _abrir(
        tester,
        conta: _Conta(falha: true),
      );
      final antes = container.read(profissionalAtualProvider).nome;

      await tester.enterText(_campo(AppStrings.contaCampoNome), 'Outro Nome');
      await tester.pumpAndSettle();
      await _tocar(tester, find.text(AppStrings.contaSalvar));

      expect(find.text(AppStrings.erroConexao), findsOneWidget);
      expect(container.read(profissionalAtualProvider).nome, antes);
    });

    testWidgets('envios na fila aparecem, com atalho para ela', (tester) async {
      await _abrir(tester, envios: 2);

      expect(find.text(AppStrings.contaEnviosPendentes(2)), findsOneWidget);
      await _tocar(tester, find.text(AppStrings.contaVerFila));
      expect(find.byType(FilaPage), findsOneWidget);
    });

    testWidgets('faixas de referência: diz que o catálogo está vazio e '
        'por quê', (tester) async {
      await _abrir(tester);

      expect(find.text(AppStrings.contaFaixasTitulo), findsOneWidget);
      expect(find.text(AppStrings.contaFaixasPendente), findsOneWidget);
      expect(find.text(AppStrings.contaFaixasVazio), findsOneWidget);
      expect(find.text(AppStrings.contaFaixasSoLeitura), findsOneWidget);
    });

    testWidgets('fila vazia: sem atalho', (tester) async {
      await _abrir(tester);

      expect(find.text(AppStrings.contaEnviosPendentes(0)), findsOneWidget);
      expect(find.text(AppStrings.contaVerFila), findsNothing);
    });

    testWidgets('licenças abrem a página de licenças', (tester) async {
      await _abrir(tester);

      final botao = find.text(AppStrings.contaLicencas);
      await tester.ensureVisible(botao);
      await tester.pumpAndSettle();
      await tester.tap(botao);
      // Sem `pumpAndSettle`: a página de licenças lê os textos de verdade,
      // fora do relógio do teste, e o indicador de carregamento não para.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LicensePage), findsOneWidget);
    });

    group('sair', () {
      testWidgets('pede confirmação e diz o que fica na fila', (tester) async {
        final (_, conta, _) = await _abrir(tester, envios: 1);

        await _tocar(tester, find.text(AppStrings.contaSair));

        expect(find.text(AppStrings.contaSairPergunta), findsOneWidget);
        expect(find.text(AppStrings.contaSairComFila(1)), findsOneWidget);
        expect(conta.saiu, isFalse);

        await _tocar(tester, find.text(AppStrings.contaCancelar));
        expect(find.text(AppStrings.contaSairPergunta), findsNothing);
        expect(conta.saiu, isFalse);
      });

      // A pergunta passou a ser a do design system (achado 5.1 da revisão de
      // 24/09): Esc cancela, como em qualquer confirmação destrutiva do
      // aplicativo. Antes ela abria dentro da tela, e o Esc não fazia nada.
      testWidgets('Esc fecha a pergunta e não sai da conta', (tester) async {
        final (_, conta, _) = await _abrir(tester);

        await _tocar(tester, find.text(AppStrings.contaSair));
        expect(find.text(AppStrings.contaSairPergunta), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.contaSairPergunta), findsNothing);
        expect(conta.saiu, isFalse);
      });

      testWidgets('confirmado, encerra a sessão e volta ao login', (
        tester,
      ) async {
        final (_, conta, container) = await _abrir(tester);
        container.read(sessaoProvider.notifier).abrir(contaDeTeste);
        container
            .read(profissionalAtualProvider.notifier)
            .definir(const Profissional(nome: 'Da sessão', registro: 'X'));

        await _tocar(tester, find.text(AppStrings.contaSair));
        expect(find.text(AppStrings.contaSairTexto), findsOneWidget);
        await _tocar(tester, find.text(AppStrings.contaConfirmarSair));

        expect(conta.saiu, isTrue);
        expect(find.byType(LoginPage), findsOneWidget);
        // A fila pausa junto (revisão de 23/09).
        expect(container.read(sessaoAbertaProvider), isFalse);
        expect(
          container.read(profissionalAtualProvider).nome,
          isNot('Da sessão'),
        );
      });
    });

    group('layout', () {
      for (final (nome, tamanho) in [
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final escala in [1.0, 2.0]) {
          testWidgets('$nome, texto ${escala}x: sem estouro', (tester) async {
            await _abrir(tester, tamanho: tamanho, escala: escala, envios: 1);
            expect(tester.takeException(), isNull);

            await _tocar(tester, find.text(AppStrings.contaSair));
            expect(tester.takeException(), isNull);
          });
        }
      }
    });
  });

  test('sair com a tela já fechada: sem erro, e a sessão encerra', () async {
    // Achado da revisão de 23/09: o `ref` descartado fazia `sair` devolver
    // falso com o token já limpo.
    final conta = _SaidaLenta();
    final container = ProviderContainer(
      overrides: [
        repositorioAutenticacaoProvider.overrideWithValue(conta),
        repositorioDaContaProvider.overrideWithValue(_Conta()),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessaoProvider.notifier).abrir(contaDeTeste);
    container
        .read(profissionalAtualProvider.notifier)
        .definir(const Profissional(nome: 'Da sessão', registro: 'X'));

    final tela = container.listen(contaControladorProvider, (_, _) {});
    final saindo = container.read(contaControladorProvider.notifier).sair();
    expect(container.read(sessaoAbertaProvider), isFalse);
    tela.close();
    await container.pump();

    conta.espera.complete();
    await expectLater(saindo, completion(isTrue));
    expect(container.read(profissionalAtualProvider).nome, isNot('Da sessão'));
  });
}

class _SaidaLenta extends AutenticacaoFalsa {
  final espera = Completer<void>();

  @override
  Future<void> sair() => espera.future;
}
