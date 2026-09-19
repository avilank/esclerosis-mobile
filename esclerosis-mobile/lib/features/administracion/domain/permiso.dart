/// Mapea `esclerosis-back/src/modules/auth/permisos/entities/permiso.entity.ts`.
class Permiso {
  const Permiso({required this.idPermiso, required this.nombre, this.descripcion});

  final int idPermiso;
  final String nombre;
  final String? descripcion;

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
      idPermiso: (json['idPermiso'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
    );
  }
}
