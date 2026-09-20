/// Valores de plantilla para indicadores clinicos, por nivel de gravedad.
///
/// Los ids 1..8 son los que siembra `esclerosis-back` en
/// `database/seeds/indicadores-clinicos.seed.ts`, en este orden:
///   1 EDSS, 2 T25FW, 3 9HPT, 4 RM (lesiones), 5 SDMT, 6 PASAT,
///   7 N.º de comorbilidades, 8 N.º de farmacos concomitantes.
///
/// Rangos de referencia usados (ver tabla de variables del documento):
///   EDSS   0-10 en pasos de 0.5  -> >0-3.9 leve | 4.0-6.9 moderado | >=7.0 grave
///   T25FW  segundos (>0)         -> mas alto, peor marcha
///   9HPT   segundos por mano     -> mas alto, peor destreza
///   RM     conteo entero >=0     -> lesiones nuevas/agrandadas en T2
///   SDMT   0-110                 -> mas alto, mejor cognicion
///   PASAT  0-60                  -> mas alto, mejor cognicion
const Map<String, List<PlantillaIndicadorValor>> kPlantillasIndicadores = {
  'leve': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '1.5'), // EDSS leve
    PlantillaIndicadorValor(idIndicador: 2, valor: '4.2'), // T25FW rapido
    PlantillaIndicadorValor(idIndicador: 3, valor: '19'), // 9HPT
    PlantillaIndicadorValor(idIndicador: 4, valor: '3'), // RM: pocas lesiones
    PlantillaIndicadorValor(idIndicador: 5, valor: '55'), // SDMT conservado
    PlantillaIndicadorValor(idIndicador: 6, valor: '48'), // PASAT conservado
    PlantillaIndicadorValor(idIndicador: 7, valor: '0'), // sin comorbilidades
    PlantillaIndicadorValor(idIndicador: 8, valor: '1'), // 1 farmaco
  ],
  'moderado': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '3.5'), // EDSS moderado-bajo
    PlantillaIndicadorValor(idIndicador: 2, valor: '6.8'),
    PlantillaIndicadorValor(idIndicador: 3, valor: '27'),
    PlantillaIndicadorValor(idIndicador: 4, valor: '9'),
    PlantillaIndicadorValor(idIndicador: 5, valor: '42'),
    PlantillaIndicadorValor(idIndicador: 6, valor: '35'),
    PlantillaIndicadorValor(idIndicador: 7, valor: '2'),
    PlantillaIndicadorValor(idIndicador: 8, valor: '3'),
  ],
  // Antes esta plantilla era una copia exacta de 'moderado' (EDSS 3.5), asi que
  // elegir "Severo" cargaba valores de un cuadro moderado.
  'severo': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '6.0'), // EDSS: marcha limitada
    PlantillaIndicadorValor(idIndicador: 2, valor: '9.5'), // T25FW lento
    PlantillaIndicadorValor(idIndicador: 3, valor: '38'), // 9HPT deteriorado
    PlantillaIndicadorValor(idIndicador: 4, valor: '15'), // RM: carga alta
    PlantillaIndicadorValor(idIndicador: 5, valor: '32'), // SDMT bajo
    PlantillaIndicadorValor(idIndicador: 6, valor: '24'), // PASAT bajo
    PlantillaIndicadorValor(idIndicador: 7, valor: '3'), // >=3 comorbilidades
    PlantillaIndicadorValor(idIndicador: 8, valor: '5'), // polifarmacia
  ],
  'crítico': [
    PlantillaIndicadorValor(idIndicador: 1, valor: '8.0'), // EDSS: discapacidad grave
    PlantillaIndicadorValor(idIndicador: 2, valor: '14.0'),
    PlantillaIndicadorValor(idIndicador: 3, valor: '60'),
    PlantillaIndicadorValor(idIndicador: 4, valor: '22'),
    PlantillaIndicadorValor(idIndicador: 5, valor: '22'),
    PlantillaIndicadorValor(idIndicador: 6, valor: '15'),
    PlantillaIndicadorValor(idIndicador: 7, valor: '4'),
    PlantillaIndicadorValor(idIndicador: 8, valor: '10'), // polifarmacia extrema
  ],
};

class PlantillaIndicadorValor {
  const PlantillaIndicadorValor({required this.idIndicador, required this.valor});

  final int idIndicador;
  final String valor;
}
