import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/laudo/presentation/laudo_controlador.dart';
import 'package:fonar_app/features/laudo/presentation/widgets/previa_do_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// O canal nativo do `printing`. No teste não há rasterizador: o canal diz
/// só que não rasteriza, e a prévia mostra o aviso dela no lugar da folha.
const _canal = MethodChannel('net.nfet.printing');

// PNG de 1×1 transparente: uma página que o `Image` consegue decodificar.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

Widget _tela(Widget filho) => MaterialApp(
  theme: AppTheme.claro,
  home: Scaffold(body: filho),
);

void main() {
  group('MemoDaPrevia', () {
    test('a mesma função de gerar dá o mesmo callback', () {
      final memo = MemoDaPrevia();
      Future<Uint8List> gerar() async => Uint8List(0);

      expect(memo.para(gerar), same(memo.para(gerar)));
    });

    test('função nova dá callback novo, que gera com ela', () async {
      final memo = MemoDaPrevia();
      final antes = memo.para(() async => Uint8List.fromList([1]));
      final depois = memo.para(() async => Uint8List.fromList([2]));

      expect(depois, isNot(same(antes)));
      expect(await depois(PdfPageFormat.a4), [2]);
    });
  });

  group('PreviaDoPdf', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _canal,
            (chamada) async => chamada.method == 'printingInfo'
                ? <String, Object>{'canRaster': false}
                : null,
          );
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_canal, null);
    });

    LayoutCallback entregue(WidgetTester tester) =>
        tester.widget<PdfPreview>(find.byType(PdfPreview)).build;

    testWidgets(
      'a tela reconstruída com a mesma função não rasteriza de novo',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // A prévia de verdade, a que a tela do laudo usa.
        final previa = container.read(previaDoPdfProvider);
        Future<Uint8List> gerar() async => Uint8List(0);

        await tester.pumpWidget(_tela(previa(gerar)));
        final primeira = entregue(tester);

        // Outro widget, a mesma função: é o que a tela do laudo faz a cada
        // reconstrução — um foco, um hover, o respiro da digitação.
        await tester.pumpWidget(_tela(previa(gerar)));
        expect(entregue(tester), same(primeira));

        // O documento mudou: aí sim, função nova.
        await tester.pumpWidget(_tela(previa(() async => Uint8List(1))));
        expect(entregue(tester), isNot(same(primeira)));

        // A rasterização do `printing` espera um instante antes de começar.
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('a folha mantém a imagem anterior até a nova ficar pronta', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tela(PreviaDoPdf(gerar: () async => Uint8List(0))),
      );
      final paginas = tester
          .widget<PdfPreviewCustom>(find.byType(PdfPreviewCustom))
          .pagesBuilder!;
      await tester.pump(const Duration(seconds: 1));

      final pagina = PdfPreviewPageData(
        image: MemoryImage(_png),
        width: 595,
        height: 842,
      );
      await tester.pumpWidget(
        _tela(Builder(builder: (context) => paginas(context, [pagina]))),
      );

      final imagem = tester.widget<Image>(find.byType(Image));
      expect(imagem.image, same(pagina.image));
      // Sem isso, cada rasterização deixava a folha em branco entre uma
      // imagem e a seguinte: era o piscar.
      expect(imagem.gaplessPlayback, isTrue);
    });
  });
}
