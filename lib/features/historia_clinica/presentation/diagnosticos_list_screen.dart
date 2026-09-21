import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../application/historia_clinica_providers.dart';
import '../domain/diagnostico.dart';
import 'diagnostico_detail_screen.dart';
import 'diagnostico_form_screen.dart';
import 'widgets/estado_salud_tag.dart';

/// Lista de diagnosticos del medico logueado. Equivalente a
/// `esclerosis-movil/src/features/diagnosticos/screens/ListDiagnostico.tsx`.
class DiagnosticosListScreen extends ConsumerWidget {
  const DiagnosticosListScreen({super.key});

  static String _formatFecha(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DiagnosticoFormScreen()),
    );
    if (created == true) {
      ref.invalidate(misDiagnosticosProvider);
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, Diagnostico d) async {
    final nombre = d.paciente?.nombrePaciente ?? 'este paciente';
    final confirmed = await showConfirmDialog(
      context,
      title: 'Confirmar eliminación',
      message: '¿Eliminar el diagnóstico de $nombre?',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await AppToast.run(
      context,
      action: () async {
        await ref.read(historiaClinicaRepositoryProvider).eliminarDiagnostico(d.idDiagnostico);
        ref.invalidate(misDiagnosticosProvider);
      },
      success: 'Diagnóstico eliminado',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticosAsync = ref.watch(misDiagnosticosProvider);

    return CrudListScaffold<Diagnostico>(
      title: 'Diagnósticos',
      searchHint: 'Buscar paciente por nombre o DNI...',
      async: diagnosticosAsync,
      onAdd: () => _openCreate(context, ref),
      onRefresh: () => ref.refresh(misDiagnosticosProvider.future),
      filter: (d, query) {
        final nombre = (d.paciente?.nombrePaciente ?? '').toLowerCase();
        final dni = (d.paciente?.dniPaciente ?? '').toLowerCase();
        return nombre.contains(query) || dni.contains(query) || d.estadoSalud.toLowerCase().contains(query);
      },
      emptyMessage: 'No hay diagnósticos registrados.',
      emptyIcon: Icons.medical_information_outlined,
      countLabel: (count) =>
          '$count diagnóstico${count == 1 ? '' : 's'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, diagnostico) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DiagnosticoDetailScreen(idDiagnostico: diagnostico.idDiagnostico),
          ),
        ),
        child: CrudListRow(
          avatarText: diagnostico.paciente?.nombrePaciente ?? 'NA',
          title: diagnostico.paciente?.nombrePaciente ?? 'Sin paciente',
          subtitle:
              'DNI: ${diagnostico.paciente?.dniPaciente ?? '-'} · ${_formatFecha(diagnostico.fechaDiagnostico)}',
          subtitleIcon: Icons.calendar_today_outlined,
          actions: [
            EstadoSaludTag(diagnostico: diagnostico),
            const SizedBox(width: 4),
            CrudVerticalActions(
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DiagnosticoDetailScreen(idDiagnostico: diagnostico.idDiagnostico),
                ),
              ),
              onDelete: () => _eliminar(context, ref, diagnostico),
            ),
          ],
        ),
      ),
    );
  }
}
