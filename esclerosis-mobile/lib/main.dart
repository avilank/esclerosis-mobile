import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Punto de entrada. A diferencia de `app-comunicador`, no hay bootstrap de
/// Firebase/push aca (descartado por decision del proyecto): la app arranca
/// directo a la UI.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: EsclerosisApp(),
    ),
  );
}
