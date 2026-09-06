import 'package:flutter/widgets.dart';

/// Raios de borda. TODO: revisar junto da identidade visual.
abstract final class AppRadius {
  static const nenhum = Radius.zero;
  static const pequeno = Radius.circular(4);
  static const medio = Radius.circular(12);
  static const grande = Radius.circular(20);

  static const bordaPequena = BorderRadius.all(pequeno);
  static const bordaMedia = BorderRadius.all(medio);
  static const bordaGrande = BorderRadius.all(grande);
}
