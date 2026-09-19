import 'diagnostico.dart';
import 'paciente.dart';

/// Mapea `esclerosis-back/src/modules/historias-clinicas/entities/historias-clinica.entity.ts`.
class HistoriaClinica {
  const HistoriaClinica({
    required this.idHistoriaClinica,
    required this.idPaciente,
    required this.estado,
    required this.fechaIngreso,
    this.paciente,
    this.diagnosticos = const [],
  });

  final int idHistoriaClinica;
  final int idPaciente;
  final String estado;
  final String fechaIngreso;
  final Paciente? paciente;
  final List<Diagnostico> diagnosticos;

  factory HistoriaClinica.fromJson(Map<String, dynamic> json) {
    final pacienteRaw = json['paciente'];
    final pacienteJson = pacienteRaw is Map
        ? Map<String, dynamic>.from(pacienteRaw)
        : null;
    final diagnosticosJson = json['diagnosticos'] as List<dynamic>?;
    return HistoriaClinica(
      idHistoriaClinica: (json['idHistoriaClinica'] as num).toInt(),
      idPaciente: (json['idPaciente'] as num).toInt(),
      estado: json['estado']?.toString() ?? '',
      fechaIngreso: json['fechaIngreso']?.toString() ?? '',
      paciente: pacienteJson != null ? Paciente.fromJson(pacienteJson) : null,
      diagnosticos: diagnosticosJson == null
          ? const []
          : diagnosticosJson
              .whereType<Map>()
              .map((e) => Diagnostico.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }
}
