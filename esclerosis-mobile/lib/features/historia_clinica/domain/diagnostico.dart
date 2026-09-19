import 'medico.dart';
import 'receta.dart';

/// Mapea `esclerosis-back/src/modules/diagnosticos/entities/diagnostico.entity.ts`.
///
/// `recetas` viene vacio en los listados que no piden el detalle completo
/// (ver `HistoriasClinicasService.findByPaciente`); para el detalle con
/// recetas/tratamiento hay que pedir `GET /diagnosticos/:id`.
class Diagnostico {
  const Diagnostico({
    required this.idDiagnostico,
    required this.fechaDiagnostico,
    required this.estadoSalud,
    required this.gradoEnfermedad,
    this.observaciones,
    required this.esDiagnosticoInicial,
    this.medico,
    this.recetas = const [],
    this.idHistoriaClinica,
    this.idMedico,
  });

  final int idDiagnostico;
  final String fechaDiagnostico;
  final String estadoSalud;
  final String gradoEnfermedad;
  final String? observaciones;
  final bool esDiagnosticoInicial;
  final Medico? medico;
  final List<Receta> recetas;
  final int? idHistoriaClinica;
  final int? idMedico;

  bool get esCritico => estadoSalud.toLowerCase() == 'crítico' ||
      estadoSalud.toLowerCase() == 'critico';

  factory Diagnostico.fromJson(Map<String, dynamic> json) {
    final medicoJson = json['medico'] as Map<String, dynamic>?;
    final recetasJson = json['recetas'] as List<dynamic>?;
    return Diagnostico(
      idDiagnostico: json['idDiagnostico'] as int,
      fechaDiagnostico: json['fechaDiagnostico'] as String? ?? '',
      estadoSalud: json['estadoSalud'] as String? ?? '',
      gradoEnfermedad: json['gradoEnfermedad'] as String? ?? '',
      observaciones: json['observaciones'] as String?,
      esDiagnosticoInicial: json['es_diagnostico_inicial'] as bool? ?? false,
      medico: medicoJson != null ? Medico.fromJson(medicoJson) : null,
      recetas: recetasJson == null
          ? const []
          : recetasJson
              .map((e) => Receta.fromJson(e as Map<String, dynamic>))
              .toList(),
      idHistoriaClinica: (json['idhistoriaClinica'] as num?)?.toInt(),
      idMedico: (json['idMedico'] as num?)?.toInt() ?? medicoJson?['idMedico'] as int?,
    );
  }
}
