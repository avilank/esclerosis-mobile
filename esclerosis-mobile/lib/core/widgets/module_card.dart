import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tarjeta de modulo navegable del dashboard (p.ej. "Historia Clinica",
/// "Diagnosticos"). Equivalente a `AdminModuleCard` / `MedicoActionCard` /
/// `PacienteActionCard` de `esclerosis-movil/src/features/dashboard`.
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconBackground = AppColors.secondary,
    this.iconColor = AppColors.primary,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadii.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBackground, borderRadius: AppRadii.mdAll),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading3),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
