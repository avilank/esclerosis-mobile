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

  /// `unidad` en BD suele ser tipo de dato (numero/texto/booleano), no "kg" o "%".
  static bool esTipoDeDato(String? unidad) {
    if (unidad == null || unidad.trim().isEmpty) return true;
    return IndicadorUnidad.values.any((e) => e.value == unidad.trim());
  }

  static String valorParaMostrar(String valor, String? unidad) {
    final u = unidad?.trim();
    if (u == null || u.isEmpty || esTipoDeDato(u)) return valor;
    return '$valor $u';
  }
}
