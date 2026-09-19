import 'package:flutter/material.dart';

/// Estado de carga generico para listas/pantallas. Equivalente a
/// `LoadingState` de `esclerosis-movil/src/components/common`.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
