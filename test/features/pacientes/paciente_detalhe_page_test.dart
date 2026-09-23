import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/analise/presentation/pages/analise_resultado_page.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/consentimento/presentation/pages/consentimento_page.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/presentation/pages/fila_page.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/historico/presentation/pages/evolucao_page.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/paciente_detalhe_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/repositorios_em_memoria.dart';

class _Consentimentos implements RepositorioConsentimento {
  _Consentimentos({required this.tem});
  final bool tem;

  @override
  Future<Consentimento?> buscar(String pacienteId) async => tem
      ? Consentimento(
          pacienteId: pacienteId,
          registradoEm: DateTime(2026, 7, 1, 9, 30),
          versaoDoTermo: 'teste-1',
          quemAutoriza: QuemAutoriza.paciente,
        )
      : null;

  @override
  Future<Consentimento> registrar(String id, PedidoDeConsentimento p) =>
      throw UnimplementedError();
}

class _Analises implements RepositorioAnalises {
  _Analises(this.sessoes);
  final List<ResultadoDaAnalise> sessoes;

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async =>
      sessoes.firstWhere((s) => s.id == analiseId);

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async =>
      sessoes;
}

ResultadoDaAnalise _sessao(
  String id,
  DateTime? em, {
  double? avqi,
  bool amostraRuim = false,
  SituacaoDaAnalise situacao = SituacaoDaAnalise.concluida,
}) => ResultadoDaAnalise(
  id: id,
  pacienteId: 'p1',
  situacao: situacao,
  realizadaEm: em,
  medidas: [
    if (avqi != null) MedidaCalculada(medida: MedidaAcustica.avqi, valor: avqi),
  ],
  qualidade: {
    TarefaDeGravacao.vogalSustentada: QualidadeDaAmostra(
      adequada: !amostraRuim,
    ),
  },
);

final _paciente = Paciente(
  id: 'p1',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
  sexo: SexoDeReferencia.feminino,
  dataDeNascimento: DateTime(1985, 7, 2),
);

