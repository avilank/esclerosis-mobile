import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/crud_list_scaffold.dart';
import '../application/historia_clinica_providers.dart';
import '../domain/diagnostico.dart';
import 'diagnostico_detail_screen.dart';
import 'widgets/estado_salud_tag.dart';

class _DiagnosticoEntry {
  const _DiagnosticoEntry({required this.diagnostico, required this.pacienteNombre});
  final Diagnostico diagnostico;
  final String pacienteNombre;
}

/// Listado administrativo de todos los diagnosticos del sistema (derivado de
/// `historiasClinicasListProvider`). Ver manual de usuario ESCLEROSIS - BI,
/// sección "Diagnósticos" (figuras 37, 38, 39).
class DiagnosticosAdminListScreen extends ConsumerWidget {
  const DiagnosticosAdminListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiasAsync = ref.watch(historiasClinicasListProvider);
    final entriesAsync = historiasAsync.whenData((historias) {
      final entries = <_DiagnosticoEntry>[];
      for (final historia in historias) {
        final nombre = historia.paciente?.nombrePaciente ?? 'Paciente #${historia.idPaciente}';
        for (final diagnostico in historia.diagnosticos) {
          entries.add(_DiagnosticoEntry(diagnostico: diagnostico, pacienteNombre: nombre));
        }
      }
      entries.sort((a, b) => b.diagnostico.fechaDiagnostico.compareTo(a.diagnostico.fechaDiagnostico));
      return entries;
    });

    return CrudListScaffold<_DiagnosticoEntry>(
      title: 'Diagnósticos',
      searchHint: 'Buscar por paciente o estado...',
      async: entriesAsync,
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () => ref.refresh(historiasClinicasListProvider.future),
      filter: (entry, query) =>
          entry.pacienteNombre.toLowerCase().contains(query) ||
          entry.diagnostico.estadoSalud.toLowerCase().contains(query),
      emptyMessage: 'No hay diagnósticos registrados.',
      emptyIcon: Icons.medical_information_outlined,
      countLabel: (count) =>
          '$count diagnóstico${count == 1 ? '' : 's'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, entry) => CrudListRow(
        avatarText: entry.pacienteNombre,
        title: entry.pacienteNombre,
        subtitle: 'Fecha: ${entry.diagnostico.fechaDiagnostico}',
        subtitleIcon: Icons.event_outlined,
        actions: [
          EstadoSaludTag(diagnostico: entry.diagnostico),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiagnosticoDetailScreen(
                  idDiagnostico: entry.diagnostico.idDiagnostico,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
