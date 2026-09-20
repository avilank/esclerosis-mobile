import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/domain/tratamiento.dart';
import '../application/tratamientos_providers.dart';
import 'tratamiento_form_sheet.dart';

/// Lista de tratamientos disponibles, con CRUD. Equivalente a
/// `esclerosis-movil/src/features/tratamientos/screens/ListTratamiento.tsx`
/// (ver manual de usuario ESCLEROSIS - BI, figuras 24, 25, 26, 36).
class TratamientosListScreen extends ConsumerWidget {
  const TratamientosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tratamientosAsync = ref.watch(tratamientosListProvider);
    final api = ref.read(tratamientosApiProvider);
    // Solo el admin administra el catalogo; el medico lo consulta.
    final esAdmin = ref.watch(esAdminProvider);

    Future<void> crear() async {
      final data = await showTratamientoFormSheet(context);
      if (data == null) return;
      try {
        await api.create(data);
        ref.invalidate(tratamientosListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return CrudListScaffold<Tratamiento>(
      title: 'Tratamientos',
      searchHint: 'Buscar tratamiento por nombre...',
      async: tratamientosAsync,
      onAdd: esAdmin ? crear : null,
      onRefresh: () => ref.refresh(tratamientosListProvider.future),
      filter: (t, query) => t.nombre.toLowerCase().contains(query),
      emptyMessage: 'No hay tratamientos registrados.',
      emptyIcon: Icons.medication_outlined,
      countLabel: (count) =>
          '$count tratamiento${count == 1 ? '' : 's'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, tratamiento) => CrudListRow(
        avatarText: tratamiento.nombre,
        title: tratamiento.nombre,
        subtitle: 'ID: ${tratamiento.idTratamiento}',
        subtitleIcon: Icons.medication_outlined,
        // Los tratamientos del catalogo base (`bloqueado`) no se editan ni se
        // borran: el asistente de prescripcion depende de ellos.
        actions: !esAdmin || tratamiento.bloqueado
            ? const []
            : [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final data = await showTratamientoFormSheet(context, tratamiento: tratamiento);
              if (data == null) return;
              try {
                await api.update(tratamiento.idTratamiento, data);
                ref.invalidate(tratamientosListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Eliminar tratamiento',
                message: '¿Eliminar "${tratamiento.nombre}"?',
              );
              if (!confirmed) return;
              try {
                await api.remove(tratamiento.idTratamiento);
                ref.invalidate(tratamientosListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
