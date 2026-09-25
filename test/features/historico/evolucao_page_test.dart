import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_status_medida.dart';
import 'package:fonar_app/features/analise/data/catalogo_de_referencias_vazio.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/faixa_de_referencia.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/analise/presentation/pages/analise_resultado_page.dart';
import 'package:fonar_app/features/historico/data/limiares_de_mudanca_indefinidos.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/historico/domain/serie_da_medida.dart';
import 'package:fonar_app/features/historico/presentation/pages/evolucao_modo_paciente_page.dart';
import 'package:fonar_app/features/historico/presentation/pages/evolucao_page.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

class _Repositorio implements RepositorioAnalises {
  _Repositorio(this.sessoes, {this.falha = false});

  final List<ResultadoDaAnalise> sessoes;
  final bool falha;

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async =>
      sessoes.firstWhere((s) => s.id == analiseId);

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async {
    if (falha) throw const FalhaDeConexao();
    return sessoes;
  }
}

/// Limiar de TESTE, sem valor clínico nenhum.
class _Limiares implements LimiaresDeMudanca {
  @override
  double? limiar(MedidaAcustica medida) => 0.1;
}

/// Faixa de TESTE para o AVQI, sem valor clínico nenhum.
class _Catalogo implements CatalogoDeReferencias {
  @override
  FaixaDeReferencia? faixa(MedidaAcustica medida, PerfilDeReferencia perfil) =>
      medida == MedidaAcustica.avqi
      ? const FaixaDeReferencia(maximo: 3.3, procedencia: 'Fonte de teste')
      : null;
}

ResultadoDaAnalise _sessao(
  String id,
  DateTime em, {
  double? avqi,
  double? cpps,
}) => ResultadoDaAnalise(
  id: id,
  pacienteId: 'p1',
  situacao: SituacaoDaAnalise.concluida,
  realizadaEm: em,
  medidas: [
    MedidaCalculada(medida: MedidaAcustica.avqi, valor: avqi),
    MedidaCalculada(medida: MedidaAcustica.cpps, valor: cpps),
  ],
);

final _tres = [
  _sessao('s1', DateTime(2026, 5, 28, 9), avqi: 4.61, cpps: 9.8),
  _sessao('s2', DateTime(2026, 6, 18, 9), avqi: 3.58, cpps: null),
  _sessao('s3', DateTime(2026, 7, 23, 9), avqi: 3.12, cpps: 12.4),
];

const _paciente = Paciente(
  id: 'p1',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
);

