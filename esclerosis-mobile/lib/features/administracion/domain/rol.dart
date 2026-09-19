/// Mapea `esclerosis-back/src/modules/auth/roles/entities/role.entity.ts`.
class Rol {
  const Rol({
    required this.idRol,
    required this.nombre,
    this.descripcion,
    this.isActive = true,
  });

  final int idRol;
  final String nombre;
  final String? descripcion;
  final bool isActive;

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      idRol: (json['idRol'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
