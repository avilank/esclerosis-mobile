import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../application/administracion_providers.dart';
import '../domain/rol.dart';
import 'rol_permisos_dialog.dart';
import 'simple_field_form_sheet.dart';

/// Listado de roles (permisos por rol desde el dialogo al tocar/editar).
/// Equivalente a `esclerosis-movil/src/features/administrador/roles/screens/ListRole.tsx`.
class RolesPermisosScreen extends ConsumerWidget {
  const RolesPermisosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesListProvider);
    final api = ref.read(rolesApiProvider);

    Future<void> guardar({int? id, Map<String, String>? initial}) async {
      final data = await showSimpleFormSheet(
        context,
        title: id == null ? 'Nuevo rol' : 'Editar rol',
        sectionIcon: Icons.shield_outlined,
        sectionLabel: 'Datos del rol',
        submitLabel: id == null ? 'Crear' : 'Guardar',
        fields: [
          SimpleFormField(key: 'nombre', label: 'Nombre *', initialValue: initial?['nombre']),
          SimpleFormField(
            key: 'descripcion',
            label: 'Descripción',
            initialValue: initial?['descripcion'],
            required: false,
          ),
        ],
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
          ref.invalidate(rolesListProvider);
        },
        success: id == null ? 'Rol creado' : 'Rol actualizado',
      );
    }

    Future<void> eliminar(Rol rol) async {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Confirmar eliminación',
        message: '¿Eliminar el rol "${rol.nombre}"?',
      );
      if (!confirmed) return;
      if (!context.mounted) return;
      await AppToast.run(
        context,
        action: () async {
          await api.remove(rol.idRol);
          ref.invalidate(rolesListProvider);
        },
        success: 'Rol eliminado',
      );
    }

    return CrudListScaffold<Rol>(
      title: 'Roles',
      searchHint: 'Buscar por nombre o descripción...',
      async: rolesAsync,
      onAdd: () => guardar(),
      onRefresh: () => ref.refresh(rolesListProvider.future),
      filter: (rol, query) =>
          rol.nombre.toLowerCase().contains(query) ||
          (rol.descripcion ?? '').toLowerCase().contains(query),
      emptyMessage: 'Aún no has registrado roles.',
      emptyIcon: Icons.shield_outlined,
      countLabel: (count) => '$count rol${count == 1 ? '' : 'es'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, rol) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showRolPermisosDialog(context, ref, rol),
        child: CrudListRow(
          avatarText: rol.nombre,
          title: rol.nombre,
          subtitle: (rol.descripcion ?? '').isNotEmpty ? rol.descripcion : null,
          actions: [
            CrudVerticalActions(
              onEdit: () => guardar(
                id: rol.idRol,
                initial: {'nombre': rol.nombre, 'descripcion': rol.descripcion ?? ''},
              ),
              onDelete: () => eliminar(rol),
            ),
          ],
        ),
      ),
    );
  }
}
