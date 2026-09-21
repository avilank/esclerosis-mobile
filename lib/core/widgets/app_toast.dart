import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppToastKind { success, error, info, warning }

/// Toast flotante, corto y reutilizable para confirmar o fallar una acción.
///
/// Vive sobre el [ScaffoldMessenger] de [MaterialApp], así que sobrevive a
/// `Navigator.pop` de formularios y diálogos. No usa paquetes extra.
abstract final class AppToast {
  const AppToast._();

  static const Duration _successDuration = Duration(milliseconds: 2200);
  static const Duration _infoDuration = Duration(milliseconds: 2800);
  static const Duration _errorDuration = Duration(milliseconds: 3800);

  static const Map<String, String> _mensajesConocidos = {
    'Unauthorized': 'Correo o contraseña incorrectos',
    'Forbidden': 'No tienes permiso para esta acción',
    'Not Found': 'No se encontró lo que buscabas',
    'Bad Request': 'Revisa los datos e inténtalo de nuevo',
    'Conflict': 'Ese registro ya existe',
    'Internal Server Error': 'Error del servidor. Inténtalo de nuevo',
  };

  static void success(BuildContext context, String message) {
    show(context, message: message, kind: AppToastKind.success);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, kind: AppToastKind.info);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, kind: AppToastKind.warning);
  }

  static void error(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    show(
      context,
      message: messageOf(error, fallback: fallback),
      kind: AppToastKind.error,
    );
  }

  /// Ejecuta [action] y muestra toast de éxito o de error. Devuelve si salió bien.
  static Future<bool> run(
    BuildContext context, {
    required Future<void> Function() action,
    required String success,
  }) async {
    try {
      await action();
      if (context.mounted) AppToast.success(context, success);
      return true;
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
      return false;
    }
  }

  static String messageOf(Object error, {String? fallback}) {
    var raw = switch (error) {
      ApiException e => e.message,
      DioException e => ApiException.fromDio(e).message,
      _ => error.toString(),
    };
    raw = raw.trim().replaceFirst(
          RegExp(r'^(Exception|ApiException|DioException):\s*'),
          '',
        );
    if (raw.isEmpty) {
      return fallback ?? 'No se pudo completar la acción';
    }
    return _mensajesConocidos[raw] ?? raw;
  }

  static void show(
    BuildContext context, {
    required String message,
    AppToastKind kind = AppToastKind.info,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            0,
            AppSpacing.s4,
            AppSpacing.s5,
          ),
          duration: switch (kind) {
            AppToastKind.success => _successDuration,
            AppToastKind.error => _errorDuration,
            AppToastKind.info || AppToastKind.warning => _infoDuration,
          },
          clipBehavior: Clip.none,
          content: _AppToastCard(message: trimmed, kind: kind),
        ),
      );
  }
}

class _AppToastCard extends StatelessWidget {
  const _AppToastCard({required this.message, required this.kind});

  final String message;
  final AppToastKind kind;

  @override
  Widget build(BuildContext context) {
    final accent = switch (kind) {
      AppToastKind.success => AppColors.success,
      AppToastKind.error => AppColors.danger,
      AppToastKind.warning => AppColors.warning,
      AppToastKind.info => AppColors.info,
    };
    final icon = switch (kind) {
      AppToastKind.success => Icons.check_circle_outline,
      AppToastKind.error => Icons.error_outline,
      AppToastKind.warning => Icons.warning_amber_outlined,
      AppToastKind.info => Icons.info_outline,
    };

    return Material(
      color: AppColors.card,
      elevation: 0,
      borderRadius: AppRadii.mdAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
