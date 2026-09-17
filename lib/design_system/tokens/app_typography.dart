import 'package:flutter/material.dart';

/// Escala tipográfica — PLACEHOLDER.
///
/// TODO: definir a família tipográfica real e registrá-la no pubspec.
/// Por ora usamos a fonte padrão da plataforma com tamanhos explícitos.
///
/// Tamanhos foram escolhidos com folga: o usuário lê a tela de pé, de lado,
/// entre uma fala e outra do paciente. Nada abaixo de 14.
abstract final class AppTypography {
  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.25,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, height: 1.5),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: TextStyle(fontSize: 13, height: 1.4),
  );

  /// Valor numérico de medida acústica. Tabular para as casas decimais não
  /// dançarem quando o número muda.
  static const medida = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
