/// Mapea `esclerosis-back/src/modules/tratamientos/entities/tratamiento.entity.ts`.
class Tratamiento {
  const Tratamiento({
    required this.idTratamiento,
    required this.nombre,
    required this.descripcion,
    this.bloqueado = false,
    this.isActive = true,
  });

  final int idTratamiento;
  final String nombre;
  final String descripcion;
  final bool bloqueado;
  final bool isActive;

  factory Tratamiento.fromJson(Map<String, dynamic> json) {
    return Tratamiento(
      idTratamiento: (json['idTratamiento'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      bloqueado: json['bloqueado'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
