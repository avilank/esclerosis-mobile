/// Mapea `esclerosis-back/src/modules/indicadores-clinicos/entities/categorias-indicadores.entity.ts`.
class CategoriaIndicador {
  const CategoriaIndicador({
    required this.idTipoIndicador,
    required this.descripcion,
    this.bloqueado = false,
    this.isActive = true,
  });

  final int idTipoIndicador;
  final String descripcion;
  final bool bloqueado;
  final bool isActive;

  factory CategoriaIndicador.fromJson(Map<String, dynamic> json) {
    return CategoriaIndicador(
      idTipoIndicador: (json['idTipoIndicador'] as num).toInt(),
      descripcion: json['descripcion'] as String? ?? '',
      bloqueado: json['bloqueado'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
