import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/analise/presentation/pages/analise_resultado_page.dart';
import 'package:fonar_app/features/historico/domain/entrada_do_historico.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/historico/presentation/historico_controlador.dart';
import 'package:fonar_app/features/historico/presentation/pages/historico_page.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

const _ana = Paciente(
  id: 'p-ana',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
);
const _bia = Paciente(
  id: 'p-bia',
  nome: 'Bia de Teste',
  queixa: 'soprosidade',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
);

ResultadoDaAnalise _analise(
  String id,
  String pacienteId, {
  DateTime? em,
  SituacaoDaAnalise situacao = SituacaoDaAnalise.concluida,
  double? avqi = 3.12,
  bool exemplo = false,
}) => ResultadoDaAnalise(
  id: id,
  pacienteId: pacienteId,
  situacao: situacao,
  realizadaEm: em,
  medidas: [
    if (situacao == SituacaoDaAnalise.concluida)
      MedidaCalculada(medida: MedidaAcustica.avqi, valor: avqi),
  ],
  qualidade: const {},
  exemplo: exemplo,
);

class _Analises implements RepositorioAnalises {
  _Analises(this.porPaciente);
  final Map<String, List<ResultadoDaAnalise>> porPaciente;

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async {
    for (final l in porPaciente.values) {
      for (final a in l) {
        if (a.id == analiseId) return a;
      }
    }
    throw StateError('sem $analiseId');
  }

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async =>
      porPaciente[pacienteId] ?? const [];
}

final _padrao = {
  'p-ana': [
    _analise('an-1', 'p-ana', em: DateTime(2026, 8, 12, 9, 30)),
    _analise('an-3', 'p-ana', em: DateTime(2026, 9, 20, 14)),
  ],
  'p-bia': [
    _analise('an-2', 'p-bia', em: DateTime(2026, 9, 2, 10), avqi: null),
    _analise('an-4', 'p-bia', situacao: SituacaoDaAnalise.processando),
  ],
};

