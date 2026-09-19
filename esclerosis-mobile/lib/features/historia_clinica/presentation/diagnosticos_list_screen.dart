import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/historia_clinica_providers.dart';
import 'diagnostico_detail_screen.dart';
import 'diagnostico_form_screen.dart';
import 'widgets/estado_salud_tag.dart';

/// Lista de diagnosticos realizados por el medico logueado, con acceso a
/// crear uno nuevo. Equivalente a
/// `esclerosis-movil/src/app/(tabs)/diagnosticos/index.tsx`.
class DiagnosticosListScreen extends ConsumerWidget {
  const DiagnosticosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticosAsync = ref.watch(misDiagnosticosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnósticos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const DiagnosticoFormScreen()),
          );
          if (created == true) {
            ref.invalidate(misDiagnosticosProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(misDiagnosticosProvider.future),
        child: diagnosticosAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(misDiagnosticosProvider),
          ),
          data: (diagnosticos) {
            if (diagnosticos.isEmpty) {
              return const EmptyView(
                message: 'Todavía no registraste diagnósticos.',
                icon: Icons.medical_information_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s5),
              itemCount: diagnosticos.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
              itemBuilder: (context, index) {
                final diagnostico = diagnosticos[index];
                return Card(
                  child: ListTile(
                    title: Text(diagnostico.fechaDiagnostico),
                    subtitle: Text(diagnostico.gradoEnfermedad),
                    trailing: EstadoSaludTag(diagnostico: diagnostico),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DiagnosticoDetailScreen(idDiagnostico: diagnostico.idDiagnostico),
                      ),
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
