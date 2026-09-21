import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validation/password_policy.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/administracion_providers.dart';
import '../domain/rol.dart';
import '../domain/usuario_admin.dart';
import 'simple_field_form_sheet.dart';
import 'usuario_create_screen.dart';

/// Lista de usuarios del sistema, con alta, edicion basica (usuario, correo,
/// estado, rol) y baja. Equivalente a
/// `esclerosis-movil/src/features/administrador/users/screens/ListUsers.tsx`.
class UsuariosListScreen extends ConsumerWidget {
  const UsuariosListScreen({super.key});

  Future<void> _editar(BuildContext context, WidgetRef ref, UsuarioAdmin usuario) async {
    final roles = await ref.read(rolesListProvider.future);
    if (!context.mounted) return;

    Rol? rolSeleccionado;
    for (final r in roles) {
      if (r.idRol == usuario.idRol) {
        rolSeleccionado = r;
        break;
      }
    }

    final data = await showSimpleFormSheet(
      context,
      title: 'Editar usuario',
      fields: [
        SimpleFormField(key: 'username', label: 'Usuario', initialValue: usuario.username),
        SimpleFormField(key: 'email', label: 'Correo electrónico', initialValue: usuario.email),
        SimpleFormField(
          key: 'password',
          label: 'Nueva contraseña (opcional)',
          initialValue: '',
          required: false,
          obscureText: true,
          // Misma politica que el backend: si se deja vacio no se cambia.
          validator: (value) =>
              PasswordPolicy.validate(value, requerida: false),
        ),
      ],
    );
    if (data == null) return;

    final body = <String, dynamic>{
      'username': data['username'],
      'email': data['email'],
      if ((data['password'] ?? '').isNotEmpty) 'password': data['password'],
      if (rolSeleccionado != null) 'idRol': rolSeleccionado.idRol,
    };
    try {
      await ref.read(usuariosApiProvider).update(usuario.idUsuario, body);
      ref.invalidate(usuariosListProvider);
      if (context.mounted) AppToast.success(context, 'Usuario actualizado');
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, UsuarioAdmin usuario) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Confirmar eliminación',
      message: '¿Eliminar al usuario ${usuario.username}?',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await AppToast.run(
      context,
      action: () async {
        await ref.read(usuariosApiProvider).remove(usuario.idUsuario);
        ref.invalidate(usuariosListProvider);
      },
      success: 'Usuario eliminado',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosListProvider);

    return CrudListScaffold<UsuarioAdmin>(
      title: 'Usuarios',
      searchHint: 'Buscar por usuario, correo o rol...',
      async: usuariosAsync,
      onAdd: () async {
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const UsuarioCreateScreen()),
        );
        if (created == true) ref.invalidate(usuariosListProvider);
      },
      onRefresh: () => ref.refresh(usuariosListProvider.future),
      filter: (usuario, query) =>
          usuario.username.toLowerCase().contains(query) ||
          usuario.email.toLowerCase().contains(query) ||
          (usuario.rolNombre ?? '').toLowerCase().contains(query),
      emptyMessage: 'Aún no has registrado usuarios.',
      emptyIcon: Icons.people_outline,
      countLabel: (count) => '$count usuario${count == 1 ? '' : 's'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, usuario) => _UsuarioListRow(
        usuario: usuario,
        onEdit: () => _editar(context, ref, usuario),
        onDelete: () => _eliminar(context, ref, usuario),
      ),
    );
  }
}

class _UsuarioListRow extends StatelessWidget {
  const _UsuarioListRow({
    required this.usuario,
    required this.onEdit,
    required this.onDelete,
  });

  final UsuarioAdmin usuario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rolNombre = usuario.rolNombre ?? 'Sin rol';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InitialsAvatar(text: usuario.username.isNotEmpty ? usuario.username : usuario.email, size: 56),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.username.isNotEmpty ? usuario.username : 'Sin usuario',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.mail_outline, size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usuario.email,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: 4,
                children: [
                  _RoleBadge(label: rolNombre),
                  StatusChip.accountStatus(usuario.estado),
                ],
              ),
            ],
          ),
        ),
        CrudVerticalActions(onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF059669)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: const Color(0xFF059669),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
