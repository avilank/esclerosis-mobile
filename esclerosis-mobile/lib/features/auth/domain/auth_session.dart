import 'usuario.dart';

/// Sesion activa: token JWT + datos del usuario logueado.
class AuthSession {
  const AuthSession({required this.token, required this.usuario});

  final String token;
  final Usuario usuario;
}
