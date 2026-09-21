import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../application/administracion_providers.dart';
import '../domain/area.dart';
import 'simple_field_form_sheet.dart';

/// CRUD de areas. Equivalente a
/// `esclerosis-movil/src/app/(tabs)/(administrador)/areas/index.tsx` (ver
/// manual de usuario ESCLEROSIS - BI, figuras 21, 22, 23).
class AreasListScreen extends ConsumerWidget {
  const AreasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasListProvider);
    final api = ref.read(areasApiProvider);

    Future<void> guardar({int? id, String? initial}) async {
      final data = await showSimpleFormSheet(
        context,
        title: id == null ? 'Nueva área' : 'Editar Área',
        sectionIcon: Icons.category_outlined,
        sectionLabel: 'Datos del área',
        submitLabel: id == null ? 'Crear' : 'Guardar',
        fields: [SimpleFormField(key: 'descripcion', label: 'Descripción *', initialValue: initial)],
      );
      if (data == null) return;
      if (!context.mounted) return;
      await AppToast.run(
        context,
        action: () async {
          if (id == null) {
            await api.create(data);
          } else {
            await api.update(id, data);
          }
          ref.invalidate(areasListProvider);
        },
        success: id == null ? 'Área creada' : 'Área actualizada',
      );
    }

    return CrudListScaffold<Area>(
      title: 'Áreas',
      searchHint: 'Buscar por descripción...',
      async: areasAsync,
      onAdd: () => guardar(),
      onRefresh: () => ref.refresh(areasListProvider.future),
      filter: (area, query) => area.descripcion.toLowerCase().contains(query),
      emptyMessage: 'No hay áreas registradas.',
      emptyIcon: Icons.business_outlined,
      countLabel: (count) => '$count área${count == 1 ? '' : 's'} encontrada${count == 1 ? '' : 's'}',
      itemBuilder: (context, area) => CrudListRow(
        avatarText: area.descripcion,
        title: area.descripcion,
        subtitle: 'ID: ${area.idArea}',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => guardar(id: area.idArea, initial: area.descripcion),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Eliminar área',
                message: '¿Eliminar "${area.descripcion}"?',
              );
              if (!confirmed) return;
              if (!context.mounted) return;
              await AppToast.run(
                context,
                action: () async {
                  await api.remove(area.idArea);
                  ref.invalidate(areasListProvider);
                },
                success: 'Área eliminada',
              );
            },
          ),
        ],
      ),
    );
  }
}
