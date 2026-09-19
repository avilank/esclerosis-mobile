import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/diagnostico.dart';

/// Etiqueta compacta de estado de salud (crítico en rojo, resto en verde).
class EstadoSaludTag extends StatelessWidget {
  const EstadoSaludTag({super.key, required this.diagnostico});

  final Diagnostico diagnostico;

  @override
  Widget build(BuildContext context) {
    final color = diagnostico.esCritico ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillAll,
      ),
      child: Text(
        diagnostico.estadoSalud,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
