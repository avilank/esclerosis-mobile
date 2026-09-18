import 'package:flutter/material.dart';

import '../../../core/widgets/app_logo.dart';

/// Pantalla mostrada mientras se rehidrata la sesion (lectura de secure
/// storage). Sin llamadas de red ni dependencias externas.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: AppLogo(size: 80)),
    );
  }
}
