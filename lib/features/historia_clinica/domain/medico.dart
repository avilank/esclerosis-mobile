/// Mapea `esclerosis-back/src/modules/medicos/entities/medico.entity.ts`.
///
/// `idMedico` es el mismo id que `idUsuario` (relacion 1:1), asi que el `id`
/// del [Usuario] logueado sirve directo como `idMedico`.
class Medico {
  const Medico({
    required this.idMedico,
    required this.nombre,
    required this.genero,
    this.isActive = true,
    this.areaDescripcion,
    this.sedeNombre,
  });

  final int idMedico;
  final String nombre;
  final String genero;
  final bool isActive;
  final String? areaDescripcion;
  final String? sedeNombre;

  factory Medico.fromJson(Map<String, dynamic> json) {
    final area = json['area'] as Map<String, dynamic>?;
    final sede = json['sede'] as Map<String, dynamic>?;
    return Medico(
      idMedico: (json['idMedico'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      genero: json['genero'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      areaDescripcion: area?['descripcion'] as String?,
      sedeNombre: sede?['nombre'] as String?,
    );
  }
}
