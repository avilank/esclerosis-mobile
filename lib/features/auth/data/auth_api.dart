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

  /// `POST /auth/register`. A diferencia de `login`, la respuesta es plana
  /// (`{ id, email, dni, rol, token }`, sin `username`) y el backend siempre
  /// asigna el rol `paciente` a las cuentas creadas por este endpoint (ver
  /// `AuthService.register`). Se conserva el `username` ingresado en el
  /// formulario porque el backend no lo devuelve.
  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );

      final data = response.data;
      final token = data?['token'] as String?;
      if (token == null) {
        throw const ApiException(
          message: 'Respuesta de registro inválida del servidor',
        );
      }

      final usuario = Usuario(
        id: data?['id'] as int? ?? 0,
        email: data?['email'] as String? ?? email,
        username: username,
        rol: data?['rol'] as String? ?? 'paciente',
      );

      return AuthSession(token: token, usuario: usuario);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
