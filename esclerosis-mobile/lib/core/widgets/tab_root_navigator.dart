import 'package:flutter/material.dart';

/// [Navigator] independiente por pestaña del shell inferior. Las rutas que se
/// abren con `Navigator.of(context).push` desde un tab (p. ej. modulos del
/// dashboard) quedan en esta pila y no ocultan el bottom navigation bar.
class TabRootNavigator extends StatelessWidget {
  const TabRootNavigator({super.key, required this.root});

  final Widget root;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (_, _) => [
        MaterialPageRoute<void>(builder: (_) => root),
      ],
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => root,
        );
      },
    );
  }
}
