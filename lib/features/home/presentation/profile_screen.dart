import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_version_label.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/curved_teal_header_shell.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/usuario.dart';

/// Perfil del usuario logueado + cerrar sesion. Equivalente a
/// `esclerosis-movil/src/app/(tabs)/profile.tsx`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).value;
    if (usuario == null) return const SizedBox.shrink();

    final rolLabel = _rolLabel(usuario.rol);
    final initial = usuario.username.isNotEmpty
        ? usuario.username[0].toUpperCase()
        : (usuario.email.isNotEmpty ? usuario.email[0].toUpperCase() : '?');
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CurvedTealHeaderShell(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s5,
                topInset + AppSpacing.s4,
                AppSpacing.s5,
                AppSpacing.s8,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: AppTypography.heading1.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    usuario.username.isNotEmpty ? usuario.username : usuario.email,
                    style: AppTypography.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    rolLabel,
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -AppSpacing.s6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s5),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppRadii.xlAll,
                      border: Border.all(color: AppColors.subtle),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu cuenta',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        _ProfileInfoRow(
                          icon: Icons.mail_outline,
                          label: 'Correo electrónico',
                          value: usuario.email,
                        ),
                        const Divider(height: AppSpacing.s6),
                        _ProfileInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Rol',
                          value: rolLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Material(
                    color: AppColors.card,
                    borderRadius: AppRadii.lgAll,
                    child: InkWell(
                      borderRadius: AppRadii.lgAll,
                      onTap: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Cerrar sesión',
                          message: '¿Seguro que deseas cerrar sesión?',
                          confirmLabel: 'Cerrar sesión',
                        );
                        if (confirmed) {
                          if (context.mounted) {
                            AppToast.success(context, 'Sesión cerrada');
                          }
                          await ref.read(authControllerProvider.notifier).logout();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.lgAll,
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: AppColors.danger, size: 20),
                            SizedBox(width: AppSpacing.s2),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  const Center(child: AppVersionLabel()),
                  const SizedBox(height: AppSpacing.s6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rolLabel(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'medico':
        return 'Médico';
      case 'paciente':
        return 'Paciente';
      default:
        return rol;
    }
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ayuda para mostrar iniciales/roles desde otras pantallas si hiciera falta.
extension UsuarioLabel on Usuario {
  String get rolLabel {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'medico':
        return 'Médico';
      case 'paciente':
        return 'Paciente';
      default:
        return rol;
    }
  }
}
