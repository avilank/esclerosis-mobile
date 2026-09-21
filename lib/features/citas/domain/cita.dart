import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../historia_clinica/domain/medico.dart';
import '../../historia_clinica/domain/paciente.dart';

/// Estados de una cita, espejo de `ESTADOS_CITA` en
/// `esclerosis-back/src/modules/citas/entities/cita.entity.ts`.
enum EstadoCita {
  programada('programada', 'Programada'),
  atendida('atendida', 'Atendida'),
  cancelada('cancelada', 'Cancelada'),
  noAsistio('no_asistio', 'No asistió');

  const EstadoCita(this.value, this.label);

  final String value;
  final String label;

  static EstadoCita fromValue(String? value) {
    return EstadoCita.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoCita.programada,
    );
  }

  /// Color del chip. Cancelada/no asistió en gris y rojo suave, como pide el
  /// tema teal del proyecto.
  Color get color {
    switch (this) {
      case EstadoCita.programada:
        return AppColors.primary;
      case EstadoCita.atendida:
        return AppColors.success;
      case EstadoCita.cancelada:
        return AppColors.muted;
      case EstadoCita.noAsistio:
        return AppColors.danger;
    }
  }

  Color get background {
    switch (this) {
      case EstadoCita.programada:
        return const Color(0xFFE0F2F1);
      case EstadoCita.atendida:
        return const Color(0xFFDCFCE7);
      case EstadoCita.cancelada:
        return const Color(0xFFF1F5F9);
      case EstadoCita.noAsistio:
        return const Color(0xFFFEE2E2);
    }
  }
}

/// Mapea `esclerosis-back/src/modules/citas/entities/cita.entity.ts`.
///
/// `fechaCita` llega como `YYYY-MM-DD` y `horaCita` como `HH:mm` (el backend
/// normaliza la columna `time`, que trae segundos).
class Cita {
  const Cita({
    required this.idCita,
    required this.idPaciente,
    required this.idMedico,
    required this.fechaCita,
    required this.horaCita,
    required this.estado,
    this.idSede,
    this.motivo,
    this.observaciones,
    this.paciente,
    this.medico,
    this.sedeNombre,
    this.idDiagnostico,
  });

  final int idCita;
  final int idPaciente;
  final int idMedico;
  final String fechaCita;
  final String horaCita;
  final EstadoCita estado;
  final int? idSede;
  final String? motivo;
  final String? observaciones;
  final Paciente? paciente;
  final Medico? medico;
  final String? sedeNombre;

  /// Diagnóstico que resultó de atender la cita, si ya se atendió.
  final int? idDiagnostico;

  bool get esProgramada => estado == EstadoCita.programada;

  String get pacienteNombre =>
      paciente?.nombrePaciente ?? 'Paciente #$idPaciente';

  String get medicoNombre => medico?.nombre ?? 'Médico #$idMedico';

  /// `2026-10-05` + `09:00` -> `05/10/2026 09:00`, para mostrar en la lista.
  String get fechaHoraLegible {
    final partes = fechaCita.split('-');
    if (partes.length != 3) return '$fechaCita $horaCita';
    return '${partes[2]}/${partes[1]}/${partes[0]} $horaCita';
  }

  factory Cita.fromJson(Map<String, dynamic> json) {
    final pacienteJson = json['paciente'];
    final medicoJson = json['medico'];
    final sedeJson = json['sede'];
    final diagnosticoJson = json['diagnostico'];

    final hora = json['horaCita'] as String? ?? '';

    return Cita(
      idCita: (json['idCita'] as num?)?.toInt() ?? 0,
      idPaciente: (json['idPaciente'] as num?)?.toInt() ?? 0,
      idMedico: (json['idMedico'] as num?)?.toInt() ?? 0,
      fechaCita: json['fechaCita'] as String? ?? '',
      // Defensivo: si algún día llega 'HH:mm:ss' sin normalizar.
      horaCita: hora.length > 5 ? hora.substring(0, 5) : hora,
      estado: EstadoCita.fromValue(json['estado'] as String?),
      idSede: (json['idSede'] as num?)?.toInt(),
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      paciente: pacienteJson is Map
          ? Paciente.fromJson(Map<String, dynamic>.from(pacienteJson))
          : null,
      medico: medicoJson is Map
          ? Medico.fromJson(Map<String, dynamic>.from(medicoJson))
          : null,
      sedeNombre: sedeJson is Map ? sedeJson['nombre'] as String? : null,
      idDiagnostico: diagnosticoJson is Map
          ? (diagnosticoJson['idDiagnostico'] as num?)?.toInt()
          : null,
    );
  }
}
