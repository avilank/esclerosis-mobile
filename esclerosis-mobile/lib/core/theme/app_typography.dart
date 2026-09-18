import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos de texto de la app.
///
/// Usa la tipografia del sistema (Roboto en Android / San Francisco en iOS)
/// para no depender de `google_fonts` ni de descargar fuentes en runtime.
/// Si mas adelante se define una tipografia de marca, empaquetarla como
/// asset local (ver ejemplo en `app-comunicador/assets/fonts`) y setear
/// [fontFamily] aca.
abstract final class AppTypography {
  const AppTypography._();

  /// `null` = usa la fuente por defecto de la plataforma.
  static const String? fontFamily = null;

  static TextStyle _style(double size, FontWeight weight, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: 1.3,
    );
  }

  static TextStyle get display => _style(32, FontWeight.w600);
  static TextStyle get heading1 => _style(22, FontWeight.w600);
  static TextStyle get heading2 => _style(18, FontWeight.w600);
  static TextStyle get heading3 => _style(16, FontWeight.w600);
  static TextStyle get bodyLarge =>
      _style(16, FontWeight.w400, color: AppColors.body);
  static TextStyle get body => _style(14, FontWeight.w400, color: AppColors.body);
  static TextStyle get bodyMedium =>
      _style(14, FontWeight.w500, color: AppColors.body);
  static TextStyle get label => _style(13, FontWeight.w500);
  static TextStyle get caption =>
      _style(12, FontWeight.w400, color: AppColors.muted);

  static TextTheme get textTheme => TextTheme(
        displayMedium: display,
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        titleMedium: heading3,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        titleSmall: bodyMedium,
        labelLarge: bodyMedium,
        labelMedium: label,
        bodySmall: caption,
      );
}
