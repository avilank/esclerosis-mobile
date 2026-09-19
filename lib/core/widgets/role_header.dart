import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'curved_teal_header_shell.dart';

/// Header curvo con fondo teal usado en el dashboard por rol, con stats
/// resumidas a la derecha. Equivalente a `AppHeader` de
/// `esclerosis-movil/src/shared/components/AppHeader/AppHeader.tsx`.
class RoleHeader extends StatelessWidget {
  const RoleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.stats = const [],
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<RoleHeaderStat> stats;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return CurvedTealHeaderShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s5,
          topInset + AppSpacing.s4,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.heading1.copyWith(color: Colors.white),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.body.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                ],
              ),
            ),
            if (stats.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final stat in stats) ...[
                    _StatBadge(stat: stat),
                    const SizedBox(width: AppSpacing.s2),
                  ],
                ],
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class RoleHeaderStat {
  const RoleHeaderStat({required this.label, required this.value});
  final String label;
  final Object value;
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.stat});
  final RoleHeaderStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadii.mdAll,
      ),
      child: Column(
        children: [
          Text(
            '${stat.value}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          Text(
            stat.label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
