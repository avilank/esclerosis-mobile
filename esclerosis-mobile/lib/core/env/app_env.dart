/// Configuracion de entorno, inyectada en compilacion con
/// `--dart-define-from-file=env/dev.json` (o `env/prod.json`).
///
/// Los valores se leen con [String.fromEnvironment], por lo que quedan
/// embebidos en el binario (no se leen de disco en runtime).
class AppEnv {
  const AppEnv._();

  /// URL base del backend (esclerosis-back), incluyendo el prefijo `/api`.
  ///
  /// Emulador Android: `http://10.0.2.2:3000/api` (esclerosis-back corre en
  /// el puerto 3000, ver `esclerosis-back/src/main.ts`).
  /// Dispositivo fisico en la misma red: usar la IP LAN de la maquina que
  /// corre el backend, ej. `http://192.168.1.51:3000/api`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Nombre del entorno activo (dev | staging | prod).
  static const String envName = String.fromEnvironment(
    'ENV_NAME',
    defaultValue: 'dev',
  );

  static bool get isDev => envName == 'dev';
}
