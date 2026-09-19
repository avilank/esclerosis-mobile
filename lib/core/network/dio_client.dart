import 'package:dio/dio.dart';

import '../env/app_env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Construye la instancia de [Dio] de la app, con el [AuthInterceptor] y el
/// `baseUrl` del entorno activo ya configurados.
Dio buildDioClient({
  required TokenStorage tokenStorage,
  required Future<void> Function() onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      // No lanzamos por status >= 400 aca; se mapea a ApiException en el
      // repositorio correspondiente.
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      onSessionExpired: onSessionExpired,
    ),
  );

  if (AppEnv.isDev) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  return dio;
}
