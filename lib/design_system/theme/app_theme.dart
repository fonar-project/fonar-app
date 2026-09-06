import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Tema base montado a partir dos tokens.
///
/// TODO: revisar por completo quando a identidade visual existir. Hoje isto é
/// só o esqueleto que garante que nenhuma tela invente cor ou espaçamento
/// próprio.
abstract final class AppTheme {
  static ThemeData get claro => _montar(Brightness.light);
  static ThemeData get escuro => _montar(Brightness.dark);

  static ThemeData _montar(Brightness brilho) {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.semente,
      brightness: brilho,
      error: AppColors.erro,
    );

    return ThemeData(
      colorScheme: esquema,
      textTheme: AppTypography.textTheme,
      visualDensity: VisualDensity.standard,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bordaMedia),
        margin: EdgeInsets.all(AppSpacing.xs),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.bordaPequena),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.alvoDeToqueMinimo),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.bordaPequena,
          ),
        ),
      ),
      // TODO: foco visível é requisito de acessibilidade e o Windows é usado
      // com teclado. Verificar que o indicador aparece em todo componente
      // interativo antes de fechar o design system.
      focusColor: AppColors.foco,
    );
  }
}
