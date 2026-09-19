import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Estado de error generico, con boton opcional de reintentar. Equivalente a
/// `ErrorView` de `esclerosis-movil/src/shared/components/ErrorView.tsx`.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: AppSpacing.s3),
            Text(message, textAlign: TextAlign.center, style: AppTypography.body),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s4),
              OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
