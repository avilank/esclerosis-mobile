import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_toast.dart';
import '../application/administracion_providers.dart';
import '../data/administracion_api.dart';
import '../domain/permiso.dart';
import '../domain/rol.dart';

/// Dialogo para asignar/quitar permisos de un rol. Equivalente a las rutas
/// `permisos/asignar-rol` y `permisos/permisos-roles/*` de
/// `esclerosis-movil` (gestion via `permisos.controller.ts`).
Future<void> showRolPermisosDialog(BuildContext context, WidgetRef ref, Rol rol) async {
  final permisosApi = ref.read(permisosApiProvider);
  final todosLosPermisos = await ref.read(permisosListProvider.future);
  final asignadosIniciales = await permisosApi.permisosPorRol(rol.idRol);

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => _RolPermisosDialog(
      rol: rol,
      permisos: todosLosPermisos,
      asignadosIniciales: asignadosIniciales.toSet(),
      permisosApi: permisosApi,
    ),
  );
}

class _RolPermisosDialog extends StatefulWidget {
  const _RolPermisosDialog({
    required this.rol,
    required this.permisos,
    required this.asignadosIniciales,
    required this.permisosApi,
  });

  final Rol rol;
  final List<Permiso> permisos;
  final Set<int> asignadosIniciales;
  final PermisosApi permisosApi;

  @override
  State<_RolPermisosDialog> createState() => _RolPermisosDialogState();
}

class _RolPermisosDialogState extends State<_RolPermisosDialog> {
  late Set<int> _asignados = {...widget.asignadosIniciales};
  final Set<int> _pending = {};

  Future<void> _toggle(Permiso permiso, bool value) async {
    setState(() => _pending.add(permiso.idPermiso));
    try {
      if (value) {
        await widget.permisosApi.asignarPermisoARol(idRol: widget.rol.idRol, idPermiso: permiso.idPermiso);
      } else {
        await widget.permisosApi.quitarPermisoDeRol(idRol: widget.rol.idRol, idPermiso: permiso.idPermiso);
      }
      setState(() {
        if (value) {
          _asignados.add(permiso.idPermiso);
        } else {
          _asignados.remove(permiso.idPermiso);
        }
      });
      if (mounted) {
        AppToast.success(
          context,
          value ? 'Permiso asignado' : 'Permiso quitado',
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _pending.remove(permiso.idPermiso));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permisos de ${widget.rol.nombre}'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.permisos.isEmpty
            ? const Text('No hay permisos registrados.')
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final permiso in widget.permisos)
                    CheckboxListTile(
                      title: Text(permiso.nombre),
                      subtitle: (permiso.descripcion ?? '').isNotEmpty
                          ? Text(permiso.descripcion!)
                          : null,
                      value: _asignados.contains(permiso.idPermiso),
                      onChanged: _pending.contains(permiso.idPermiso)
                          ? null
                          : (value) => _toggle(permiso, value ?? false),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
