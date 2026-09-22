import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/app.dart';
import 'package:fonar_app/l10n/app_strings.dart';

void main() {
  testWidgets('app sobe e abre na rota inicial', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FonarApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginTitulo), findsOneWidget);
  });
}
