import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/app/app.dart';
import 'package:praatico_app/l10n/app_strings.dart';

void main() {
  testWidgets('app sobe e abre na rota inicial', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PraaticoApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginTitulo), findsOneWidget);
  });
}
