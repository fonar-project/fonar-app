import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Põe o ponteiro do mouse sobre [alvo] e deixa a tela assentar.
///
/// Existe porque contraste em repouso não é o contraste que o profissional lê:
/// no Windows ele usa mouse, e o véu de hover do `AppToque` escurece o fundo
/// justamente da linha que ele está olhando. Ver `AppToque` e
/// `app_colors_test.dart`.
Future<void> passarOMouse(WidgetTester tester, Finder alvo) async {
  final rato = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await rato.addPointer(location: Offset.zero);
  addTearDown(rato.removePointer);
  await rato.moveTo(tester.getCenter(alvo));
  await tester.pumpAndSettle();
}

/// A cor declarada no `style` do `Text` que mostra [texto].
Color? corDoTexto(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto).first).style?.color;
