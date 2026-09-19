import 'package:flutter/widgets.dart';

/// Tokens de color de la app, alineados a la paleta "SCLERK" de
/// `esclerosis-movil` (ver
/// `esclerosis-movil/src/shared/constants/colors.ts` y
/// `esclerosis-movil/src/styles/theme.ts`): teal como color de marca.
///
/// No hardcodear colores en las vistas: consumir siempre desde aca o desde el
/// `ColorScheme` del tema (`Theme.of(context).colorScheme`).
abstract final class AppColors {
  const AppColors._();

  // ── Accion (teal QuickCare) ─────────────────────────────────────────────
  static const Color primary = Color(0xFF0D9488); // teal-600
  static const Color primaryHover = Color(0xFF0F766E); // teal-700
  static const Color primaryLight = Color(0xFF99F6E4); // teal-100
  static const Color secondary = Color(0xFFCCFBF1); // teal-50
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Texto ────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF0F172A);
  static const Color body = Color(0xFF475569);
  static const Color muted = Color(0xFF64748B);

  // ── Superficie ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color subtle = Color(0xFFF1F5F9);
  static const Color line = Color(0xFFE2E8F0);

  // ── Semantico ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
}
