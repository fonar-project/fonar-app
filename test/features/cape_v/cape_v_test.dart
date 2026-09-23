import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/cape_v/data/repositorio_cape_v_local.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/cape_v/presentation/apresentacao_cape_v.dart';
import 'package:fonar_app/features/cape_v/presentation/cape_v_controlador.dart';
import 'package:fonar_app/features/cape_v/presentation/pages/cape_v_page.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/repositorios_em_memoria.dart';

Map<ParametroCapeV, NotaCapeV> _todasSemDesvio() => {
  for (final p in ParametroCapeV.values) p: const NotaCapeV(valor: 0),
};

/// Análises de teste: [dono] é o paciente a quem todas pertencem.
class _Analises implements RepositorioAnalises {
  _Analises({this.dono = 'p1'});
  final String dono;

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async =>
      ResultadoDaAnalise(
        id: analiseId,
        pacienteId: dono,
        situacao: SituacaoDaAnalise.concluida,
      );

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async => [];
}

Future<RepositorioCapeVEmMemoria> _abrir(
  WidgetTester tester, {
  AvaliacaoCapeV? existente,
  String donoDaAnalise = 'p1',
  Size tamanho = const Size(390, 2600),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final repositorio = RepositorioCapeVEmMemoria();
  if (existente != null) await repositorio.registrar(existente);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioCapeVProvider.overrideWithValue(repositorio),
        repositorioAnalisesProvider.overrideWithValue(
          _Analises(dono: donoDaAnalise),
        ),
        relogioProvider.overrideWithValue(() => DateTime(2026, 9, 23, 11)),
        conexaoOnlineProvider.overrideWithValue(true),
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
      child: MaterialApp.router(
        theme: AppTheme.claro,
        routerConfig: GoRouter(
          initialLocation: '/resultado/cape-v',
          routes: [
            GoRoute(
              name: AppRoutes.analiseResultadoNome,
              path: '/resultado',
              builder: (_, _) =>
                  const Scaffold(body: Text('tela do resultado')),
              routes: [
                GoRoute(
                  path: 'cape-v',
                  builder: (_, _) =>
                      const CapeVPage(pacienteId: 'p1', analiseId: 'an-1'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repositorio;
}

Finder get _escalas => find.byType(Slider);

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// Marca a escala [i] tocando nela a [fracao] da largura.
Future<void> _marcar(WidgetTester tester, int i, double fracao) async {
  final escala = _escalas.at(i);
  await tester.ensureVisible(escala);
  await tester.pumpAndSettle();
  final caixa = tester.getRect(escala);
  // O Slider desenha a trilha com um recuo de cada lado: tocar dentro desse
  // recuo, à esquerda, dá 0. O pixel exato da borda fica fora da área de
  // toque, daí os 4 px para dentro.
  final x = (caixa.left + caixa.width * fracao).clamp(
    caixa.left + 4,
    caixa.right - 4,
  );
  await tester.tapAt(Offset(x, caixa.center.dy));
  await tester.pumpAndSettle();
}

Future<void> _registrar(WidgetTester tester) =>
    _tocar(tester, find.text(AppStrings.capeVRegistrar));

void main() {
  group('conferirNotas', () {
    test('nada marcado: todos os seis apontados', () {
      expect(conferirNotas(const {}), {
        for (final p in ParametroCapeV.values) p: ProblemaNaNota.naoMarcada,
      });
    });

    test('zero é resposta: sem desvio não pede consistência', () {
      expect(conferirNotas(_todasSemDesvio()), isEmpty);
    });

    test('com desvio pede consistência; pitch e loudness, o sentido', () {
      final notas = {
        ..._todasSemDesvio(),
        ParametroCapeV.rugosidade: const NotaCapeV(valor: 30),
        ParametroCapeV.pitch: const NotaCapeV(
          valor: 20,
          consistencia: Consistencia.consistente,
        ),
      };
      expect(conferirNotas(notas), {
        ParametroCapeV.rugosidade: ProblemaNaNota.semConsistencia,
        ParametroCapeV.pitch: ProblemaNaNota.semDirecao,
      });
    });

    test('voltar para zero apaga consistência e sentido', () {
      const nota = NotaCapeV(
        valor: 40,
        consistencia: Consistencia.intermitente,
        direcao: DirecaoDoDesvio.acima,
      );
      final zerada = nota.comValor(0);
      expect(zerada.valor, 0);
      expect(zerada.consistencia, isNull);
      expect(zerada.direcao, isNull);
    });

    test('valor fora de 0–100 é contido', () {
      expect(const NotaCapeV().comValor(140).valor, 100);
      expect(const NotaCapeV().comValor(-5).valor, 0);
    });
  });

  test('resumo da nota para a tela de resultado', () {
    expect(
      resumirNota(
        ParametroCapeV.pitch,
        const NotaCapeV(
          valor: 37,
          consistencia: Consistencia.consistente,
          direcao: DirecaoDoDesvio.abaixo,
        ),
      ),
      '37 · consistente · mais grave',
    );
  });

  group('tela', () {
    testWidgets('começa sem nada marcado — nem zero', (tester) async {
      await _abrir(tester);

      expect(_escalas, findsNWidgets(6));
      expect(find.text(AppStrings.capeVNaoMarcado), findsNWidgets(6));
      // Consistência só aparece com desvio.
      expect(find.text(AppStrings.capeVConsistencia), findsNothing);
    });

    testWidgets('leitor de tela ouve "não marcado", não "0"', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrir(tester);

      String valorLido() => tester
          .getSemantics(find.bySemanticsLabel(AppStrings.capeVGrauGeral))
          .getSemanticsData()
          .value;

      expect(valorLido(), AppStrings.capeVNaoMarcado);

      await _marcar(tester, 0, 0.5);
      expect(valorLido(), matches(RegExp(r'^\d+ de 100$')));
      semantica.dispose();
    });

    testWidgets('registrar sem marcar aponta cada parâmetro', (tester) async {
      final repositorio = await _abrir(tester);

      await _registrar(tester);

      expect(find.text(AppStrings.capeVMarque), findsNWidgets(6));
      expect(await repositorio.daAnalise('an-1'), isNull);
    });

    testWidgets('marcar desvio mostra consistência; zerar esconde', (
      tester,
    ) async {
      await _abrir(tester);

      await _marcar(tester, 0, 0.5);
      expect(find.text(AppStrings.capeVConsistencia), findsOneWidget);
      expect(find.text(AppStrings.capeVNaoMarcado), findsNWidgets(5));

      await _marcar(tester, 0, 0);
      expect(find.text('0'), findsOneWidget);
      expect(find.text(AppStrings.capeVConsistencia), findsNothing);
    });

    testWidgets('pitch com desvio pede também o sentido', (tester) async {
      await _abrir(tester);

      await _marcar(tester, ParametroCapeV.pitch.index, 0.5);

      expect(find.text(AppStrings.capeVSentido), findsOneWidget);
      expect(find.text(AppStrings.capeVPitchAbaixo), findsOneWidget);
    });

    testWidgets('toque na ponta esquerda de escala sem marca marca 0', (
      tester,
    ) async {
      // O Slider só avisa quando o valor muda, e a escala sem marca está no
      // mínimo por dentro: sem cuidado, tocar no 0 não marcava nada.
      await _abrir(tester);

      await _marcar(tester, 0, 0);

      expect(find.text('0'), findsOneWidget);
      expect(find.text(AppStrings.capeVNaoMarcado), findsNWidgets(5));
    });

    testWidgets('teclado: seta para a esquerda numa escala sem marca marca 0', (
      tester,
    ) async {
      await _abrir(tester);

      // Tab: voltar, depois a primeira escala.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('tudo marcado: registra e volta ao resultado', (tester) async {
      final repositorio = await _abrir(tester);

      for (var i = 0; i < 6; i++) {
        await _marcar(tester, i, 0);
      }
      // Rugosidade com desvio, intermitente.
      await _marcar(tester, ParametroCapeV.rugosidade.index, 0.5);
      await _tocar(tester, find.text(AppStrings.capeVIntermitente));
      await tester.enterText(
        find.byType(TextField),
        '  Voz rugosa no fim das frases (teste).  ',
      );

      await _registrar(tester);

      expect(find.text('tela do resultado'), findsOneWidget);
      final registrada = (await repositorio.daAnalise('an-1'))!;
      expect(registrada.pacienteId, 'p1');
      expect(registrada.notas[ParametroCapeV.grauGeral]!.valor, 0);
      final rugosidade = registrada.notas[ParametroCapeV.rugosidade]!;
      expect(rugosidade.valor, greaterThan(0));
      expect(rugosidade.consistencia, Consistencia.intermitente);
      expect(registrada.comentarios, 'Voz rugosa no fim das frases (teste).');
    });

    testWidgets('avaliação já registrada abre para edição, como estava', (
      tester,
    ) async {
      await _abrir(
        tester,
        existente: AvaliacaoCapeV(
          analiseId: 'an-1',
          pacienteId: 'p1',
          registradaEm: DateTime(2026, 9, 20),
          comentarios: 'Comentário anterior (teste).',
          notas: {
            ..._todasSemDesvio(),
            ParametroCapeV.tensao: const NotaCapeV(
              valor: 42,
              consistencia: Consistencia.consistente,
            ),
          },
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text(AppStrings.capeVNaoMarcado), findsNothing);
      expect(find.text('Comentário anterior (teste).'), findsOneWidget);
    });

    for (final (nome, tamanho) in [
      ('celular', const Size(390, 844)),
      ('desktop', const Size(1440, 900)),
    ]) {
      testWidgets('$nome não estoura com o texto do sistema em 200%', (
        tester,
      ) async {
        await _abrir(tester, tamanho: tamanho, escala: 2);
        await _registrar(tester);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('paciente da análise', () {
    // Achado da revisão de 23/09: a CAPE-V era registrada com o paciente da
    // rota sem conferir de quem era a análise.
    testWidgets('análise de outro paciente: nada de formulário', (
      tester,
    ) async {
      await _abrir(tester, donoDaAnalise: 'outro-paciente');

      expect(find.text(AppStrings.resultadoDeOutroPaciente), findsOneWidget);
      expect(_escalas, findsNothing);
    });

    test('o controlador também recusa, sem depender da tela', () async {
      final repositorio = RepositorioCapeVEmMemoria();
      final container = ProviderContainer(
        overrides: [
          repositorioCapeVProvider.overrideWithValue(repositorio),
          repositorioAnalisesProvider.overrideWithValue(
            _Analises(dono: 'outro-paciente'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(capeVControladorProvider('an-1'), (_, _) {});
      await container.read(capeVControladorProvider('an-1').future);
      final controlador = container.read(
        capeVControladorProvider('an-1').notifier,
      );
      for (final p in ParametroCapeV.values) {
        controlador.marcar(p, 0);
      }

      final registrou = await controlador.registrar(
        pacienteId: 'p1',
        comentarios: '',
      );

      expect(registrou, isFalse);
      expect(await repositorio.daAnalise('an-1'), isNull);
      expect(
        container.read(capeVControladorProvider('an-1')).value?.erroGeral,
        AppStrings.resultadoDeOutroPaciente,
      );
    });
  });

  test(
    'tela fechada no meio do registro: sem erro, e o resumo atualiza',
    () async {
      // Achado da revisão de 23/09: a invalidação usava o `ref` descartado.
      final repositorio = _RepositorioLento();
      final container = ProviderContainer(
        overrides: [
          repositorioCapeVProvider.overrideWithValue(repositorio),
          repositorioAnalisesProvider.overrideWithValue(_Analises()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(capeVDaAnaliseProvider('an-1'), (_, _) {});
      expect(
        await container.read(capeVDaAnaliseProvider('an-1').future),
        isNull,
      );

      final tela = container.listen(
        capeVControladorProvider('an-1'),
        (_, _) {},
      );
      await container.read(capeVControladorProvider('an-1').future);
      final controlador = container.read(
        capeVControladorProvider('an-1').notifier,
      );
      for (final p in ParametroCapeV.values) {
        controlador.marcar(p, 0);
      }
      final registrando = controlador.registrar(
        pacienteId: 'p1',
        comentarios: '',
      );
      await Future<void>.delayed(Duration.zero);
      tela.close();
      await container.pump();

      repositorio.espera.complete();
      await expectLater(registrando, completion(isTrue));
      expect(
        await container.read(capeVDaAnaliseProvider('an-1').future),
        isNotNull,
      );
    },
  );
}

/// Segura o registro até o teste soltar.
class _RepositorioLento extends RepositorioCapeVEmMemoria {
  final espera = Completer<void>();

  @override
  Future<void> registrar(AvaliacaoCapeV avaliacao) async {
    await espera.future;
    await super.registrar(avaliacao);
  }
}
