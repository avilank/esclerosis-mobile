// Smoke test minimo: la app arranca y muestra la pantalla de bienvenida
// cuando no hay sesion guardada, y desde ahi se puede llegar al login.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esclerosis_mobile/app/app.dart';
import 'package:esclerosis_mobile/core/storage/token_storage.dart';
import 'package:esclerosis_mobile/features/auth/application/auth_providers.dart';

/// `flutter_secure_storage` no tiene canal de plataforma mockeado en tests
/// widget; esta version en memoria evita tocar el channel real.
class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveToken(String accessToken) async {}

  @override
  Future<bool> get hasSession async => false;
}

void main() {
  testWidgets('Muestra bienvenida y permite llegar al login sin sesion',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        ],
        child: const EsclerosisApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comenzar'), findsOneWidget);

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
