import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/formatacao/mascara_de_data.dart';

String _digitar(String texto, {String antes = ''}) => const MascaraDeData()
    .formatEditUpdate(
      TextEditingValue(text: antes),
      TextEditingValue(text: texto),
    )
    .text;

void main() {
  test('põe as barras conforme os dígitos chegam', () {
    expect(_digitar('0'), '0');
    expect(_digitar('02'), '02');
    expect(_digitar('020'), '02/0');
    expect(_digitar('0207'), '02/07');
    expect(_digitar('02071'), '02/07/1');
    expect(_digitar('02071985'), '02/07/1985');
  });

  test('para em oito dígitos', () {
    expect(_digitar('020719851'), '02/07/1985');
  });

  test('descarta o que não é dígito, inclusive colado', () {
    expect(_digitar('02.07.1985'), '02/07/1985');
    expect(_digitar('ab'), '');
  });

  test('apagar o último dígito tira a barra que ficaria sobrando', () {
    expect(_digitar('02/0', antes: '02/07'), '02/0');
    expect(_digitar('02/', antes: '02/0'), '02');
  });

  test('o cursor fica no fim', () {
    final valor = const MascaraDeData().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '0207'),
    );
    expect(valor.selection, const TextSelection.collapsed(offset: 5));
  });
}