/// Sobe o app com o roteador de verdade, já na evolução de p1.
Future<GoRouter> _abrir(
  WidgetTester tester, {
  List<ResultadoDaAnalise>? sessoes,
  bool falha = false,
  Paciente paciente = _paciente,
  LimiaresDeMudanca? limiares,
  CatalogoDeReferencias? catalogo,
  Size tamanho = const Size(390, 2400),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      conexaoOnlineProvider.overrideWithValue(true),
      repositorioAnalisesProvider.overrideWithValue(
        _Repositorio(sessoes ?? _tres, falha: falha),
      ),
      pacientesProvider.overrideWith((ref) async => [paciente]),
      if (limiares != null)
        limiaresDeMudancaProvider.overrideWithValue(limiares),
      if (catalogo != null)
        catalogoDeReferenciasProvider.overrideWithValue(catalogo),
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
  roteador.goNamed(
    AppRoutes.evolucaoNome,
    pathParameters: {AppRoutes.paramPacienteId: 'p1'},
  );
  await tester.pumpAndSettle();
  return roteador;
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

String _caminho(GoRouter r) =>
    r.routerDelegate.currentConfiguration.uri.toString();

void main() {
  testWidgets('sem análise concluída: estado vazio, sem gráfico', (
    tester,
  ) async {
    await _abrir(tester, sessoes: const []);

    expect(find.text(AppStrings.evolucaoVaziaTitulo), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('falha ao carregar deixa tentar de novo', (tester) async {
    await _abrir(tester, falha: true);

    expect(find.text(AppStrings.evolucaoErroCarregar), findsOneWidget);
    expect(find.text(AppStrings.tentarNovamente), findsOneWidget);
  });

  testWidgets('gráfico, valores e lista de sessões', (tester) async {
    await _abrir(tester);

    expect(find.byType(EvolucaoPage), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(
      find.text(
        AppStrings.evolucaoSessoes(
          3,
          AppStrings.data(DateTime(2026, 5, 28)),
          AppStrings.data(DateTime(2026, 7, 23)),
        ),
      ),
      findsOneWidget,
    );
    // Mais recente e anterior, lado a lado.
    expect(find.text(AppStrings.evolucaoAnterior), findsOneWidget);
    expect(find.text(AppStrings.evolucaoMaisRecente), findsOneWidget);
    // AVQI não tem unidade: o valor aparece igual na comparação e na lista.
    expect(find.text('3,58'), findsNWidgets(2));
    expect(find.text('3,12'), findsNWidgets(2));
    // Uma linha por sessão; as duas últimas também na comparação.
    expect(find.text(AppStrings.data(DateTime(2026, 5, 28))), findsOneWidget);
    expect(find.text(AppStrings.data(DateTime(2026, 6, 18))), findsNWidgets(2));
    expect(find.text(AppStrings.data(DateTime(2026, 7, 23))), findsNWidgets(2));
  });

  testWidgets('sem limiar validado, nenhuma frase de mudança', (tester) async {
    await _abrir(tester);

    expect(find.text(AppStrings.evolucaoSemLimiar), findsOneWidget);
    expect(find.textContaining(AppStrings.tendenciaMelhorando), findsNothing);
    expect(find.textContaining(AppStrings.evolucaoDesceu), findsNothing);
  });

  testWidgets('com limiar, a direção e a leitura da medida', (tester) async {
    await _abrir(tester, limiares: _Limiares());

    expect(
      find.text(
        AppStrings.evolucaoDirecao(
          'AVQI',
          AppStrings.evolucaoDesceu,
          leitura: AppStrings.tendenciaMelhorando,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.evolucaoSemLimiar), findsNothing);
  });

  testWidgets('trocar a medida troca gráfico e lista; não calculada é dita', (
    tester,
  ) async {
    await _abrir(tester);

    await _tocar(tester, find.text('CPPS').first);

    expect(find.textContaining(AppStrings.medidaCppsDescricao), findsOneWidget);
    expect(find.text(AppStrings.resultadoNaoCalculada), findsOneWidget);
    // A comparação pula a sessão sem valor: 9,8 → 12,4.
    expect(find.text('9,8'), findsOneWidget);
  });

  testWidgets('uma sessão: não há o que comparar', (tester) async {
    await _abrir(tester, sessoes: [_tres.first]);

    expect(find.text(AppStrings.evolucaoUmValor), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('sem faixa: motivo dito uma vez, sem status por linha', (
    tester,
  ) async {
    await _abrir(tester);

    expect(find.text(AppStrings.statusSemReferencia), findsOneWidget);
    expect(find.text(AppStrings.resultadoPerfilIncompleto), findsOneWidget);
    expect(find.byType(AppStatusMedida), findsNothing);
  });

  testWidgets('com faixa: área descrita em texto e status em cada sessão', (
    tester,
  ) async {
    await _abrir(
      tester,
      catalogo: _Catalogo(),
      paciente: Paciente(
        id: 'p1',
        nome: 'Ana de Teste',
        queixa: 'rouquidão',
        direcaoAvqi: DirecaoDaMedida.semComparacao,
        sexo: SexoDeReferencia.feminino,
        dataDeNascimento: DateTime(1985, 7, 2),
      ),
    );

    expect(
      find.text(AppStrings.evolucaoFaixaLegenda('até 3,30')),
      findsOneWidget,
    );
    expect(find.byType(AppStatusMedida), findsNWidgets(3));
    expect(find.text(AppStrings.statusForaDaFaixa), findsNWidgets(2));
    expect(find.text(AppStrings.statusDentroDaFaixa), findsOneWidget);
  });

  testWidgets('tocar numa sessão abre o resultado dela', (tester) async {
    await _abrir(tester);

    // A última ocorrência é a da lista; a primeira, a da comparação.
    await _tocar(
      tester,
      find.text(AppStrings.data(DateTime(2026, 6, 18))).last,
    );

    // Empilhado sobre a evolução: a URL não muda, a tela sim.
    final resultado = tester.widget<AnaliseResultadoPage>(
      find.byType(AnaliseResultadoPage),
    );
    expect(resultado.analiseId, 's2');
    expect(resultado.pacienteId, 'p1');

    // E o voltar do resultado traz de volta à evolução.
    await _tocar(tester, find.bySemanticsLabel(AppStrings.voltar).first);
    expect(find.byType(EvolucaoPage), findsOneWidget);
  });

  testWidgets('o gráfico é um nó só, com descrição, para o leitor de tela', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _abrir(tester);

    expect(
      find.bySemanticsLabel(
        AppStrings.evolucaoGraficoDescricao(
          'AVQI',
          3,
          AppStrings.data(DateTime(2026, 5, 28)),
          AppStrings.data(DateTime(2026, 7, 23)),
        ),
      ),
      findsOneWidget,
    );
    semantica.dispose();
  });

  group('modo paciente', () {
    testWidgets('mostra a medida escolhida, sem classificação nem leitura', (
      tester,
    ) async {
      final roteador = await _abrir(
        tester,
        limiares: _Limiares(),
        catalogo: _Catalogo(),
        paciente: Paciente(
          id: 'p1',
          nome: 'Ana de Teste',
          queixa: 'rouquidão',
          direcaoAvqi: DirecaoDaMedida.semComparacao,
          sexo: SexoDeReferencia.feminino,
          dataDeNascimento: DateTime(1985, 7, 2),
        ),
      );
      await _tocar(tester, find.text('CPPS').first);

      await _tocar(tester, find.text(AppStrings.evolucaoMostrarAoPaciente));

      expect(find.byType(EvolucaoModoPacientePage), findsOneWidget);
      expect(_caminho(roteador), '/pacientes/p1/evolucao/modo-paciente');
      expect(find.text(AppStrings.modoPacienteTitulo), findsOneWidget);
      expect(find.textContaining('CPPS'), findsWidgets);
      expect(find.byType(LineChart), findsOneWidget);
      // Nada do que é conversa do profissional.
      expect(find.byType(AppStatusMedida), findsNothing);
      expect(find.textContaining(AppStrings.tendenciaMelhorando), findsNothing);
      expect(find.textContaining(AppStrings.tendenciaPiorando), findsNothing);
      expect(find.textContaining('rouquidão'), findsNothing);
      expect(find.textContaining('Ana de Teste'), findsNothing);
    });

    testWidgets('sai de volta para a tela do profissional', (tester) async {
      final roteador = await _abrir(tester);
      await _tocar(tester, find.text(AppStrings.evolucaoMostrarAoPaciente));

      await _tocar(tester, find.text(AppStrings.modoPacienteSair));

      expect(find.byType(EvolucaoPage), findsOneWidget);
      expect(_caminho(roteador), '/pacientes/p1/evolucao');
    });
  });

  group('layout', () {
    for (final (nome, tamanho) in [
      ('390', const Size(390, 844)),
      ('390 deitado', const Size(844, 390)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final escala in [1.0, 2.0]) {
        testWidgets('$nome, texto ${escala}x: sem estouro', (tester) async {
          await _abrir(tester, tamanho: tamanho, escala: escala);
          expect(tester.takeException(), isNull);

          await _tocar(tester, find.text(AppStrings.evolucaoMostrarAoPaciente));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('dica de girar o aparelho só no celular em pé', (tester) async {
      await _abrir(tester, tamanho: const Size(390, 844));
      expect(find.text(AppStrings.evolucaoGireAparelho), findsOneWidget);
    });

    testWidgets('no desktop, sem dica de girar', (tester) async {
      await _abrir(tester, tamanho: const Size(1440, 900));
      expect(find.text(AppStrings.evolucaoGireAparelho), findsNothing);
    });
  });

  testWidgets('desktop: sessões ao lado do gráfico; mostrar ao paciente no '
      'cabeçalho', (tester) async {
    await _abrir(tester, tamanho: const Size(1440, 900));

    final grafico = tester.getRect(find.byType(LineChart));
    final sessoes = tester.getRect(find.text(AppStrings.evolucaoSessoesTitulo));
    expect(sessoes.left, greaterThan(grafico.right));
    expect(sessoes.top, lessThan(grafico.bottom));
    // Uma vez só: no cabeçalho, não repetido no corpo.
    final botao = find.text(AppStrings.evolucaoMostrarAoPaciente);
    expect(botao, findsOneWidget);
    expect(tester.getRect(botao).top, lessThan(80));
  });

  testWidgets('resultado leva à evolução', (tester) async {
    final roteador = await _abrir(tester);
    roteador.goNamed(
      AppRoutes.analiseResultadoNome,
      pathParameters: {
        AppRoutes.paramPacienteId: 'p1',
        AppRoutes.paramAnaliseId: 's3',
      },
    );
    await tester.pumpAndSettle();

    await _tocar(tester, find.text(AppStrings.resultadoVerEvolucao));
    expect(find.byType(EvolucaoPage), findsOneWidget);

    await _tocar(tester, find.bySemanticsLabel(AppStrings.voltar).first);
    expect(find.byType(AnaliseResultadoPage), findsOneWidget);
  });
}
