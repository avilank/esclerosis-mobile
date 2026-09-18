/// Usuario autenticado. Mapea el `payload` que `esclerosis-back` devuelve en
/// `AuthService.login` (`{ id, email, username, rol }`).
class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.username,
    required this.rol,
  });

  final int id;
  final String email;
  final String username;
  final String rol;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }
}
