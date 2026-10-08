import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_cores.dart';
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
  static ThemeData get claro => _montar(_esquemaClaro, AppCores.claro);

  /// Paleta aprovada em 25/09/2026 — ver `AppColors`, seção "tema escuro", e
  /// `AppCores.escuro`.
  static ThemeData get escuro => _montar(_esquemaEscuro, AppCores.escuro);

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

  /// O mesmo mapa de papéis do claro, com a paleta escura. O "primary" é o
  /// ACENTO — é o que o Material usa para texto e ícone de destaque; o fundo
  /// dos botões do design system vem de `AppCores.primaria`.
  static const _esquemaEscuro = ColorScheme(
    brightness: Brightness.dark,

    primary: AppColors.escuroAcento,
    onPrimary: AppColors.escuroFundo,
    primaryContainer: AppColors.escuroPrimaria,
    onPrimaryContainer: AppColors.escuroTexto,

    secondary: AppColors.escuroLavanda,
    onSecondary: AppColors.escuroTexto,
    secondaryContainer: AppColors.escuroLavanda,
    onSecondaryContainer: AppColors.escuroSecundario,

    tertiary: AppColors.escuroPrimariaHover,
    onTertiary: AppColors.escuroTexto,

    surface: AppColors.escuroFundo,
    onSurface: AppColors.escuroTexto,
    surfaceContainerLowest: AppColors.escuroCartao,
    surfaceContainerLow: AppColors.escuroCartao,
    surfaceContainer: AppColors.escuroSuave,
    surfaceContainerHigh: AppColors.escuroSuave,
    surfaceContainerHighest: AppColors.escuroLavanda,
    onSurfaceVariant: AppColors.escuroSecundario,

    outline: AppColors.escuroBorda,
    outlineVariant: AppColors.escuroBorda,

    error: AppColors.escuroErro,
    onError: AppColors.escuroSobreErro,
    errorContainer: AppColors.escuroFundo,
    onErrorContainer: AppColors.escuroErro,
  );

  static ThemeData _montar(ColorScheme esquema, AppCores cores) {
    final bordaCampo = OutlineInputBorder(
      borderRadius: AppRadius.bordaPequena,
      borderSide: BorderSide(color: cores.bordaDeCampo, width: 1.5),
    );
    final bordaFoco = OutlineInputBorder(
      borderRadius: AppRadius.bordaPequena,
      borderSide: BorderSide(color: cores.foco, width: 3),
    );

    return ThemeData(
      colorScheme: esquema,
      extensions: [cores],
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
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.bordaMedia,
          side: BorderSide(color: cores.borda),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(
        color: cores.borda,
        thickness: 1,
        space: 1,
      ),

      // Campo com borda de 1,5 px no tom de texto, não lavanda: sobre o
      // fundo, a lavanda some e o campo vira texto solto na tela. O foco troca
      // a borda pela cor de foco do projeto, como em todo controle interativo.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: bordaCampo,
        enabledBorder: bordaCampo,
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.bordaPequena,
          borderSide: BorderSide(color: cores.borda, width: 1.5),
        ),
        focusedBorder: bordaFoco,
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.bordaPequena,
          borderSide: BorderSide(color: cores.erro, width: 1.5),
        ),
        focusedErrorBorder: bordaFoco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.sm + 1,
        ),
      ),

      iconTheme: IconThemeData(size: 24, color: cores.texto),

      // O indicador de foco é requisito de acessibilidade e o Windows é usado
      // com teclado. Cada componente do design system desenha o próprio anel;
      // este é o fallback para os widgets do Material.
      focusColor: cores.veu,

      pageTransitionsTheme: AppMovimento.transicoesDePagina,
    );
  }
}
