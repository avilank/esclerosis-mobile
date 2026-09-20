import 'package:flutter/foundation.dart';

/// Configuracion de entorno, inyectada en compilacion con
/// `--dart-define-from-file=env/dev.json` (o `env/prod.json`).
///
/// Los valores se leen con [String.fromEnvironment], por lo que quedan
/// embebidos en el binario (no se leen de disco en runtime).
class AppEnv {
  const AppEnv._();

  /// URL base del backend (esclerosis-back), incluyendo el prefijo `/api`.
  ///
  /// Emulador Android: `http://10.0.2.2:3000/api` (alias del localhost de la
  /// PC). Escritorio / iOS / web: `http://127.0.0.1:3000/api`.
  /// Dispositivo fisico en la misma red: pasar la IP LAN con
  /// `--dart-define=API_BASE_URL=http://192.168.1.51:3000/api`.
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    final fromEnv = _apiBaseUrlFromEnv;
    final resolved = fromEnv.isNotEmpty
        ? fromEnv
        : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:3000/api'
            : 'http://127.0.0.1:3000/api');

    // `10.0.2.2` solo existe dentro del emulador Android.
    if (defaultTargetPlatform != TargetPlatform.android &&
        resolved.contains('10.0.2.2')) {
      return resolved.replaceFirst('10.0.2.2', '127.0.0.1');
    }
    return resolved;
  }

  /// Nombre del entorno activo (dev | staging | prod).
  static const String envName = String.fromEnvironment(
    'ENV_NAME',
    defaultValue: 'dev',
  );

  static bool get isDev => envName == 'dev';
}
