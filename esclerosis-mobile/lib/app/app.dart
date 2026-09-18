import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Raiz de la aplicacion. Usa `MaterialApp.router` cableado al
/// `routerProvider`. Sin Firebase ni ningun otro servicio de Google.
class EsclerosisApp extends ConsumerWidget {
  const EsclerosisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Esclerosis Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
