import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema global de la app. Unica fuente de verdad visual: colores, tipografia
/// y estilos de los componentes base (botones, inputs, cards, appbar). Las
/// vistas consumen via `Theme.of(context)` y no redefinen estilos sueltos.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.info,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.card,
      surfaceContainerLow: AppColors.subtle,
      surfaceContainer: AppColors.subtle,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      dividerColor: AppColors.line,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          textStyle: AppTypography.bodyMedium,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          textStyle: AppTypography.bodyMedium,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyMedium,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.lgAll),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.subtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
        labelStyle: AppTypography.body,
        // El manual muestra el label siempre arriba del campo (no flotando
        // adentro al enfocar), por eso se fija `always`.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: AppTypography.label.copyWith(color: AppColors.body),
        // Campos "pill" con relleno gris y sin borde visible en reposo,
        // igual al mockup de login/formularios de `esclerosis-movil`
        // (ver manual de usuario ESCLEROSIS - BI.docx, figuras 6, 12, 13).
        border: const OutlineInputBorder(
          borderRadius: AppRadii.pillAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pillAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pillAll,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pillAll,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pillAll,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.smAll),
      ),

      // Sin esto, `BottomNavigationBar` con mas de 3 items usa el tipo
      // `shifting` por defecto y colores sin marca (se ve "en blanco" al
      // cambiar de tab). `type` tambien se fuerza explicitamente en cada
      // `BottomNavigationBar` de la app, pero se deja aca el resto del estilo
      // para que sea consistente si se usa en otro lado.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        showUnselectedLabels: true,
        elevation: 8,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.line,
      ),
    );
  }
}
