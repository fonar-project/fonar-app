import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/design_system/tokens/app_cores.dart';
import 'package:fonar_app/design_system/widgets/app_status_medida.dart';

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

    test('selo de status passa sobre o próprio fundo tingido', () {
      // O selo pinta o fundo com a cor do status a 10%. O contraste que conta
      // é o do texto sobre essa mistura, não sobre o creme puro — foi assim
      // que o "sem faixa de referência" escapou com 4,41:1.
      for (final status in StatusMedida.values) {
        final cor = status.cor(AppCores.claro);
        final fundo = Color.alphaBlend(
          cor.withValues(alpha: 0.10),
          AppColors.creme,
        );
        expect(
          contraste(cor, fundo),
          greaterThanOrEqualTo(4.5),
          reason: status.name,
        );
      }
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

  // Os pares que o tema escuro tem de cumprir — os mesmos papéis do claro. A
  // conta vale para os DOIS conjuntos de `AppCores`: uma cor que reprove em
  // qualquer um dos temas quebra o CI.
  group('contraste por papel, nos dois temas', () {
    for (final (nome, c) in [
      ('claro', AppCores.claro),
      ('escuro', AppCores.escuro),
    ]) {
      // A superfície suave do claro é translúcida: conta a mistura com o
      // fundo, que é o que o olho vê.
      final suave = Color.alphaBlend(c.suave, c.fundo);
      final superficies = {
        'fundo': c.fundo,
        'cartão': c.cartao,
        'suave': suave,
      };

      test('$nome: texto em AAA sobre fundo e cartão, AA sobre o suave', () {
        expect(contraste(c.texto, c.fundo), greaterThanOrEqualTo(7));
        expect(contraste(c.texto, c.cartao), greaterThanOrEqualTo(7));
        expect(contraste(c.texto, suave), greaterThanOrEqualTo(4.5));
      });

      test('$nome: secundário em AA onde é usado', () {
        expect(contraste(c.secundario, c.fundo), greaterThanOrEqualTo(4.5));
        expect(contraste(c.secundario, c.cartao), greaterThanOrEqualTo(4.5));
        expect(
          contraste(c.secundarioSobreLavanda, c.lavanda),
          greaterThanOrEqualTo(4.5),
          reason: 'rótulo de botão desabilitado',
        );
        expect(
          contraste(c.secundarioSobreLavanda, suave),
          greaterThanOrEqualTo(4.5),
          reason: 'texto dentro de aviso',
        );
      });

      test('$nome: botão primário e barra lateral', () {
        for (final fundo in [
          c.primaria,
          c.primariaHover,
          c.primariaPressionada,
          c.lateral,
        ]) {
          expect(contraste(c.sobrePrimaria, fundo), greaterThanOrEqualTo(4.5));
        }
      });

      test('$nome: acento (link, ícone, botão secundário) em AA', () {
        for (final MapEntry(:key, :value) in superficies.entries) {
          expect(
            contraste(c.acento, value),
            greaterThanOrEqualTo(4.5),
            reason: 'acento sobre $key',
          );
        }
      });

      test('$nome: estados em AA, e o selo sobre o próprio tingido', () {
        for (final cor in [c.sucesso, c.atencao, c.erro]) {
          for (final MapEntry(:key, :value) in superficies.entries) {
            expect(
              contraste(cor, value),
              greaterThanOrEqualTo(4.5),
              reason: 'estado sobre $key',
            );
          }
        }
        for (final status in StatusMedida.values) {
          final cor = status.cor(c);
          final tingido = Color.alphaBlend(
            cor.withValues(alpha: 0.10),
            c.fundo,
          );
          expect(
            contraste(cor, tingido),
            greaterThanOrEqualTo(4.5),
            reason: status.name,
          );
        }
        expect(contraste(c.sobreErro, c.erro), greaterThanOrEqualTo(4.5));
      });

      test('$nome: foco e borda de campo em 3:1 (WCAG 1.4.11)', () {
        // Sobre a barra lateral o anel é o `sobrePrimaria`, não o foco: no
        // claro, o azul some sobre o roxo (2,3:1) — ver `_ItemLateral`.
        for (final fundo in [c.fundo, c.cartao]) {
          expect(contraste(c.foco, fundo), greaterThanOrEqualTo(3));
        }
        expect(contraste(c.sobrePrimaria, c.lateral), greaterThanOrEqualTo(3));
        expect(contraste(c.bordaDeCampo, c.fundo), greaterThanOrEqualTo(3));
        expect(contraste(c.bordaDeCampo, c.cartao), greaterThanOrEqualTo(3));
      });
    }

    test('no escuro, o foco aparece também sobre o botão primário', () {
      // No claro o anel fica por fora do botão, sobre o creme. No escuro o
      // botão é mais claro que o fundo, e o anel encosta nele.
      expect(
        contraste(AppCores.escuro.foco, AppCores.escuro.primaria),
        greaterThanOrEqualTo(3),
      );
    });
  });
}
