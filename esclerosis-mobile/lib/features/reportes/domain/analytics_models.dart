/// Dimension de indicador clinico del data warehouse (`DimIndicadoresClinicos`).
/// Ver `esclerosis-back/src/entities/esclerosisd/dim-indicador.entity.ts`.
class DimIndicadorClinico {
  const DimIndicadorClinico({
    required this.indicadorId,
    required this.nombreIndicador,
    this.categoriaIndicador,
    this.valorIndicador,
  });

  final int indicadorId;
  final String nombreIndicador;
  final String? categoriaIndicador;
  final double? valorIndicador;

  factory DimIndicadorClinico.fromJson(Map<String, dynamic> json) {
    return DimIndicadorClinico(
      indicadorId: (json['indicadorId'] as num?)?.toInt() ?? 0,
      nombreIndicador: json['nombreIndicador'] as String? ?? '',
      categoriaIndicador: json['categoriaIndicador'] as String?,
      valorIndicador: (json['valorIndicador'] as num?)?.toDouble(),
    );
  }
}

/// Hecho de indicadores del data warehouse (`HechoIndicador`).
/// Ver `esclerosis-back/src/entities/esclerosisd/hechos/hecho-indicador.entity.ts`.
class HechoIndicador {
  const HechoIndicador({
    required this.hechoIndicadorId,
    this.indicador,
    this.pacienteId,
    this.fechaId,
    this.valorPromedioIndicador,
    this.valorInicialIndicador,
  });

  final int hechoIndicadorId;
  final DimIndicadorClinico? indicador;
  final int? pacienteId;
  final int? fechaId;
  final double? valorPromedioIndicador;
  final double? valorInicialIndicador;

  factory HechoIndicador.fromJson(Map<String, dynamic> json) {
    final indicadorJson = json['indicador'];
    final pacienteJson = json['paciente'];
    final tiempoJson = json['tiempo'];
    return HechoIndicador(
      hechoIndicadorId: (json['hechoIndicadorId'] as num?)?.toInt() ?? 0,
      indicador: indicadorJson is Map
          ? DimIndicadorClinico.fromJson(Map<String, dynamic>.from(indicadorJson))
          : null,
      pacienteId: pacienteJson is Map ? (pacienteJson['pacienteId'] as num?)?.toInt() : null,
      fechaId: tiempoJson is Map ? (tiempoJson['fechaId'] as num?)?.toInt() : null,
      valorPromedioIndicador: (json['valorPromedioIndicador'] as num?)?.toDouble() ??
          (indicadorJson is Map ? (indicadorJson['valorIndicador'] as num?)?.toDouble() : null),
      valorInicialIndicador: (json['valorInicialIndicador'] as num?)?.toDouble(),
    );
  }
}

/// Punto de la serie temporal usada por el grafico de evolucion.
class PuntoIndicador {
  const PuntoIndicador({required this.fechaId, required this.value});
  final int fechaId;
  final double value;
}
