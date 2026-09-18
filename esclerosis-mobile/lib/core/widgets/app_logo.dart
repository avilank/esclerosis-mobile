import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder del logo de marca. Reemplazar por el asset real (SVG/PNG)
/// cuando exista el design system de Esclerosis Mobile.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: Text(
        'E',
        style: TextStyle(
          color: AppColors.onPrimary,
          fontSize: size / 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
