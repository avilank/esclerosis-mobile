/// Mapea `esclerosis-back/src/modules/areas/entities/area.entity.ts`.
class Area {
  const Area({required this.idArea, required this.descripcion, this.isActive = true});

  final int idArea;
  final String descripcion;
  final bool isActive;

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      idArea: (json['idArea'] as num).toInt(),
      descripcion: json['descripcion'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
