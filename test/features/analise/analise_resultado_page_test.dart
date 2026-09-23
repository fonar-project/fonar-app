import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_status_medida.dart';
import 'package:fonar_app/features/analise/data/catalogo_de_referencias_vazio.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/faixa_de_referencia.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/analise/presentation/pages/analise_resultado_page.dart';
import 'package:fonar_app/features/cape_v/data/repositorio_cape_v_em_memoria.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_placeholder.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

class _Repositorio implements RepositorioAnalises {
  _Repositorio(this.resposta);
  final Future<ResultadoDaAnalise> Function() resposta;
  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) => resposta();
  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async =>
      const [];
}

/// Catálogo de TESTE, com números sem referência nenhuma: uma faixa por
/// medida, escolhida para cada caso cair onde o teste quer.
class _Catalogo implements CatalogoDeReferencias {
  @override
  FaixaDeReferencia? faixa(MedidaAcustica medida, PerfilDeReferencia perfil) =>
      switch (medida) {
        MedidaAcustica.f0 => const FaixaDeReferencia(
          minimo: 100,
          maximo: 300,
          procedencia: 'Fonte de teste A',
        ),
        MedidaAcustica.avqi => const FaixaDeReferencia(
          maximo: 2,
          procedencia: 'Fonte de teste B',
        ),
        MedidaAcustica.cpps => const FaixaDeReferencia(
          minimo: 10,
          margemLimitrofe: 5,
          procedencia: 'Fonte de teste C',
        ),
        _ => null,
      };
}

final _concluida = ResultadoDaAnalise(
  id: 'an-1',
  pacienteId: 'p1',
  situacao: SituacaoDaAnalise.concluida,
  realizadaEm: DateTime(2026, 7, 2, 9, 30),
  medidas: const [
    MedidaCalculada(medida: MedidaAcustica.avqi, valor: 3.12),
    MedidaCalculada(medida: MedidaAcustica.cpps, valor: 12.4),
    MedidaCalculada(medida: MedidaAcustica.jitter, valor: null),
    MedidaCalculada(medida: MedidaAcustica.f0, valor: 212),
  ],
  qualidade: const {
    TarefaDeGravacao.vogalSustentada: QualidadeDaAmostra(adequada: true),
    TarefaDeGravacao.falaEncadeada: QualidadeDaAmostra(
      adequada: false,
      motivo: 'Trecho com ruído de fundo (teste).',
    ),
  },
);

Paciente _paciente({SexoDeReferencia? sexo, DateTime? nascimento}) => Paciente(
  id: 'p1',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
  sexo: sexo,
  dataDeNascimento: nascimento,
);

