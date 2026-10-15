import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/escala_da_interface.dart';

/// O que a interface vê por dentro: a largura, a altura e a densidade.
Widget _sonda(void Function(MediaQueryData) ver) => Builder(
  builder: (context) {
    ver(MediaQuery.of(context));
    return const SizedBox.expand();
  },
);

Future<void> _montar(
  WidgetTester tester, {
  required Size janela,
  required TamanhoDaInterface tamanho,
  required Widget filho,
}) async {
  tester.view.physicalSize = janela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, conteudo) =>
          EscalaDaInterface(tamanho: tamanho, child: conteudo!),
      home: Scaffold(body: filho),
    ),
  );
}

void main() {
  group('fatorDaInterface', () {
    double fator(
      TamanhoDaInterface t,
      double largura, [
      double altura = 1080,
    ]) => fatorDaInterface(t, largura: largura, altura: altura);

    test('automático: pela largura da janela', () {
      expect(fator(TamanhoDaInterface.automatico, 1920), 1.2);
      expect(fator(TamanhoDaInterface.automatico, 1600), 1.2);
      expect(fator(TamanhoDaInterface.automatico, 1440), 1.1);
      expect(fator(TamanhoDaInterface.automatico, 1280), 1.1);
      expect(fator(TamanhoDaInterface.automatico, 1100), 1.0);
    });

    test('a escolha da Conta vale onde cabe', () {
      expect(fator(TamanhoDaInterface.cem, 1920), 1.0);
      expect(fator(TamanhoDaInterface.centoEQuinze, 1920), 1.15);
      expect(fator(TamanhoDaInterface.centoETrinta, 1920), 1.3);
    });

    test('o celular e a janela estreita ficam idênticos', () {
      for (final t in TamanhoDaInterface.values) {
        expect(fator(t, 390, 844), 1.0, reason: t.name);
        expect(fator(t, 1000, 800), 1.0, reason: t.name);
      }
    });

    test('nunca empurra a janela para fora do desktop, nem a deixa baixa', () {
      // 1280 / 1,3 daria 985 px: a tela cairia para a faixa média.
      final largo = fator(TamanhoDaInterface.centoETrinta, 1280, 1000);
      expect(1280 / largo, greaterThanOrEqualTo(1024));
      // Notebook 1366×768: 768 / 1,1 daria 698 px de altura.
      final baixo = fator(TamanhoDaInterface.automatico, 1366, 768);
      expect(768 / baixo, greaterThanOrEqualTo(EscalaDaInterface.alturaMinima));
    });
  });

  group('EscalaDaInterface', () {
    testWidgets('Full HD: o app vê uma janela menor e mais densa', (
      tester,
    ) async {
      late MediaQueryData visto;
      await _montar(
        tester,
        janela: const Size(1920, 1080),
        tamanho: TamanhoDaInterface.automatico,
        filho: _sonda((mq) => visto = mq),
      );

      expect(visto.size.width, closeTo(1600, 0.01));
      expect(visto.size.height, closeTo(900, 0.01));
      expect(visto.devicePixelRatio, closeTo(1.2, 0.001));
    });

    testWidgets('o toque segue a escala', (tester) async {
      var tocou = 0;
      await _montar(
        tester,
        janela: const Size(1920, 1080),
        tamanho: TamanhoDaInterface.automatico,
        filho: Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () => tocou++,
            child: const Text('no canto'),
          ),
        ),
      );

      // Desenhado 1,2 vez maior, e ainda dentro da janela.
      final canto = tester.getBottomRight(find.byType(TextButton));
      expect(canto.dx, closeTo(1920, 0.5));
      await tester.tap(find.text('no canto'));
      expect(tocou, 1);
    });

    testWidgets('celular: nada muda', (tester) async {
      late MediaQueryData visto;
      await _montar(
        tester,
        janela: const Size(390, 844),
        tamanho: TamanhoDaInterface.centoETrinta,
        filho: _sonda((mq) => visto = mq),
      );

      expect(visto.size, const Size(390, 844));
      expect(visto.devicePixelRatio, 1);
      expect(find.byType(OverflowBox), findsNothing);
    });
  });
}
