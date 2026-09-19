/// Mapea `esclerosis-back/src/common/enums/indicador-unidad.enum.ts`.
enum IndicadorUnidad {
  numero('numero', 'Número'),
  texto('texto', 'Texto'),
  booleano('booleano', 'Booleano');

  const IndicadorUnidad(this.value, this.label);
  final String value;
  final String label;

  static IndicadorUnidad fromValue(String? value) {
    return IndicadorUnidad.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IndicadorUnidad.numero,
    );
  }
}
