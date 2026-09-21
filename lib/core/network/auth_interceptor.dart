import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Interceptor de autenticacion contra `esclerosis-back`.
///
/// A diferencia de `app-comunicador` (que tiene access+refresh token y
/// reintenta en 401), `esclerosis-back` hoy solo emite un JWT sin endpoint de
/// refresh (`AuthService.login`, sin `/auth/refresh`). Este interceptor:
/// 1. Adjunta `Authorization: Bearer <token>` si hay sesion.
/// 2. Ante un 401, limpia la sesion y notifica para redirigir a login (no hay
///    nada que refrescar).
class AuthInterceptor extends Interceptor {
  // Parametros publicos asignados a campos privados: `required this._campo`
  // (private named parameters) necesita Dart >= 3.12 y el pubspec declara
  // `^3.8.0`, con lo cual la app no compilaba.
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Future<void> Function() onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _onSessionExpired = onSessionExpired;

  final TokenStorage _tokenStorage;
  final Future<void> Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token =
        TokenStorage.cachedToken ?? await _tokenStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthError = err.response?.statusCode == 401;
    final isLoginCall = err.requestOptions.path.contains('/auth/login');

    if (isAuthError && !isLoginCall) {
      await _onSessionExpired();
    }

    handler.next(err);
  }
}
