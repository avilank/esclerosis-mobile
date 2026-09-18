// Smoke test minimo: la app arranca y muestra la pantalla de login cuando no
// hay sesion guardada.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esclerosis_mobile/app/app.dart';

void main() {
  testWidgets('Muestra login al no haber sesion', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EsclerosisApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
  });
}
