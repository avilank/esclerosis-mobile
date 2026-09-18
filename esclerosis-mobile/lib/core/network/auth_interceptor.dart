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
  AuthInterceptor({
    required this._tokenStorage,
    required this._onSessionExpired,
  });

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
