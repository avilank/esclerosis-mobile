import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../application/historia_clinica_providers.dart';
import 'widgets/estado_salud_tag.dart';

class DiagnosticoDetailScreen extends ConsumerWidget {
  const DiagnosticoDetailScreen({super.key, required this.idDiagnostico});

  final int idDiagnostico;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar diagnóstico',
      message: '¿Seguro que deseas eliminar este diagnóstico? Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;
    try {
      await ref.read(historiaClinicaRepositoryProvider).eliminarDiagnostico(idDiagnostico);
      ref.invalidate(misDiagnosticosProvider);
      ref.invalidate(misPacientesProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticoAsync = ref.watch(diagnosticoDetalleProvider(idDiagnostico));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: diagnosticoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (diagnostico) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s5),
            children: [
              Row(
                children: [
                  Text(
                    diagnostico.fechaDiagnostico,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  EstadoSaludTag(diagnostico: diagnostico),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Grado: ${diagnostico.gradoEnfermedad}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (diagnostico.medico != null) ...[
                const SizedBox(height: AppSpacing.s1),
                Text(
                  'Médico: ${diagnostico.medico!.nombre}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (diagnostico.esDiagnosticoInicial) ...[
                const SizedBox(height: AppSpacing.s1),
                const Text('Diagnóstico inicial'),
              ],
              if ((diagnostico.observaciones ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s5),
                Text('Observaciones', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s2),
                Text(diagnostico.observaciones!),
              ],
              if (diagnostico.recetas.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s6),
                Text('Recetas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s3),
                for (final receta in diagnostico.recetas)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receta.tratamiento?.nombre ?? 'Tratamiento',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            receta.fechaReceta,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if ((receta.contenido ?? '').isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s2),
                            Text(receta.contenido!),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
