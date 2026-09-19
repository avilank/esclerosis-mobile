import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Barras diagnosticados vs atendidos (`ComparisonChart.tsx`).
class ReportesComparisonChart extends StatelessWidget {
  const ReportesComparisonChart({
    super.key,
    required this.diagnosed,
    required this.attended,
  });

  final int diagnosed;
  final int attended;

  @override
  Widget build(BuildContext context) {
    final total = diagnosed + attended;
    final diagPct = total == 0 ? 0.0 : diagnosed / total * 100;
    final attPct = total == 0 ? 0.0 : attended / total * 100;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pacientes: Diagnosticados vs Atendidos',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text('Diagnosticados • $diagnosed', style: AppTypography.caption),
          const SizedBox(height: 6),
          _Bar(pct: diagPct, color: const Color(0xFF06B6D4), bg: const Color(0xFFE6F6FF)),
          const SizedBox(height: AppSpacing.s3),
          Text('Atendidos • $attended', style: AppTypography.caption),
          const SizedBox(height: 6),
          _Bar(pct: attPct, color: const Color(0xFFF59E0B), bg: const Color(0xFFFFF7ED)),
          const SizedBox(height: AppSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${diagPct.round()}%', style: AppTypography.caption),
              Text('${attPct.round()}%', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.pct, required this.color, required this.bg});

  final double pct;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final widthFactor = (pct / 100).clamp(0.06, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 14,
        child: ColoredBox(
          color: bg,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ),
    );
  }
}
