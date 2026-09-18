import 'package:flutter/widgets.dart';

/// Tokens de color de la app. Ajustar cuando exista un design system propio
/// para Esclerosis Mobile; por ahora son valores neutros de arranque.
///
/// No hardcodear colores en las vistas: consumir siempre desde aca o desde el
/// `ColorScheme` del tema (`Theme.of(context).colorScheme`).
abstract final class AppColors {
  const AppColors._();

  // ── Accion ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryHover = Color(0xFF0B5D57);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Texto ────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF111827);
  static const Color body = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);

  // ── Superficie ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF3F4F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color subtle = Color(0xFFF1F5F9);
  static const Color line = Color(0xFFE2E8F0);

  // ── Semantico ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}
