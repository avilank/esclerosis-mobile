import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../application/administracion_providers.dart';
import '../domain/sede.dart';
import 'simple_field_form_sheet.dart';

/// CRUD de sedes. Equivalente a
/// `esclerosis-movil/src/app/(tabs)/(administrador)/sedes/index.tsx` (ver
/// manual de usuario ESCLEROSIS - BI, figuras 5, 18, 19, 20).
class SedesListScreen extends ConsumerWidget {
  const SedesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sedesAsync = ref.watch(sedesListProvider);
    final api = ref.read(sedesApiProvider);

    Future<void> guardar({int? id, Map<String, String>? initial}) async {
      final data = await showSimpleFormSheet(
        context,
        title: id == null ? 'Nueva sede' : 'Editar sede',
        sectionIcon: Icons.apartment_outlined,
        sectionLabel: 'Datos de la sede',
        submitLabel: id == null ? 'Crear' : 'Guardar',
        fields: [
          SimpleFormField(key: 'nombre', label: 'Nombre *', initialValue: initial?['nombre']),
          SimpleFormField(
            key: 'direccion',
            label: 'Dirección *',
            initialValue: initial?['direccion'],
            required: false,
          ),
        ],
      );
      if (data == null) return;
      try {
        if (id == null) {
          await api.create(data);
        } else {
          await api.update(id, data);
        }
        ref.invalidate(sedesListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return CrudListScaffold<Sede>(
      title: 'Sedes',
      searchHint: 'Buscar por nombre o dirección...',
      async: sedesAsync,
      onAdd: () => guardar(),
      onRefresh: () => ref.refresh(sedesListProvider.future),
      filter: (sede, query) =>
          sede.nombre.toLowerCase().contains(query) ||
          (sede.direccion ?? '').toLowerCase().contains(query),
      emptyMessage: 'No hay sedes registradas.',
      emptyIcon: Icons.map_outlined,
      countLabel: (count) => '$count sede${count == 1 ? '' : 's'} encontrada${count == 1 ? '' : 's'}',
      itemBuilder: (context, sede) => CrudListRow(
        avatarText: sede.nombre,
        title: sede.nombre,
        subtitle: sede.direccion,
        subtitleIcon: Icons.place_outlined,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => guardar(
              id: sede.idSede,
              initial: {'nombre': sede.nombre, 'direccion': sede.direccion ?? ''},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Eliminar sede',
                message: '¿Eliminar "${sede.nombre}"?',
              );
              if (!confirmed) return;
              try {
                await api.remove(sede.idSede);
                ref.invalidate(sedesListProvider);
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
