import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/design_system/tokens/app_colors.dart';

/// Razão de contraste WCAG 2.1 entre duas cores opacas.
///
/// (L1 + 0,05) / (L2 + 0,05), com L a luminância relativa. É a mesma conta que
/// as ferramentas de auditoria fazem — está aqui para o teste não depender de
/// alguém lembrar de abrir uma delas.
double contraste(Color a, Color b) {
  final la = _luminancia(a);
  final lb = _luminancia(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _luminancia(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

void main() {
  // Os números vêm do design system e do CLAUDE.md. Este teste existe para que
  // um ajuste de hex "só um tomzinho mais claro" não passe silenciosamente:
  // contraste é requisito, não gosto.
  group('contraste da paleta', () {
    test('texto principal sobre os dois fundos passa em AAA/AA', () {
      expect(
        contraste(AppColors.cinzaChumbo, AppColors.creme),
        greaterThanOrEqualTo(7.0),
        reason: 'chumbo sobre creme deve passar em AAA (~9,3:1)',
      );
      expect(
        contraste(AppColors.cinzaChumbo, AppColors.lavandaClaro),
        greaterThanOrEqualTo(4.5),
        reason: 'chumbo sobre lavanda deve passar em AA (~6,9:1)',
      );
    });

    test('roxo e creme se invertem sem perder contraste', () {
      expect(
        contraste(AppColors.roxoProfundo, AppColors.creme),
        greaterThanOrEqualTo(7.0),
      );
      expect(
        contraste(AppColors.creme, AppColors.roxoProfundo),
        greaterThanOrEqualTo(7.0),
        reason: 'texto creme sobre botão roxo',
      );
    });

    test('derivados do roxo continuam legíveis com texto creme', () {
      for (final tom in [AppColors.roxoHover, AppColors.roxoPressionado]) {
        expect(
          contraste(AppColors.creme, tom),
          greaterThanOrEqualTo(4.5),
          reason: 'hover e pressed também recebem o rótulo do botão',
        );
      }
    });

    test('cada texto secundário serve ao fundo para o qual foi criado', () {
      expect(
        contraste(AppColors.secundarioSobreCreme, AppColors.creme),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contraste(AppColors.secundarioSobreLavanda, AppColors.lavandaClaro),
        greaterThanOrEqualTo(4.5),
      );
    });

    test(
      'o token de creme reprova sobre lavanda — é por isso que existem dois',
      () {
        // Documenta a armadilha em vez de só descrevê-la em comentário: se
        // alguém "simplificar" os dois tokens em um, este teste cai.
        expect(
          contraste(AppColors.secundarioSobreCreme, AppColors.lavandaClaro),
          lessThan(4.5),
        );
      },
    );

    test('texto secundário escuro passa dentro de aviso lavanda', () {
      // A superfície é translúcida; o que o olho vê é a mistura com o creme.
      final fundoDoAviso = Color.alphaBlend(
        AppColors.lavandaSuave,
        AppColors.creme,
      );
      expect(
        contraste(AppColors.secundarioSobreLavanda, fundoDoAviso),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contraste(AppColors.secundarioSobreCreme, fundoDoAviso),
        lessThan(4.5),
        reason: 'o token claro reprova aqui — use o escuro dentro de aviso',
      );
    });

    test('anel de foco se destaca do fundo', () {
      // 3:1 é o mínimo WCAG para indicador de interface (critério 1.4.11).
      expect(
        contraste(AppColors.foco, AppColors.creme),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('cores de status passam em AA sobre o fundo principal', () {
      for (final cor in [
        AppColors.sucesso,
        AppColors.atencao,
        AppColors.erro,
      ]) {
        expect(
          contraste(cor, AppColors.creme),
          greaterThanOrEqualTo(4.5),
          reason: 'status de medida é a informação mais crítica da tela',
        );
      }
    });
  });
}
