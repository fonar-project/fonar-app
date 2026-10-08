import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_area_com_acoes.dart';

/// Monta uma área com conteúdo alto e uma faixa de ações, numa tela de
/// [tamanho], e devolve onde a faixa ficou.
Future<Rect> _acoes(
  WidgetTester tester,
  Size tamanho, {
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: AppAreaComAcoes(
          topo: const SizedBox(height: 40, child: Text('topo')),
          corpo: const SizedBox(height: 2000, child: Text('corpo')),
          acoes: SizedBox(
            height: 80,
            child: TextButton(onPressed: () {}, child: const Text('Agir')),
          ),
        ),
      ),
    ),
  );
  expect(tester.takeException(), isNull);
  return tester.getRect(
    find.ancestor(of: find.text('Agir'), matching: find.byType(SizedBox)),
  );
}

void main() {
  testWidgets('celular em pé: as ações ficam presas no rodapé', (tester) async {
    final acoes = await _acoes(tester, const Size(390, 844));
    expect(acoes.bottom, 844);
  });

  testWidgets('celular deitado: as ações rolam junto, sem estourar', (
    tester,
  ) async {
    final acoes = await _acoes(tester, const Size(844, 390));
    // Abaixo do conteúdo de 2000 pontos: fora da tela até rolar.
    expect(acoes.top, greaterThan(390));
  });

  testWidgets('texto em 200% conta: a mesma tela em pé passa a rolar', (
    tester,
  ) async {
    // 844 de altura não alcança 520 × 2: a faixa, que cresce com o texto,
    // deixaria pouco para o conteúdo.
    final acoes = await _acoes(tester, const Size(390, 844), escala: 2);
    expect(acoes.top, greaterThan(844));
  });
}
