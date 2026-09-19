import 'indicador_unidad.dart';

/// Mapea `esclerosis-back/src/modules/indicadores-clinicos/entities/indicadores-clinicos.entity.ts`.
class IndicadorClinico {
  const IndicadorClinico({
    required this.idIndicador,
    required this.nombre,
    required this.descripcion,
    required this.unidad,
    this.idCategoriaIndicador,
    this.categoriaDescripcion,
    this.bloqueado = false,
    this.isActive = true,
  });

  final int idIndicador;
  final String nombre;
  final String descripcion;
  final IndicadorUnidad unidad;
  final int? idCategoriaIndicador;
  final String? categoriaDescripcion;
  final bool bloqueado;
  final bool isActive;

  factory IndicadorClinico.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoriaIndicador'] as Map<String, dynamic>?;
    return IndicadorClinico(
      idIndicador: (json['idIndicador'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      unidad: IndicadorUnidad.fromValue(json['unidad'] as String?),
      idCategoriaIndicador: (categoria?['idTipoIndicador'] as num?)?.toInt() ??
          (json['idCategoriaIndicador'] as num?)?.toInt(),
      categoriaDescripcion: categoria?['descripcion'] as String?,
      bloqueado: json['bloqueado'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
