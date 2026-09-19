/// Mapea `esclerosis-back/src/modules/sedes/entities/sede.entity.ts`.
class Sede {
  const Sede({
    required this.idSede,
    required this.nombre,
    this.direccion,
    this.isActive = true,
  });

  final int idSede;
  final String nombre;
  final String? direccion;
  final bool isActive;

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      idSede: (json['idSede'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
