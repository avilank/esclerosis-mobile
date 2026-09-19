import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Fondo teal de borde a borde (status bar + esquinas inferiores redondeadas).
/// Evita las franjas blancas laterales que aparecen cuando el `Scaffold` respeta
/// el padding horizontal del sistema y el header no se extiende.
class CurvedTealHeaderShell extends StatelessWidget {
  const CurvedTealHeaderShell({
    super.key,
    required this.child,
    this.bottomRadius = AppRadii.xl,
  });

  final Widget child;
  final double bottomRadius;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        removeTop: true,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(bottomRadius),
            bottomRight: Radius.circular(bottomRadius),
          ),
          child: ColoredBox(
            color: AppColors.primary,
            child: child,
          ),
        ),
      ),
    );
  }
}
