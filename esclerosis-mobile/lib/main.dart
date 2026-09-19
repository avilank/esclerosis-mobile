import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/auth/application/auth_providers.dart';

/// Punto de entrada. A diferencia de `app-comunicador`, no hay bootstrap de
/// Firebase/push aca (descartado por decision del proyecto): la app arranca
/// directo a la UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EsclerosisApp(),
    ),
  );
}
