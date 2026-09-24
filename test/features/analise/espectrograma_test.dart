import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/analise/data/imagem_do_servidor.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/analise/presentation/pages/analise_resultado_page.dart';
import 'package:fonar_app/features/analise/presentation/pages/espectrograma_page.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../apoio/banco_em_memoria.dart';

/// PNG de 1×1: a imagem de teste no lugar da que viria do servidor.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

class _Analises implements RepositorioAnalises {
  _Analises({this.url});
  final String? url;

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async =>
      ResultadoDaAnalise(
        id: analiseId,
        pacienteId: 'p1',
        situacao: SituacaoDaAnalise.concluida,
        realizadaEm: DateTime(2026, 9, 23, 9, 30),
        medidas: const [
          MedidaCalculada(medida: MedidaAcustica.avqi, valor: 3.12),
        ],
        espectrogramaUrl: url,
      );

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async =>
      const [];
}

Future<GoRouter> _abrir(
  WidgetTester tester, {
  String? url = 'https://servidor/an-1/espectrograma.png',
  String rota = AppRoutes.analiseResultadoNome,
  String paciente = 'p1',
  Size tamanho = const Size(390, 844),
  double escala = 1,
  List<String>? pedidas,
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
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(false),
      repositorioAnalisesProvider.overrideWithValue(_Analises(url: url)),
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
      imagemDoServidorProvider.overrideWithValue((url) {
        pedidas?.add(url);
        return MemoryImage(_png);
      }),
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
    rota,
    pathParameters: {
      AppRoutes.paramPacienteId: paciente,
      AppRoutes.paramAnaliseId: 'an-1',
    },
  );
  await tester.pumpAndSettle();
  return roteador;
}

String _caminho(GoRouter r) =>
    r.routerDelegate.currentConfiguration.uri.toString();

Future<void> _tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto);
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

double _escala(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

bool _habilitado(WidgetTester tester, String rotulo) {
  final botao = find.ancestor(
    of: find.text(rotulo),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(botao.first).onPressed != null;
}

void main() {
  testWidgets('do resultado, "Ver em tela cheia" abre o espectrograma, e '
      'voltar traz de volta', (tester) async {
    final pedidas = <String>[];
    final r = await _abrir(tester, pedidas: pedidas);

    await _tocar(tester, AppStrings.resultadoEspectrogramaTelaCheia);

    // `push`: a tela cheia vem por cima do resultado.
    expect(find.byType(EspectrogramaPage), findsOneWidget);
    // A mesma imagem do servidor, e só ela.
    expect(pedidas.toSet(), {'https://servidor/an-1/espectrograma.png'});
    expect(
      find.bySemanticsLabel(AppStrings.resultadoEspectrogramaDescricao),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(AppStrings.voltar).first);
    await tester.pumpAndSettle();
    expect(find.byType(EspectrogramaPage), findsNothing);
    expect(find.byType(AnaliseResultadoPage), findsOneWidget);
    expect(_caminho(r), '/pacientes/p1/analise/an-1');
  });

  testWidgets('sem imagem do servidor, não há o que abrir', (tester) async {
    await _abrir(tester, url: null);

    expect(
      find.text(AppStrings.resultadoEspectrogramaIndisponivel),
      findsOneWidget,
    );
    expect(find.text(AppStrings.resultadoEspectrogramaTelaCheia), findsNothing);
  });

  testWidgets('sem imagem, nem pelo endereço direto', (tester) async {
    await _abrir(tester, url: null, rota: AppRoutes.espectrogramaNome);

    expect(
      find.text(AppStrings.resultadoEspectrogramaIndisponivel),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('análise de outro paciente não é mostrada', (tester) async {
    await _abrir(tester, rota: AppRoutes.espectrogramaNome, paciente: 'p2');

    expect(find.text(AppStrings.resultadoDeOutroPaciente), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('no celular em pé, sugere girar', (tester) async {
    await _abrir(tester, rota: AppRoutes.espectrogramaNome);

    expect(find.text(AppStrings.espectrogramaGireAparelho), findsOneWidget);
  });

  testWidgets('deitado, a imagem fica com quase toda a altura', (tester) async {
    await _abrir(
      tester,
      rota: AppRoutes.espectrogramaNome,
      tamanho: const Size(844, 390),
    );

    expect(find.text(AppStrings.espectrogramaGireAparelho), findsNothing);
    expect(
      tester.getSize(find.byType(InteractiveViewer)).height,
      greaterThan(390 * 0.5),
    );
  });

  testWidgets('botões aproximam e ajustam — sem precisar de gesto', (
    tester,
  ) async {
    await _abrir(tester, rota: AppRoutes.espectrogramaNome);
    expect(_escala(tester), 1);
    // Já no tamanho da tela: não há o que ajustar, e diz por quê.
    expect(_habilitado(tester, AppStrings.espectrogramaAjustar), isFalse);
    expect(find.text(AppStrings.espectrogramaNoTamanhoDaTela), findsOneWidget);

    await _tocar(tester, AppStrings.espectrogramaAproximar);
    await _tocar(tester, AppStrings.espectrogramaAproximar);
    expect(_escala(tester), closeTo(2.25, 0.001));
    expect(_habilitado(tester, AppStrings.espectrogramaAjustar), isTrue);

    await _tocar(tester, AppStrings.espectrogramaAjustar);
    expect(_escala(tester), 1);
    expect(_habilitado(tester, AppStrings.espectrogramaAjustar), isFalse);
  });

  testWidgets('com a imagem em foco, o teclado aproxima, percorre e ajusta', (
    tester,
  ) async {
    await _abrir(
      tester,
      rota: AppRoutes.espectrogramaNome,
      tamanho: const Size(1440, 900),
    );
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(_escala(tester), closeTo(1.5, 0.001));

    Offset deslocamento() {
      final t = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getTranslation();
      return Offset(t.x, t.y);
    }

    final antes = deslocamento();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(deslocamento().dx, lessThan(antes.dx));

    // Não passa da borda: muitas setas param no canto.
    for (var i = 0; i < 30; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    }
    await tester.pump();
    expect(deslocamento().dx, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(_escala(tester), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.pump();
    expect(_escala(tester), 1);
    expect(deslocamento(), Offset.zero);
  });

  testWidgets('aproximar tem limite', (tester) async {
    await _abrir(tester, rota: AppRoutes.espectrogramaNome);

    for (var i = 0; i < 10; i++) {
      if (!_habilitado(tester, AppStrings.espectrogramaAproximar)) break;
      await _tocar(tester, AppStrings.espectrogramaAproximar);
    }

    expect(_escala(tester), closeTo(6, 0.001));
    expect(_habilitado(tester, AppStrings.espectrogramaAproximar), isFalse);
    expect(find.text(AppStrings.espectrogramaNoMaximo), findsOneWidget);
  });

  for (final (nome, tamanho) in [
    ('celular em pé', const Size(390, 844)),
    ('celular deitado', const Size(844, 390)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome em 200% não estoura', (tester) async {
      await _abrir(
        tester,
        rota: AppRoutes.espectrogramaNome,
        tamanho: tamanho,
        escala: 2,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
