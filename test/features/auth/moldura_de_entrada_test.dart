import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/presentation/widgets/moldura_de_entrada.dart';

Future<void> _montar(
  WidgetTester tester, {
  required double largura,
  double escala = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: largura,
            child: const CamposLadoALado(
              primeiro: TextField(key: Key('senha')),
              segundo: TextField(key: Key('confirmacao')),
            ),
          ),
        ),
      ),
    ),
  );
}

bool _ladoALado(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const Key('senha'))).dy ==
    tester.getTopLeft(find.byKey(const Key('confirmacao'))).dy;

void main() {
  group('CamposLadoALado', () {
    testWidgets('formulário largo: lado a lado, na ordem', (tester) async {
      await _montar(tester, largura: 640);

      expect(_ladoALado(tester), isTrue);
      expect(
        tester.getTopLeft(find.byKey(const Key('senha'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const Key('confirmacao'))).dx),
      );
    });

    testWidgets('formulário estreito: um embaixo do outro', (tester) async {
      await _montar(tester, largura: 440);

      expect(_ladoALado(tester), isFalse);
    });

    testWidgets('texto em 200%: um embaixo do outro, mesmo largo', (
      tester,
    ) async {
      await _montar(tester, largura: 640, escala: 2);

      expect(_ladoALado(tester), isFalse);
    });
  });

  test('a largura do formulário acompanha a janela, de 440 a 640', () {
    // 1024 px de janela: 464 à direita da marca.
    expect(larguraDoFormulario(464), 440);
    // 1440: 880.
    expect(larguraDoFormulario(880), closeTo(484, 0.01));
    // Full HD: 1360.
    expect(larguraDoFormulario(1360), 640);
  });
}
