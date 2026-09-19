import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Donut de dominancia (dos segmentos), equivalente a `DominanceChart.tsx`.
class ReportesDominanceChart extends StatelessWidget {
  const ReportesDominanceChart({
    super.key,
    required this.primaryCount,
    required this.secondaryCount,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.size = 160,
  });

  final int primaryCount;
  final int secondaryCount;
  final String primaryLabel;
  final String secondaryLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = primaryCount + secondaryCount;
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Text(
          'No hay datos para mostrar',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      );
    }

    final primaryPct = primaryCount / total * 100;
    final secondaryPct = secondaryCount / total * 100;

    return Column(
      children: [
        SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: size * 0.35,
                  sections: [
                    PieChartSectionData(
                      value: primaryCount.toDouble(),
                      color: const Color(0xFF0EA5E9),
                      radius: size * 0.2,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: secondaryCount.toDouble(),
                      color: const Color(0xFFF59E0B),
                      radius: size * 0.2,
                      title: '',
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total', style: AppTypography.heading2),
                  Text('Recetas', style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Legend(
              color: const Color(0xFF0EA5E9),
              pct: primaryPct,
              label: '$primaryLabel ($primaryCount)',
            ),
            _Legend(
              color: const Color(0xFFF59E0B),
              pct: secondaryPct,
              label: '$secondaryLabel ($secondaryCount)',
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.pct, required this.label});

  final Color color;
  final double pct;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 6),
        Text('${pct.round()}%', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
      ],
    );
  }
}
