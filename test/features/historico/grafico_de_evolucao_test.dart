import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/historico/domain/serie_da_medida.dart';
import 'package:fonar_app/features/historico/presentation/widgets/grafico_de_evolucao.dart';
import 'package:fonar_app/l10n/app_strings.dart';

Future<void> _desenhar(
  WidgetTester tester,
  List<PontoDaSerie> pontos, {
  double largura = 390,
}) async {
  tester.view.physicalSize = Size(largura, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: GraficoDeEvolucao(
          medida: MedidaAcustica.avqi,
          pontos: pontos,
          altura: 240,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sessões próximas: a mais recente sempre tem data no eixo', (
    tester,
  ) async {
    // Doze sessões semanais em 390 px: não cabem doze datas.
    final pontos = [
      for (var i = 0; i < 12; i++)
        PontoDaSerie(
          analiseId: 's$i',
          realizadaEm: DateTime(2026, 5, 7).add(Duration(days: 7 * i)),
          valor: 3 + i / 10,
        ),
    ];
    await _desenhar(tester, pontos);

    expect(tester.takeException(), isNull);
    final ultima = AppStrings.dataCurta(pontos.last.realizadaEm);
    expect(find.text(ultima), findsOneWidget);

    final datas = [
      for (final p in pontos)
        if (find
            .text(AppStrings.dataCurta(p.realizadaEm))
            .evaluate()
            .isNotEmpty)
          p.realizadaEm,
    ];
    expect(datas.length, lessThan(12));
    expect(datas.length, greaterThan(1));
  });

  testWidgets('sessões em anos diferentes levam o ano na data', (tester) async {
    await _desenhar(tester, [
      PontoDaSerie(
        analiseId: 'a',
        realizadaEm: DateTime(2025, 11, 3),
        valor: 4,
      ),
      PontoDaSerie(analiseId: 'b', realizadaEm: DateTime(2026, 2, 9), valor: 3),
    ]);

    expect(
      find.text(AppStrings.dataCurta(DateTime(2026, 2, 9), comAno: true)),
      findsOneWidget,
    );
  });

  testWidgets('medida nunca calculada: texto em vez de gráfico vazio', (
    tester,
  ) async {
    await _desenhar(tester, [
      PontoDaSerie(
        analiseId: 'a',
        realizadaEm: DateTime(2026, 7, 2),
        valor: null,
      ),
    ]);

    expect(find.text(AppStrings.evolucaoNenhumValor), findsOneWidget);
  });
}
