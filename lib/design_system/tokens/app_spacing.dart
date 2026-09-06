/// Escala de espaçamento em passos de 4dp.
///
/// Use estes tokens em vez de números soltos: padding, gap e margin saem
/// todos daqui. Mantém o ritmo vertical consistente entre telas compactas
/// (celular em consultório) e expandidas (desktop).
abstract final class AppSpacing {
  static const nenhum = 0.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Alvo mínimo de toque. Não reduzir: o app é usado com pressa e às vezes
  /// com luva.
  static const alvoDeToqueMinimo = 48.0;
}
