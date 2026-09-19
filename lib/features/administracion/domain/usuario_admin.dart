/// Usuario visto desde el panel de administracion. Mapea
/// `esclerosis-back/src/modules/usuarios/entities/usuario.entity.ts`
/// (incluye el nombre del rol si el backend lo devuelve con la relacion
/// cargada).
class UsuarioAdmin {
  const UsuarioAdmin({
    required this.idUsuario,
    required this.username,
    required this.email,
    required this.estado,
    this.idRol,
    this.rolNombre,
  });

  final int idUsuario;
  final String username;
  final String email;
  final bool estado;
  final int? idRol;
  final String? rolNombre;

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) {
    final rol = json['rol'] as Map<String, dynamic>?;
    return UsuarioAdmin(
      idUsuario: (json['idUsuario'] as num).toInt(),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      estado: json['estado'] as bool? ?? true,
      idRol: (json['idRol'] as num?)?.toInt() ?? (rol?['idRol'] as num?)?.toInt(),
      rolNombre: rol?['nombre'] as String?,
    );
  }
}
