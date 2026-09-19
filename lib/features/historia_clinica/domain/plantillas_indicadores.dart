/// Valores de plantilla para indicadores (leve / moderado / severo), alineado
/// a `esclerosis-movil/.../CreateDiagnosticoModal/pruebita.json`.
const Map<String, List<PlantillaIndicadorValor>> kPlantillasIndicadores = {
  'leve': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '1.5'),
    PlantillaIndicadorValor(idIndicador: 2, valor: '4.2'),
    PlantillaIndicadorValor(idIndicador: 3, valor: '19'),
    PlantillaIndicadorValor(idIndicador: 4, valor: '3'),
    PlantillaIndicadorValor(idIndicador: 5, valor: '55'),
    PlantillaIndicadorValor(idIndicador: 6, valor: '48'),
    PlantillaIndicadorValor(idIndicador: 7, valor: '0'),
    PlantillaIndicadorValor(idIndicador: 8, valor: '1'),
  ],
  'moderado': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '3.5'),
    PlantillaIndicadorValor(idIndicador: 2, valor: '6.8'),
    PlantillaIndicadorValor(idIndicador: 3, valor: '27'),
    PlantillaIndicadorValor(idIndicador: 4, valor: '9'),
    PlantillaIndicadorValor(idIndicador: 5, valor: '42'),
    PlantillaIndicadorValor(idIndicador: 6, valor: '35'),
    PlantillaIndicadorValor(idIndicador: 7, valor: '2'),
    PlantillaIndicadorValor(idIndicador: 8, valor: '3'),
  ],
  'severo': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '3.5'),
    PlantillaIndicadorValor(idIndicador: 2, valor: '6.8'),
    PlantillaIndicadorValor(idIndicador: 3, valor: '27'),
    PlantillaIndicadorValor(idIndicador: 4, valor: '9'),
    PlantillaIndicadorValor(idIndicador: 5, valor: '42'),
    PlantillaIndicadorValor(idIndicador: 6, valor: '35'),
    PlantillaIndicadorValor(idIndicador: 7, valor: '2'),
    PlantillaIndicadorValor(idIndicador: 8, valor: '3'),
  ],
};

class PlantillaIndicadorValor {
  const PlantillaIndicadorValor({required this.idIndicador, required this.valor});

  final int idIndicador;
  final String valor;
}
