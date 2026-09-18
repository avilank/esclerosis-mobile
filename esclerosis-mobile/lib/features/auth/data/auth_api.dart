import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import '../domain/usuario.dart';

/// Llamadas HTTP crudas contra `POST /api/auth/login` de esclerosis-back
/// (ver `esclerosis-back/src/modules/auth/authentication/controllers/authentication.controller.ts`).
///
/// Respuesta esperada: `{ token: string, user: { id, email, username, rol } }`.
/// Sin envelope `{ success, data }` ni refresh token (a diferencia de
/// comunicador-services).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      final token = data?['token'] as String?;
      final userJson = data?['user'] as Map<String, dynamic>?;
      if (token == null || userJson == null) {
        throw const ApiException(
          message: 'Respuesta de login inválida del servidor',
        );
      }

      return AuthSession(token: token, usuario: Usuario.fromJson(userJson));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
