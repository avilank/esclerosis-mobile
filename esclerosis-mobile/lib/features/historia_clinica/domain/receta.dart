import 'tratamiento.dart';

/// Mapea `esclerosis-back/src/modules/recetas/entities/receta.entity.ts`.
class Receta {
  const Receta({
    required this.idReceta,
    required this.fechaReceta,
    this.contenido,
    this.sustentacion,
    this.tratamiento,
  });

  final int idReceta;
  final String fechaReceta;
  final String? contenido;
  final String? sustentacion;
  final Tratamiento? tratamiento;

  factory Receta.fromJson(Map<String, dynamic> json) {
    final tratamientoJson = json['tratamiento'] as Map<String, dynamic>?;
    return Receta(
      idReceta: (json['idReceta'] as num?)?.toInt() ?? 0,
      fechaReceta: json['fechaReceta'] as String? ?? '',
      contenido: json['contenido'] as String?,
      sustentacion: json['sustentacion'] as String?,
      tratamiento:
          tratamientoJson != null ? Tratamiento.fromJson(tratamientoJson) : null,
    );
  }
}
