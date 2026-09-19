import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Estado vacio generico para listas. Equivalente a `EmptyState` de
/// `esclerosis-movil/src/components/common/EmptyState`.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.muted, size: 40),
            const SizedBox(height: AppSpacing.s3),
            Text(message, textAlign: TextAlign.center, style: AppTypography.body),
            if (action != null) ...[const SizedBox(height: AppSpacing.s4), action!],
          ],
        ),
      ),
    );
  }
}
