import 'package:flutter/material.dart';

/// Tokens de cor — TODOS OS VALORES SÃO PLACEHOLDER.
///
/// TODO: substituir pela paleta real quando a identidade visual for definida.
/// Ao trocar, verificar contraste AA (4.5:1 para texto normal, 3:1 para texto
/// grande e para elementos de interface) em CADA par texto/fundo, nos temas
/// claro e escuro.
///
/// Regra de acessibilidade do projeto: nenhuma informação crítica pode ser
/// comunicada apenas por cor. Estado sempre acompanha ícone, texto ou forma.
abstract final class AppColors {
  /// Semente do Material 3. O restante do esquema é derivado dela.
  static const semente = Color(0xFF00696E);

  // Cores de estado. Usar sempre junto de um ícone ou rótulo.
  static const sucesso = Color(0xFF1B6B3A);
  static const atencao = Color(0xFF8A5A00);
  static const erro = Color(0xFFB3261E);

  /// Indicador de foco de teclado. Precisa ser visível nos dois temas —
  /// navegação por teclado é requisito no Windows.
  static const foco = Color(0xFF0B57D0);
}
