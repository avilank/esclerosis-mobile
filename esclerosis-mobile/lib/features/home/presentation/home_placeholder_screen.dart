import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_version_label.dart';
import '../../auth/application/auth_providers.dart';

/// Home provisional: confirma que el login funciono y que hay conexion con
/// esclerosis-back. Las features clinicas reales (pacientes, diagnosticos,
/// tratamientos, etc.) se agregan en una siguiente iteracion.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esclerosis Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Sesión iniciada',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (usuario != null && usuario.email.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(usuario.email, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.s7),
              const AppVersionLabel(),
            ],
          ),
        ),
      ),
    );
  }
}
