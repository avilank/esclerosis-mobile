import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/crud_list_scaffold.dart';
import '../../historia_clinica/application/historia_clinica_providers.dart';
import '../../historia_clinica/domain/paciente.dart';
import '../application/citas_providers.dart';
import 'cita_form_screen.dart';
import 'paciente_alta_screen.dart';

/// Padrón de pacientes para la secretaria: buscar, dar de alta y agendar.
class PacientesListScreen extends ConsumerWidget {
  const PacientesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacientesAsync = ref.watch(pacientesListProvider);

    Future<void> crear() async {
      final nuevo = await Navigator.of(context).push<Paciente>(
        MaterialPageRoute(builder: (_) => const PacienteAltaScreen()),
      );
      if (nuevo == null) return;
      ref.invalidate(pacientesListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paciente ${nuevo.nombrePaciente} creado')),
      );
    }

    Future<void> agendar() async {
      final creada = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CitaFormScreen()),
      );
      if (creada == true) invalidarCitasDesdeWidget(ref);
    }

    return CrudListScaffold<Paciente>(
      title: 'Pacientes',
      searchHint: 'Buscar por nombre o DNI...',
      async: pacientesAsync,
      onAdd: crear,
      onRefresh: () => ref.refresh(pacientesListProvider.future),
      filter: (paciente, query) =>
          paciente.nombrePaciente.toLowerCase().contains(query) ||
          paciente.dniPaciente.toLowerCase().contains(query),
      emptyMessage: 'No hay pacientes registrados.',
      emptyIcon: Icons.people_outline,
      countLabel: (count) =>
          '$count paciente${count == 1 ? '' : 's'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, paciente) => CrudListRow(
        avatarText: paciente.nombrePaciente,
        title: paciente.nombrePaciente,
        subtitle: 'DNI ${paciente.dniPaciente} · ${paciente.edadPaciente} años',
        subtitleIcon: Icons.badge_outlined,
        actions: [
          IconButton(
            tooltip: 'Agendar cita',
            icon: const Icon(Icons.event_available_outlined, size: 20),
            onPressed: agendar,
          ),
        ],
      ),
    );
  }
}
