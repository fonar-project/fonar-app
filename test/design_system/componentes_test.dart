import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/design_system/theme/app_theme.dart';
import 'package:praatico_app/design_system/widgets/app_botao.dart';
import 'package:praatico_app/design_system/widgets/app_campo_texto.dart';
import 'package:praatico_app/design_system/widgets/app_indicador_conexao.dart';
import 'package:praatico_app/design_system/widgets/app_status_medida.dart';
import 'package:praatico_app/l10n/app_strings.dart';

Widget _tela(Widget filho) => MaterialApp(
  theme: AppTheme.claro,
  home: Scaffold(body: Center(child: filho)),
);

void main() {
  group('AppBotao', () {
    testWidgets('chama o callback ao ser tocado', (tester) async {
      var tocou = false;
      await tester.pumpWidget(
        _tela(AppBotao.primario(rotulo: 'Entrar', aoTocar: () => tocou = true)),
      );

      await tester.tap(find.text('Entrar'));
      expect(tocou, isTrue);
    });

    test('recusa ser desabilitado sem explicação', () {
      // A regra do design system — desabilitado nunca é só cor apagada — vira
      // erro de construção, não item de checklist de revisão.
      //
      // O rótulo vem de uma função de propósito: com literais, a chamada seria
      // uma expressão constante, o analisador avaliaria o assert em tempo de
      // compilação e o teste deixaria de compilar em vez de falhar aqui.
      String rotulo() => 'Baixar';

      expect(
        () => AppBotao.primario(rotulo: rotulo(), aoTocar: null),
        throwsAssertionError,
      );
    });

    testWidgets('desabilitado mostra o motivo em texto', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppBotao.primario(
            rotulo: 'Gravar',
            aoTocar: null,
            motivoDesabilitado: 'Registre o consentimento para gravar',
          ),
        ),
      );

      expect(find.text('Registre o consentimento para gravar'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('respeita o alvo mínimo de toque', (tester) async {
      await tester.pumpWidget(
        _tela(AppBotao.primario(rotulo: 'Entrar', aoTocar: () {})),
      );

      // 48dp: o app é usado com pressa e às vezes com luva.
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48.0),
      );
    });
  });

  group('StatusMedida', () {
    test('cada status tem ícone próprio', () {
      // O contrato de acessibilidade do projeto: informação crítica nunca é
      // comunicada só por cor. Dois status com o mesmo ícone dependeriam da
      // cor para se distinguir.
      final icones = StatusMedida.values.map((s) => s.icone).toSet();
      expect(icones.length, StatusMedida.values.length);
    });

    test('cada status tem rótulo próprio e não vazio', () {
      final rotulos = StatusMedida.values.map((s) => s.rotulo).toSet();
      expect(rotulos.length, StatusMedida.values.length);
      expect(rotulos.any((r) => r.trim().isEmpty), isFalse);
    });

    test('existe o estado de faixa indisponível', () {
      // Classificar sem referência válida é pior que não classificar. Se
      // alguém remover este estado, a medida passa a ser exibida como se
      // tivesse faixa — e não tem.
      expect(StatusMedida.values, contains(StatusMedida.semReferencia));
    });

    testWidgets('desenha texto junto do ícone', (tester) async {
      for (final status in StatusMedida.values) {
        await tester.pumpWidget(_tela(AppStatusMedida(status: status)));
        expect(find.text(status.rotulo), findsOneWidget);
      }
    });
  });

  group('AppCampoTexto', () {
    testWidgets('mostra o rótulo acima, sempre visível', (tester) async {
      await tester.pumpWidget(
        _tela(const AppCampoTexto(rotulo: 'Nome completo')),
      );
      expect(find.text('Nome completo'), findsOneWidget);
    });

    testWidgets('erro aparece como mensagem de texto', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppCampoTexto(
            rotulo: 'E-mail',
            erro: 'Informe um e-mail válido (ex.: nome@dominio.com.br)',
          ),
        ),
      );

      expect(
        find.text('Informe um e-mail válido (ex.: nome@dominio.com.br)'),
        findsOneWidget,
      );
    });

    testWidgets('erro substitui o texto de apoio', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppCampoTexto(
            rotulo: 'E-mail',
            apoio: 'Usamos para enviar o laudo',
            erro: 'Informe um e-mail válido',
          ),
        ),
      );

      expect(find.text('Usamos para enviar o laudo'), findsNothing);
      expect(find.text('Informe um e-mail válido'), findsOneWidget);
    });
  });

  group('AppIndicadorConexao', () {
    testWidgets('diz em texto qual é o estado', (tester) async {
      await tester.pumpWidget(_tela(const AppIndicadorConexao(online: true)));
      expect(find.text(AppStrings.conexaoOnline), findsOneWidget);

      await tester.pumpWidget(_tela(const AppIndicadorConexao(online: false)));
      expect(find.text(AppStrings.conexaoOffline), findsOneWidget);
    });
  });
}
