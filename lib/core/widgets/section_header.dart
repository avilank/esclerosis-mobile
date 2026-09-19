import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Encabezado de seccion: titulo + accion opcional a la derecha (p.ej.
/// "Ver todo" o un boton de agregar). Equivalente a `SectionHeader` de
/// `esclerosis-movil/src/shared/ui/SectionHeader.tsx`.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading2),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
