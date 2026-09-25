import 'package:flutter/material.dart';

/// Escala tipográfica do FONAR.
///
/// Família única: **Urbanist**. A regra da marca é hierarquia por PESO e
/// espaçamento, nunca por cor — o que também é o que mantém a interface legível
/// para quem não distingue bem matiz.
///
/// - **700–800** para títulos, dados e métricas acústicas
/// - **600** para rótulos de campo e de botão
/// - **400** para instruções e corpo de texto
///
/// Tamanhos têm folga de propósito: o profissional lê a tela de pé, de lado,
/// entre uma fala e outra do paciente. **Nada abaixo de 14.**
///
/// Isso diverge do design system da landing page, que desce a 12–13 px em
/// legenda e overline. É divergência deliberada, não esquecimento: a landing é
/// lida sentado, com tempo; esta tela é lida em consultório. Onde os dois
/// documentos brigam sobre legibilidade, o aplicativo é mais conservador.
abstract final class AppTypography {
  /// Nome da família declarada no `pubspec.yaml`.
  static const familia = 'Urbanist';

  static const textTheme = TextTheme(
    // Título de tela grande, só no desktop.
    displaySmall: TextStyle(
      fontSize: 40,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),

    // Título de seção.
    headlineMedium: TextStyle(
      fontSize: 30,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),

    // Título de card e de bloco.
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.35,
      fontWeight: FontWeight.w700,
    ),

    // Corpo. `bodyLarge` é a instrução principal; `bodyMedium` é o apoio.
    bodyLarge: TextStyle(
      fontSize: 17,
      height: 1.55,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      height: 1.55,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),

    // Rótulo de botão e de campo.
    labelLarge: TextStyle(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    labelSmall: TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
  );

  /// Valor numérico de medida acústica — o dado que o profissional veio ler.
  ///
  /// Tabular para as casas decimais não dançarem quando o número muda: um
  /// valor que se desloca entre atualizações é lido como valor diferente.
  static const medida = TextStyle(
    fontFamily: familia,
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// As medidas principais do resultado (AVQI e CPPS), em destaque.
  static const medidaDestaque = TextStyle(
    fontFamily: familia,
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Mesma medida, em linha de tabela ou card compacto.
  static const medidaCompacta = TextStyle(
    fontFamily: familia,
    fontSize: 20,
    height: 1.1,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Rótulo de seção em caixa alta.
  static const overline = TextStyle(
    fontFamily: familia,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );
}
