import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/tokens/app_movimento.dart';

/// Troca o conteúdo de uma [AppTrocaAnimada] de 'A' para 'B'.
class _Troca extends StatefulWidget {
  const _Troca();

  @override
  State<_Troca> createState() => _TrocaState();
}

class _TrocaState extends State<_Troca> {
  var _qual = 'A';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () => setState(() => _qual = 'B'),
        child: const Text('trocar'),
      ),
      AppTrocaAnimada(chave: _qual, child: Text('conteúdo $_qual')),
    ],
  );
}

Future<void> _montar(
  WidgetTester tester,
  Widget filho, {
  bool reduzido = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.claro,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduzido),
      child: Scaffold(body: filho),
    ),
  ),
);

double _opacidade(WidgetTester tester, String texto) {
  final fades = tester.widgetList<FadeTransition>(
    find.ancestor(of: find.text(texto), matching: find.byType(FadeTransition)),
  );
  return fades.fold(1.0, (acc, f) => acc * f.opacity.value);
}

void main() {
  group('AppTrocaAnimada', () {
    testWidgets('o novo entra esmaecendo; o antigo sai na hora', (
      tester,
    ) async {
      await _montar(tester, const _Troca());
      await tester.tap(find.text('trocar'));
      await tester.pump();

      // Nunca dois estados na tela ao mesmo tempo.
      expect(find.text('conteúdo A'), findsNothing);
      expect(find.text('conteúdo B'), findsOneWidget);
      expect(_opacidade(tester, 'conteúdo B'), lessThan(1));

      await tester.pump(AppMovimento.media);
      expect(_opacidade(tester, 'conteúdo B'), 1);
    });

    testWidgets('com movimento reduzido, o novo aparece pronto', (
      tester,
    ) async {
      await _montar(tester, const _Troca(), reduzido: true);
      await tester.tap(find.text('trocar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('conteúdo A'), findsNothing);
      expect(_opacidade(tester, 'conteúdo B'), 1);
    });

    testWidgets('a mesma chave com dado novo não anima', (tester) async {
      await _montar(
        tester,
        const AppTrocaAnimada(chave: 'x', child: Text('1')),
      );
      await tester.pumpAndSettle();
      await _montar(
        tester,
        const AppTrocaAnimada(chave: 'x', child: Text('2')),
      );
      await tester.pump();

      expect(_opacidade(tester, '2'), 1);
    });
  });

  group('AppRevelar', () {
    Future<void> revelar(WidgetTester tester, bool visivel, {bool r = false}) =>
        _montar(
          tester,
          Column(
            children: [
              AppRevelar(
                visivel: visivel,
                child: const SizedBox(height: 100, child: Text('seção')),
              ),
            ],
          ),
          reduzido: r,
        );

    testWidgets('escondido não ocupa altura; ao aparecer, a altura cresce', (
      tester,
    ) async {
      await revelar(tester, false);
      expect(tester.getSize(find.byType(AppRevelar)).height, 0);

      await revelar(tester, true);
      await tester.pump(const Duration(milliseconds: 50));
      final meio = tester.getSize(find.byType(AppRevelar)).height;
      expect(meio, greaterThan(0));
      expect(meio, lessThan(100));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AppRevelar)).height, 100);
    });

    testWidgets('com movimento reduzido, aparece inteiro na hora', (
      tester,
    ) async {
      await revelar(tester, false, r: true);
      await revelar(tester, true, r: true);
      await tester.pump();

      expect(tester.getSize(find.byType(AppRevelar)).height, 100);
    });
  });

  group('AppTamanhoAnimado', () {
    Future<void> tamanho(WidgetTester tester, double altura) => _montar(
      tester,
      Column(
        children: [AppTamanhoAnimado(child: SizedBox(height: altura))],
      ),
      reduzido: true,
    );

    testWidgets('com movimento reduzido, mudar de tamanho não quebra', (
      tester,
    ) async {
      // Duração zero no `AnimatedSize` termina a animação no meio do layout,
      // e o Flutter acusa erro — justamente para quem pediu menos movimento.
      await tamanho(tester, 0);
      await tamanho(tester, 80);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppTamanhoAnimado)).height, 80);
    });
  });

  group('transição de página', () {
    Future<void> navegar(WidgetTester tester, {bool reduzido = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.claro,
          builder: (context, filho) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduzido),
            child: filho!,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('tela nova')),
                ),
              ),
              child: const Text('ir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
    }

    testWidgets('a tela nova esmaece ao entrar, sem deslizar de lado', (
      tester,
    ) async {
      await navegar(tester);

      expect(_opacidade(tester, 'tela nova'), lessThan(1));
      expect(
        find.ancestor(
          of: find.text('tela nova'),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(_opacidade(tester, 'tela nova'), 1);
    });

    testWidgets('com movimento reduzido, a tela nova aparece pronta', (
      tester,
    ) async {
      await navegar(tester, reduzido: true);

      expect(_opacidade(tester, 'tela nova'), 1);
    });
  });
}