Future<void> _abrir(
  WidgetTester tester, {
  Future<ResultadoDaAnalise> Function()? resposta,
  Paciente? paciente,
  CatalogoDeReferencias? catalogo,
  AvaliacaoCapeV? capeV,
  Size tamanho = const Size(1440, 2000),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final capeVs = RepositorioCapeVEmMemoria();
  if (capeV != null) await capeVs.registrar(capeV);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        repositorioCapeVProvider.overrideWithValue(capeVs),
        repositorioAnalisesProvider.overrideWithValue(
          _Repositorio(resposta ?? () async => _concluida),
        ),
        if (catalogo != null)
          catalogoDeReferenciasProvider.overrideWithValue(catalogo),
        pacientesProvider.overrideWith(
          (ref) async => [paciente ?? _paciente()],
        ),
        conexaoOnlineProvider.overrideWithValue(true),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const AnaliseResultadoPage(pacienteId: 'p1', analiseId: 'an-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<StatusMedida> _status(WidgetTester tester) => [
  for (final w in tester.widgetList<AppStatusMedida>(
    find.byType(AppStatusMedida),
  ))
    w.status,
];

void main() {
  testWidgets('catálogo do app: toda medida aparece, nenhuma classificada', (
    tester,
  ) async {
    await _abrir(
      tester,
      paciente: _paciente(
        sexo: SexoDeReferencia.feminino,
        nascimento: DateTime(1985, 7, 2),
      ),
    );

    expect(find.text('3,12'), findsOneWidget);
    expect(find.text('12,4'), findsOneWidget);
    expect(find.text('212'), findsOneWidget);
    expect(_status(tester), everyElement(StatusMedida.semReferencia));
    // O motivo é o mesmo para todas: dito uma vez, acima das medidas, e não
    // repetido em cada cartão.
    expect(find.text(AppStrings.resultadoSemFaixaValidada), findsOneWidget);
  });

  testWidgets('perfil sem sexo: diz que falta o perfil, não a faixa', (
    tester,
  ) async {
    await _abrir(
      tester,
      catalogo: _Catalogo(),
      paciente: _paciente(sexo: SexoDeReferencia.naoInformado),
    );

    expect(_status(tester), everyElement(StatusMedida.semReferencia));
    expect(find.text(AppStrings.resultadoPerfilIncompleto), findsOneWidget);
    // A medida não calculada tem motivo próprio, e o mantém no cartão.
    expect(find.text(AppStrings.resultadoNaoCalculadaTexto), findsOneWidget);
  });

  testWidgets('com faixa: classifica e mostra a faixa e a fonte', (
    tester,
  ) async {
    await _abrir(
      tester,
      catalogo: _Catalogo(),
      paciente: _paciente(
        sexo: SexoDeReferencia.feminino,
        nascimento: DateTime(1985, 7, 2),
      ),
    );

    // Na ordem das medidas: AVQI fora (> 2), CPPS limítrofe (12,4 a menos de
    // 5 do mínimo 10), jitter não calculado, f0 dentro.
    expect(_status(tester), [
      StatusMedida.foraDaFaixa,
      StatusMedida.limitrofe,
      StatusMedida.semReferencia,
      StatusMedida.dentroDaFaixa,
    ]);
    expect(find.text(AppStrings.resultadoFaixa('100–300 Hz')), findsOneWidget);
    expect(find.text(AppStrings.resultadoFaixa('até 2,00')), findsOneWidget);
    expect(
      find.text(AppStrings.resultadoFaixa('a partir de 10,0 dB')),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.resultadoProcedencia('Fonte de teste A')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.resultadoNaoCalculada), findsOneWidget);
    expect(find.text(AppStrings.resultadoNaoCalculadaTexto), findsOneWidget);
  });

  testWidgets('qualidade das amostras, com o motivo do problema', (
    tester,
  ) async {
    await _abrir(tester);

    expect(
      find.text(
        AppStrings.resultadoAmostraAdequada(AppStrings.tarefaVogalTitulo),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        AppStrings.resultadoAmostraComProblema(AppStrings.tarefaFalaTitulo),
      ),
      findsOneWidget,
    );
    expect(find.text('Trecho com ruído de fundo (teste).'), findsOneWidget);
  });

  testWidgets('apoio à decisão aparece antes das medidas', (tester) async {
    await _abrir(tester);

    final aviso = tester.getTopLeft(find.text(AppStrings.avisoApoioDecisao));
    final medidas = tester.getTopLeft(
      find.text(AppStrings.resultadoMedidasTitulo),
    );
    expect(aviso.dy, lessThan(medidas.dy));
  });

  testWidgets('dado de exemplo é avisado como exemplo', (tester) async {
    await _abrir(
      tester,
      resposta: () => const RepositorioAnalisesPlaceholder().buscar('x'),
    );

    expect(find.text(AppStrings.resultadoExemploTitulo), findsOneWidget);
  });

  testWidgets('sem espectrograma, diz que não há imagem', (tester) async {
    await _abrir(tester);

    expect(
      find.text(AppStrings.resultadoEspectrogramaIndisponivel),
      findsOneWidget,
    );
  });

  testWidgets('em processamento: explica e deixa atualizar', (tester) async {
    await _abrir(
      tester,
      resposta: () async => const ResultadoDaAnalise(
        id: 'an-1',
        pacienteId: 'p1',
        situacao: SituacaoDaAnalise.processando,
      ),
    );

    expect(find.text(AppStrings.resultadoProcessandoTitulo), findsOneWidget);
    expect(find.text(AppStrings.resultadoAtualizar), findsOneWidget);
    expect(find.byType(AppStatusMedida), findsNothing);
  });

  testWidgets('falha ao carregar: diz e deixa tentar de novo', (tester) async {
    await _abrir(tester, resposta: () => Future.error(const FalhaDeConexao()));

    expect(find.text(AppStrings.resultadoErroCarregar), findsOneWidget);
    expect(find.text(AppStrings.tentarNovamente), findsOneWidget);
  });

  testWidgets('sem CAPE-V: diz que não há e oferece registrar', (tester) async {
    await _abrir(tester);

    expect(find.text(AppStrings.capeVSecaoTitulo), findsOneWidget);
    expect(find.text(AppStrings.capeVAindaNao), findsOneWidget);
    expect(find.text(AppStrings.capeVRegistrar), findsOneWidget);
  });

  testWidgets('com CAPE-V: resume o que foi marcado', (tester) async {
    await _abrir(
      tester,
      capeV: AvaliacaoCapeV(
        analiseId: 'an-1',
        pacienteId: 'p1',
        registradaEm: DateTime(2026, 9, 23, 11, 15),
        comentarios: 'Comentário (teste).',
        notas: {
          for (final p in ParametroCapeV.values) p: const NotaCapeV(valor: 0),
          ParametroCapeV.pitch: const NotaCapeV(
            valor: 37,
            consistencia: Consistencia.consistente,
            direcao: DirecaoDoDesvio.abaixo,
          ),
        },
      ),
    );

    expect(
      find.text(AppStrings.capeVRegistradaEm('23 set 2026', '11:15')),
      findsOneWidget,
    );
    expect(
      find.text('${AppStrings.capeVPitch}: 37 · consistente · mais grave'),
      findsOneWidget,
    );
    expect(find.text('${AppStrings.capeVGrauGeral}: 0'), findsOneWidget);
    expect(find.text('Comentário (teste).'), findsOneWidget);
    expect(find.text(AppStrings.capeVEditar), findsOneWidget);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome não estoura com o texto do sistema em 200%', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamanho: tamanho,
        escala: 2,
        catalogo: _Catalogo(),
        paciente: _paciente(
          sexo: SexoDeReferencia.feminino,
          nascimento: DateTime(1985, 7, 2),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
