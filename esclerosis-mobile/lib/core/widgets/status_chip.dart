import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chip de estado generico (activo/inactivo, grado de enfermedad, etc.).
/// Equivalente visual a `Chip.tsx` / `EstadoSaludTag` de `esclerosis-movil`.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.background,
  });

  factory StatusChip.boolStatus(bool active) {
    return StatusChip(
      label: active ? 'Activo' : 'Inactivo',
      color: active ? AppColors.success : AppColors.muted,
      background: active ? const Color(0xFFDCFCE7) : AppColors.subtle,
    );
  }

  /// Estado de cuenta en listado de usuarios (`UserCard` en esclerosis-movil).
  factory StatusChip.accountStatus(bool active) {
    return StatusChip(
      label: active ? 'Activo' : 'Inactivo',
      color: active ? const Color(0xFF2563EB) : const Color(0xFFB91C1C),
      background: active ? const Color(0xFFE0F2FE) : const Color(0xFFFEE2E2),
    );
  }

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillAll,
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