Future<GoRouter> _abrir(
  WidgetTester tester, {
  Map<String, List<ResultadoDaAnalise>>? analises,
  List<String> comLaudo = const [],
  Size tamanho = const Size(390, 1400),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final laudos = RepositorioLaudosEmMemoria();
  for (final id in comLaudo) {
    await laudos.registrar(
      Laudo(
        analiseId: id,
        pacienteId: id == 'an-2' ? 'p-bia' : 'p-ana',
        conclusao: 'conclusão (teste)',
        geradoEm: DateTime(2026, 9, 21),
        pdf: Uint8List(0),
      ),
    );
  }
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(false),
      pacientesProvider.overrideWith((ref) async => const [_ana, _bia]),
      repositorioAnalisesProvider.overrideWithValue(
        _Analises(analises ?? _padrao),
      ),
      repositorioLaudosProvider.overrideWithValue(laudos),
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
  roteador.goNamed(AppRoutes.historicoNome);
  await tester.pumpAndSettle();
  return roteador;
}

double _topo(WidgetTester tester, String texto) =>
    tester.getTopLeft(find.text(texto).first).dy;

void main() {
  group('montarHistorico', () {
    EntradaDoHistorico entrada(Paciente p, ResultadoDaAnalise a) =>
        EntradaDoHistorico(paciente: p, analise: a, temLaudo: false);

    test('mais recente primeiro; sem data (em análise) no topo', () {
      final lista = montarHistorico([
        entrada(_ana, _analise('velha', 'p-ana', em: DateTime(2026, 1, 1))),
        entrada(_bia, _analise('nova', 'p-bia', em: DateTime(2026, 9, 1))),
        entrada(
          _bia,
          _analise(
            'sem-data',
            'p-bia',
            situacao: SituacaoDaAnalise.processando,
          ),
        ),
      ]);

      expect(
        [for (final e in lista) e.analise.id],
        ['sem-data', 'nova', 'velha'],
      );
    });

    test('a busca filtra pelo paciente, sem ligar para acento', () {
      final lista = montarHistorico([
        entrada(_ana, _analise('a', 'p-ana', em: DateTime(2026, 1, 1))),
        entrada(_bia, _analise('b', 'p-bia', em: DateTime(2026, 1, 2))),
      ], termo: 'ROUQUIDAO');

      expect([for (final e in lista) e.analise.id], ['a']);
    });
  });

  test(
    'junta as análises de todos os pacientes, e marca as com laudo',
    () async {
      final laudos = RepositorioLaudosEmMemoria();
      await laudos.registrar(
        Laudo(
          analiseId: 'an-1',
          pacienteId: 'p-ana',
          conclusao: 'c',
          geradoEm: DateTime(2026, 9, 21),
          pdf: Uint8List(0),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          pacientesProvider.overrideWith((ref) async => const [_ana, _bia]),
          repositorioAnalisesProvider.overrideWithValue(_Analises(_padrao)),
          repositorioLaudosProvider.overrideWithValue(laudos),
        ],
      );
      addTearDown(container.dispose);
      container.listen(historicoProvider, (_, _) {});

      final historico = await container.read(historicoProvider.future);

      expect(
        [for (final e in historico) e.analise.id],
        ['an-4', 'an-3', 'an-2', 'an-1'],
      );
      expect(
        {for (final e in historico) e.analise.id: e.temLaudo},
        {'an-4': false, 'an-3': false, 'an-2': false, 'an-1': true},
      );
      expect(historico.last.paciente.nome, 'Ana de Teste');
    },
  );

  testWidgets('na navegação principal, e agrupado por mês', (tester) async {
    await _abrir(tester);

    expect(find.byType(HistoricoPage), findsOneWidget);
    expect(find.text(AppStrings.navHistorico), findsWidgets);
    // Em análise no topo, depois setembro, depois agosto.
    expect(
      _topo(tester, AppStrings.historicoSemData),
      lessThan(_topo(tester, 'Setembro de 2026')),
    );
    expect(
      _topo(tester, 'Setembro de 2026'),
      lessThan(_topo(tester, 'Agosto de 2026')),
    );
  });

  testWidgets('cada avaliação diz de quem, quando e o AVQI — sem '
      'classificar', (tester) async {
    await _abrir(tester, comLaudo: ['an-3']);

    expect(find.text('20 set 2026, 14:00'), findsOneWidget);
    expect(find.text('3,12'), findsNWidgets(2));
    expect(find.text(AppStrings.historicoAvqiNaoCalculado), findsOneWidget);
    expect(find.text(AppStrings.historicoProcessando), findsOneWidget);
    expect(find.text(AppStrings.historicoLaudoGerado), findsOneWidget);
    // Nenhuma palavra de leitura: sem faixa validada, o número é só número.
    expect(find.textContaining('normal', findRichText: true), findsNothing);
    expect(find.textContaining('alterad', findRichText: true), findsNothing);
  });

  testWidgets('tocar abre o resultado; voltar traz de volta', (tester) async {
    await _abrir(tester);

    await tester.tap(find.text('20 set 2026, 14:00'));
    await tester.pumpAndSettle();

    // `push`: o resultado vem por cima do histórico.
    expect(find.byType(AnaliseResultadoPage), findsOneWidget);
    // O paciente certo, no cabeçalho do resultado.
    expect(
      find.descendant(
        of: find.byType(AnaliseResultadoPage),
        matching: find.text('Ana de Teste'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel(AppStrings.voltar).first);
    await tester.pumpAndSettle();
    expect(find.byType(HistoricoPage), findsOneWidget);
  });

  testWidgets('buscar filtra; sem resultado, diz e oferece limpar', (
    tester,
  ) async {
    await _abrir(tester);

    await tester.enterText(find.byType(TextField), 'bia');
    await tester.pumpAndSettle();
    expect(find.text('Ana de Teste'), findsNothing);
    expect(find.text('Bia de Teste'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'caio');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.historicoSemResultado('caio')), findsOneWidget);

    await tester.tap(find.text(AppStrings.historicoLimparBusca));
    await tester.pumpAndSettle();
    expect(find.text('Ana de Teste'), findsNWidgets(2));
  });

  testWidgets('sem avaliação nenhuma, leva à nova avaliação', (tester) async {
    await _abrir(tester, analises: const {});

    expect(find.text(AppStrings.historicoVazioTitulo), findsOneWidget);
    expect(find.text(AppStrings.navNovaAvaliacao), findsWidgets);
  });

  testWidgets('resultado de exemplo é avisado como tal', (tester) async {
    await _abrir(
      tester,
      analises: {
        'p-ana': [
          _analise('an-x', 'p-ana', em: DateTime(2026, 9, 1), exemplo: true),
        ],
      },
    );

    expect(find.text(AppStrings.resultadoExemploTitulo), findsOneWidget);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome em 200% não estoura — com cinco abas', (tester) async {
      await _abrir(tester, tamanho: tamanho, escala: 2);

      expect(tester.takeException(), isNull);
    });
  }
}
