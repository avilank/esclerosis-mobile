/// Valor de indicador clinico asociado a un diagnostico
/// (`GET /diagnosticos/:id` → `IndicadoresClinicos`).
class DiagnosticoIndicadorRegistro {
  const DiagnosticoIndicadorRegistro({
    required this.nombre,
    required this.valor,
    this.unidad,
    this.categoria,
    this.fechaMedicion,
  });

  final String nombre;
  final String valor;
  final String? unidad;
  final String? categoria;
  final String? fechaMedicion;

  factory DiagnosticoIndicadorRegistro.fromJson(Map<String, dynamic> json) {
    final indicador = json['indicadorClinico'];
    final indicadorMap = indicador is Map ? Map<String, dynamic>.from(indicador) : null;
    final categoriaRaw = indicadorMap?['categoriaIndicador'];
    final categoriaMap = categoriaRaw is Map ? Map<String, dynamic>.from(categoriaRaw) : null;
    final unidadRaw = indicadorMap?['unidad'];
    return DiagnosticoIndicadorRegistro(
      nombre: indicadorMap?['nombre']?.toString() ?? 'Indicador',
      valor: json['valor']?.toString() ?? '',
      unidad: unidadRaw?.toString(),
      categoria: categoriaMap?['descripcion']?.toString(),
      fechaMedicion: json['fechaMedicion']?.toString(),
    );
  }
}
