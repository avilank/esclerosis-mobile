import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/analytics_models.dart';

class ReportesAttendedList extends StatelessWidget {
  const ReportesAttendedList({super.key, required this.items});

  final List<HechoPacienteAtendido> items;

  static String _fmtFechaId(int? fechaId) {
    if (fechaId == null) return '-';
    final s = fechaId.toString().padLeft(8, '0');
    if (s.length != 8) return s;
    return '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final valid = items.where((e) => e.nombreIndicador != null && e.nombrePaciente != null).toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s3),
        Text('Registros de atención', style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.s2),
        for (final it in valid)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(it.nombreIndicador!, style: AppTypography.body)),
                      Text(_fmtFechaId(it.fechaId), style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(it.nombrePaciente!, style: AppTypography.caption),
                      Text(it.nombreSede ?? '-', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
