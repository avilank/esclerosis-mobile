import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_form_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../application/historia_clinica_providers.dart';
import '../domain/historia_clinica.dart';
import '../domain/paciente.dart';
import 'paciente_historia_screen.dart';

/// Listado administrativo de historias clinicas, con buscador por
/// nombre/DNI y creacion de nuevas historias. Ver manual de usuario
/// ESCLEROSIS - BI, figuras 34, 35, 36.
class HistoriasClinicasListScreen extends ConsumerWidget {
  const HistoriasClinicasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiasAsync = ref.watch(historiasClinicasListProvider);
    final pacientesAsync = ref.watch(pacientesListProvider);
    final api = ref.read(historiaClinicaApiProvider);

    Future<void> crear() async {
      final pacientes = pacientesAsync.value ?? const [];
      if (pacientes.isEmpty) {
        AppToast.warning(context, 'No hay pacientes para asignar');
        return;
      }
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierColor: const Color(0x730F172A),
        builder: (context) => _NuevaHistoriaDialog(pacientes: pacientes),
      );
      if (result == null) return;
      if (!context.mounted) return;
      await AppToast.run(
        context,
        action: () async {
          await api.create(
            idPaciente: result['idPaciente'] as int,
            estado: result['estado'] as String?,
          );
          ref.invalidate(historiasClinicasListProvider);
        },
        success: 'Historia clínica creada',
      );
    }

    return CrudListScaffold<HistoriaClinica>(
      title: 'Historias Clínicas',
      searchHint: 'Buscar paciente por nombre o DNI',
      async: historiasAsync,
      onAdd: crear,
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () => ref.refresh(historiasClinicasListProvider.future),
      filter: (h, query) =>
          (h.paciente?.nombrePaciente ?? '').toLowerCase().contains(query) ||
          (h.paciente?.dniPaciente ?? '').toLowerCase().contains(query),
      emptyMessage: 'No hay historias clínicas registradas.',
      emptyIcon: Icons.folder_shared_outlined,
      countLabel: (count) =>
          '$count historia${count == 1 ? '' : 's'} clínica${count == 1 ? '' : 's'} encontrada${count == 1 ? '' : 's'}',
      itemBuilder: (context, historia) {
        final paciente = historia.paciente;
        final nombre = paciente?.nombrePaciente ?? 'Paciente #${historia.idPaciente}';
        final subtitleParts = [
          'HC: ${historia.estado.isEmpty ? 'Activa' : historia.estado}',
          if (paciente != null) 'DNI: ${paciente.dniPaciente}',
          if (paciente != null) '${paciente.edadPaciente} años',
        ];
        return CrudListRow(
          avatarText: nombre,
          title: nombre,
          subtitle: subtitleParts.join(' · '),
          subtitleIcon: Icons.badge_outlined,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PacienteHistoriaScreen(historia: historia)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NuevaHistoriaDialog extends StatefulWidget {
  const _NuevaHistoriaDialog({required this.pacientes});
  final List<Paciente> pacientes;

  @override
  State<_NuevaHistoriaDialog> createState() => _NuevaHistoriaDialogState();
}

class _NuevaHistoriaDialogState extends State<_NuevaHistoriaDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _idPaciente;
  final _estadoController = TextEditingController(text: 'Activa');

  @override
  void dispose() {
    _estadoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({
      'idPaciente': _idPaciente,
      'estado': _estadoController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialogChrome(
      icon: Icons.description_outlined,
      title: 'Nueva historia clínica',
      sectionIcon: Icons.folder_shared_outlined,
      sectionLabel: 'Datos de la historia clínica',
      submitLabel: 'Crear',
      submitIcon: Icons.add,
      onSubmit: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Paciente *', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _idPaciente,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: widget.pacientes
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.idPaciente,
                      child: Text(
                        '${p.nombrePaciente} - DNI: ${p.dniPaciente}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _idPaciente = value),
              validator: (value) => value == null ? 'Selecciona un paciente' : null,
            ),
            const SizedBox(height: 12),
            Text('Estado', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            TextFormField(controller: _estadoController, decoration: const InputDecoration()),
          ],
        ),
      ),
    );
  }
}
