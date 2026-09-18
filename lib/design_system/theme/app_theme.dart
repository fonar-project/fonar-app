import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_movimento.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Tema montado a partir dos tokens.
///
/// O `ColorScheme` é escrito à mão, não derivado por `ColorScheme.fromSeed`.
/// A semente gera uma família de tons harmônicos que **não é** a paleta da
/// marca: o roxo sai lavado, o creme vira quase branco. Como a paleta do FONAR
/// é fechada e pequena, declarar os papéis explicitamente custa menos que
/// corrigir tom por tom depois.
abstract final class AppTheme {
  static ThemeData get claro => _montar(_esquemaClaro);

  /// TEMA ESCURO NÃO ESPECIFICADO.
  ///
  /// A identidade do FONAR só define a paleta clara — creme, roxo, chumbo,
  /// lavanda. Não existe variante escura desenhada, e inverter a paleta na mão
  /// produziria contraste que ninguém validou, em um aplicativo onde cor
  /// comunica status de medida clínica.
  ///
  /// Até haver desenho, o modo escuro devolve o tema claro. É melhor ignorar a
  /// preferência do sistema do que exibir status verde/amarelo/vermelho com
  /// contraste não verificado.
  static ThemeData get escuro => claro;

  static const _esquemaClaro = ColorScheme(
    brightness: Brightness.light,

    // Primária — botões, cabeçalho, links.
    primary: AppColors.roxoProfundo,
    onPrimary: AppColors.creme,
    primaryContainer: AppColors.lavandaClaro,
    onPrimaryContainer: AppColors.roxoProfundo,

    // Secundária — faixas e cards de apoio.
    secondary: AppColors.lavandaClaro,
    onSecondary: AppColors.cinzaChumbo,
    secondaryContainer: AppColors.lavandaClaro,
    onSecondaryContainer: AppColors.secundarioSobreLavanda,

    tertiary: AppColors.roxoHover,
    onTertiary: AppColors.creme,

    // Fundo do aplicativo e superfície de card.
    surface: AppColors.creme,
    onSurface: AppColors.cinzaChumbo,
    surfaceContainerLowest: AppColors.branco,
    surfaceContainerLow: AppColors.branco,
    surfaceContainer: AppColors.lavandaClaro,
    onSurfaceVariant: AppColors.secundarioSobreCreme,

    outline: AppColors.lavandaClaro,
    outlineVariant: AppColors.lavandaClaro,

    error: AppColors.erro,
    onError: AppColors.branco,
    errorContainer: AppColors.creme,
    onErrorContainer: AppColors.erro,
  );

  static ThemeData _montar(ColorScheme esquema) {
    return ThemeData(
      colorScheme: esquema,
      fontFamily: AppTypography.familia,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: esquema.onSurface,
        displayColor: esquema.onSurface,
      ),
      scaffoldBackgroundColor: esquema.surface,
      visualDensity: VisualDensity.standard,

      // Sem tinta de elevação: as superfícies do FONAR são chapadas, separadas
      // por borda lavanda, não por sombra.
      cardTheme: CardThemeData(
        color: esquema.surfaceContainerLowest,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.bordaMedia,
          side: BorderSide(color: AppColors.lavandaClaro),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lavandaClaro,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerLowest,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.bordaMedia,
          borderSide: BorderSide(color: AppColors.lavandaClaro),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.bordaMedia,
          borderSide: BorderSide(color: AppColors.lavandaClaro),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.bordaMedia,
          borderSide: BorderSide(color: AppColors.roxoProfundo, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.bordaMedia,
          borderSide: BorderSide(color: AppColors.erro, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.bordaMedia,
          borderSide: BorderSide(color: AppColors.erro, width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.bordaMedia,
          borderSide: BorderSide(color: AppColors.lavandaClaro),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      iconTheme: const IconThemeData(size: 24, color: AppColors.cinzaChumbo),

      // O indicador de foco é requisito de acessibilidade e o Windows é usado
      // com teclado. Cada componente do design system desenha o próprio anel;
      // este é o fallback para os widgets do Material.
      focusColor: AppColors.roxoVeu,

      pageTransitionsTheme: AppMovimento.transicoesDePagina,
    );
  }
}
