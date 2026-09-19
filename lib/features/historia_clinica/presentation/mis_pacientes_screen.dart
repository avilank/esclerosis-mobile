import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../auth/application/auth_providers.dart';
import '../application/historia_clinica_providers.dart';

/// Lista de pacientes atendidos por el medico logueado (rol `medico`).
class MisPacientesScreen extends ConsumerWidget {
  const MisPacientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiasAsync = ref.watch(misPacientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(misPacientesProvider.future),
        child: historiasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ],
          ),
          data: (historias) {
            if (historias.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.s6),
                    child: Text(
                      'Todavía no tenés pacientes con diagnósticos asignados.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s5),
              itemCount: historias.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
              itemBuilder: (context, index) {
                final historia = historias[index];
                final paciente = historia.paciente;
                final ultimoDiagnostico =
                    historia.diagnosticos.isNotEmpty ? historia.diagnosticos.first : null;

                return Card(
                  child: ListTile(
                    title: Text(paciente?.nombrePaciente ?? 'Paciente #${historia.idPaciente}'),
                    subtitle: Text(
                      [
                        if (paciente != null) 'DNI: ${paciente.dniPaciente}',
                        if (ultimoDiagnostico != null)
                          'Último: ${ultimoDiagnostico.fechaDiagnostico}',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/pacientes/${historia.idHistoriaClinica}',
                      extra: historia,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
