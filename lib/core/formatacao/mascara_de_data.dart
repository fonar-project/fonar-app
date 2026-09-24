import 'package:flutter/services.dart';

/// Põe as barras de "dd/mm/aaaa" enquanto se digita.
///
/// O profissional digita só os oito números, no teclado numérico do celular
/// ou no teclado do desktop, e a data sai formatada. Qualquer outro caractere
/// é descartado, então colar "02.07.1985" também funciona.
///
/// O cursor vai sempre para o fim. Corrigir um dígito no meio exige apagar
/// até ele — aceitável num campo de oito dígitos, e bem mais simples do que
/// recalcular a posição do cursor em volta das barras inseridas.
class MascaraDeData extends TextInputFormatter {
  const MascaraDeData();

  static const _digitos = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    var digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > _digitos) digitos = digitos.substring(0, _digitos);

    final texto = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 2 || i == 4) texto.write('/');
      texto.write(digitos[i]);
    }
    final formatado = texto.toString();

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
