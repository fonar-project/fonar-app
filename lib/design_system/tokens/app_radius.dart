import 'package:flutter/widgets.dart';

/// Raios de borda.
///
/// O aplicativo é mais reto que a landing page: controles (botão, campo) usam
/// [pequeno], e só superfícies de agrupamento (card, aviso) arredondam com
/// [medio]. A landing usa 10–12 px em botão; o protótipo do app usa 4 px, e
/// quem manda aqui é o protótipo do app.
abstract final class AppRadius {
  static const nenhum = Radius.zero;

  /// Botões e campos.
  static const pequeno = Radius.circular(4);

  /// Cards e avisos.
  static const medio = Radius.circular(12);
  static const grande = Radius.circular(20);

  /// Selos em forma de pílula, como o indicador de conexão.
  static const pilula = Radius.circular(999);

  static const bordaPequena = BorderRadius.all(pequeno);
  static const bordaMedia = BorderRadius.all(medio);
  static const bordaGrande = BorderRadius.all(grande);
  static const bordaPilula = BorderRadius.all(pilula);
}