Future<GoRouter> _abrir(
  WidgetTester tester, {
  Paciente? paciente,
  bool consentimento = true,
  List<ResultadoDaAnalise> sessoes = const [],
  List<Laudo> laudos = const [],
  int naFila = 0,
  Size tamanho = const Size(390, 2000),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final repositorioLaudos = RepositorioLaudosEmMemoria();
  for (final l in laudos) {
    await repositorioLaudos.registrar(l);
  }
  final fila = RepositorioFilaEmMemoria();
  for (var i = 0; i < naFila; i++) {
    await fila.adicionar(
      ItemDaFila(
        id: 'envio-s$i',
        pacienteId: 'p1',
        nomeDoPaciente: 'Ana de Teste',
        sessaoId: 's$i',
        amostras: const [],
        criadoEm: DateTime(2026, 9, 23),
      ),
    );
  }

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      // Sem rede: a fila guarda e não envia.
      conexaoOnlineProvider.overrideWithValue(false),
      relogioProvider.overrideWithValue(() => DateTime(2026, 9, 23)),
      pacientesProvider.overrideWith((ref) async => [paciente ?? _paciente]),
      repositorioConsentimentoProvider.overrideWithValue(
        _Consentimentos(tem: consentimento),
      ),
      repositorioAnalisesProvider.overrideWithValue(_Analises(sessoes)),
      repositorioLaudosProvider.overrideWithValue(repositorioLaudos),
      repositorioFilaProvider.overrideWithValue(fila),
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
    AppRoutes.pacienteDetalheNome,
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

bool _habilitado(WidgetTester tester, String rotulo) {
  final botao = find.ancestor(
    of: find.text(rotulo),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(botao.first).onPressed != null;
}

String _caminho(GoRouter r) =>
    r.routerDelegate.currentConfiguration.uri.toString();

void main() {
  testWidgets('mostra quem é o paciente', (tester) async {
    await _abrir(tester);

    expect(find.byType(PacienteDetalhePage), findsOneWidget);
    expect(find.text('Ana de Teste'), findsOneWidget);
    expect(find.text(AppStrings.perfilQueixa('rouquidão')), findsOneWidget);
    expect(
      find.text(AppStrings.perfilNascimento('02 jul 1985', 41)),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.perfilSexo(AppStrings.cadastroSexoFeminino)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.perfilSemPerfilDeReferencia), findsNothing);
  });

  testWidgets('sem sexo ou nascimento, avisa que não haverá classificação', (
    tester,
  ) async {
    await _abrir(
      tester,
      paciente: const Paciente(
        id: 'p1',
        nome: 'Ana de Teste',
        queixa: 'rouquidão',
        direcaoAvqi: DirecaoDaMedida.semComparacao,
      ),
    );

    expect(find.text(AppStrings.perfilNascimentoNaoInformado), findsOneWidget);
    expect(find.text(AppStrings.perfilSexoNaoInformado), findsOneWidget);
    expect(find.text(AppStrings.perfilSemPerfilDeReferencia), findsOneWidget);
  });

  testWidgets('paciente que não está no aparelho', (tester) async {
    await _abrir(
      tester,
      paciente: const Paciente(
        id: 'outro',
        nome: 'Outra',
        queixa: 'x',
        direcaoAvqi: DirecaoDaMedida.semComparacao,
      ),
    );

    expect(find.text(AppStrings.perfilNaoEncontrado), findsOneWidget);
    expect(find.text(AppStrings.perfilNovaGravacao), findsNothing);
  });

  group('consentimento', () {
    testWidgets('registrado: gravar é a ação principal', (tester) async {
      final roteador = await _abrir(tester);

      expect(find.text(AppStrings.consentimentoRegistrado), findsOneWidget);
      expect(find.text(AppStrings.perfilRegistrarConsentimento), findsNothing);

      await _tocar(tester, find.text(AppStrings.perfilNovaGravacao));
      expect(_caminho(roteador), '/pacientes/p1/captura');
    });

    testWidgets('não registrado: registrar primeiro; gravar diz por quê', (
      tester,
    ) async {
      await _abrir(tester, consentimento: false);

      expect(find.text(AppStrings.consentimentoNaoRegistrado), findsOneWidget);
      expect(_habilitado(tester, AppStrings.perfilNovaGravacao), isFalse);
      expect(find.text(AppStrings.perfilGravacaoBloqueada), findsOneWidget);

      await _tocar(tester, find.text(AppStrings.perfilRegistrarConsentimento));
      expect(find.byType(ConsentimentoPage), findsOneWidget);
    });
  });

  group('sessões', () {
    final sessoes = [
      _sessao('s1', DateTime(2026, 5, 28, 9, 40), avqi: 4.61),
      _sessao(
        's3',
        DateTime(2026, 7, 23, 10, 5),
        avqi: 3.12,
        amostraRuim: true,
      ),
      _sessao('s2', DateTime(2026, 6, 18, 10, 10), avqi: 3.58),
    ];

    testWidgets('da mais recente para a mais antiga, com AVQI e qualidade', (
      tester,
    ) async {
      await _abrir(tester, sessoes: sessoes);

      final datas = [
        for (final d in ['23 jul 2026', '18 jun 2026', '28 mai 2026'])
          tester.getTopLeft(find.textContaining(d)).dy,
      ];
      expect(datas, orderedEquals([...datas]..sort()));
      expect(find.text('AVQI 3,12'), findsOneWidget);
      expect(find.text(AppStrings.perfilAmostraComProblema), findsOneWidget);
      expect(find.text(AppStrings.perfilAmostrasAdequadas), findsNWidgets(2));
    });

    testWidgets('mostra qual já tem laudo', (tester) async {
      await _abrir(
        tester,
        sessoes: sessoes,
        laudos: [
          Laudo(
            analiseId: 's2',
            pacienteId: 'p1',
            conclusao: 'x',
            geradoEm: DateTime(2026, 6, 19),
            pdf: Uint8List(0),
          ),
        ],
      );

      expect(
        find.text(AppStrings.perfilLaudoGerado('19 jun 2026')),
        findsOneWidget,
      );
    });

    testWidgets('análise em curso e análise que falhou', (tester) async {
      await _abrir(
        tester,
        sessoes: [
          _sessao(
            'sp',
            DateTime(2026, 9, 22),
            situacao: SituacaoDaAnalise.processando,
          ),
          _sessao(
            'sf',
            DateTime(2026, 9, 21),
            situacao: SituacaoDaAnalise.falhou,
          ),
        ],
      );

      expect(find.text(AppStrings.perfilAnaliseProcessando), findsOneWidget);
      expect(find.text(AppStrings.perfilAnaliseFalhou), findsOneWidget);
      // Sem análise concluída, não há evolução para ver.
      expect(find.text(AppStrings.perfilVerEvolucao), findsNothing);
    });

    testWidgets('tocar numa sessão abre o resultado, e o voltar volta', (
      tester,
    ) async {
      await _abrir(tester, sessoes: sessoes);

      await _tocar(tester, find.textContaining('18 jun 2026'));
      final resultado = tester.widget<AnaliseResultadoPage>(
        find.byType(AnaliseResultadoPage),
      );
      expect(resultado.analiseId, 's2');

      await _tocar(tester, find.bySemanticsLabel(AppStrings.voltar).first);
      expect(find.byType(PacienteDetalhePage), findsOneWidget);
    });

    testWidgets('com sessão analisada, leva à evolução', (tester) async {
      await _abrir(tester, sessoes: sessoes);

      await _tocar(tester, find.text(AppStrings.perfilVerEvolucao));
      expect(find.byType(EvolucaoPage), findsOneWidget);
    });

    testWidgets('sem sessão: diz, e não oferece evolução', (tester) async {
      await _abrir(tester);

      expect(find.text(AppStrings.perfilSemSessoes), findsOneWidget);
      expect(find.text(AppStrings.perfilVerEvolucao), findsNothing);
    });

    testWidgets('gravações na fila aparecem, com atalho para ela', (
      tester,
    ) async {
      await _abrir(tester, naFila: 2);

      expect(find.text(AppStrings.perfilNaFila(2)), findsOneWidget);
      await _tocar(tester, find.text(AppStrings.perfilVerFila));
      expect(find.byType(FilaPage), findsOneWidget);
    });
  });

  testWidgets('a lista leva ao perfil', (tester) async {
    final roteador = await _abrir(tester);
    roteador.goNamed(AppRoutes.pacientesNome);
    await tester.pumpAndSettle();

    await _tocar(tester, find.text('Ana de Teste').first);

    expect(find.byType(PacienteDetalhePage), findsOneWidget);
  });

  group('layout', () {
    for (final (nome, tamanho) in [
      ('390', const Size(390, 844)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final escala in [1.0, 2.0]) {
        testWidgets('$nome, texto ${escala}x: sem estouro', (tester) async {
          await _abrir(
            tester,
            tamanho: tamanho,
            escala: escala,
            consentimento: false,
            naFila: 1,
            sessoes: [_sessao('s1', DateTime(2026, 7, 23, 10, 5), avqi: 3.12)],
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
