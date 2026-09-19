import '../../historia_clinica/domain/receta.dart';

/// Modelos del data warehouse (`esclerosisd`) usados en Reportes.

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

class DimMedicoAnalytics {
  const DimMedicoAnalytics({required this.medicoId, required this.nombre, this.area});

  final int medicoId;
  final String nombre;
  final String? area;

  factory DimMedicoAnalytics.fromJson(Map<String, dynamic> json) {
    return DimMedicoAnalytics(
      medicoId: (json['medicoId'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      area: json['area'] as String?,
    );
  }
}

class DimOrganizacionAnalytics {
  const DimOrganizacionAnalytics({
    required this.organizacionId,
    required this.nombreSede,
    this.direccion,
  });

  final int organizacionId;
  final String nombreSede;
  final String? direccion;

  factory DimOrganizacionAnalytics.fromJson(Map<String, dynamic> json) {
    return DimOrganizacionAnalytics(
      organizacionId: (json['organizacionId'] as num?)?.toInt() ?? 0,
      nombreSede: json['nombreSede'] as String? ?? '',
      direccion: json['direccion'] as String?,
    );
  }
}

class DimModeloIa {
  const DimModeloIa({required this.modeloId, required this.nombreModelo});

  final int modeloId;
  final String nombreModelo;

  factory DimModeloIa.fromJson(Map<String, dynamic> json) {
    return DimModeloIa(
      modeloId: (json['modeloId'] as num?)?.toInt() ?? 0,
      nombreModelo: json['nombreModelo'] as String? ?? '',
    );
  }
}

class DimTiempoAnalytics {
  const DimTiempoAnalytics({required this.fechaId});

  final int fechaId;

  factory DimTiempoAnalytics.fromJson(Map<String, dynamic> json) {
    return DimTiempoAnalytics(fechaId: (json['fechaId'] as num?)?.toInt() ?? 0);
  }
}

class DimPacienteAnalytics {
  const DimPacienteAnalytics({
    required this.pacienteId,
    required this.nombre,
    this.numDocumento,
  });

  final int pacienteId;
  final String nombre;
  final String? numDocumento;

  factory DimPacienteAnalytics.fromJson(Map<String, dynamic> json) {
    return DimPacienteAnalytics(
      pacienteId: (json['pacienteId'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      numDocumento: json['numDocumento'] as String?,
    );
  }
}

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

class HechoRecetaAnalytics {
  const HechoRecetaAnalytics({
    required this.hechoRecetaId,
    this.medicoId,
    this.organizacionId,
    this.fechaId,
    this.cantidadCopilot = 0,
    this.cantidadDeepseek = 0,
  });

  final int hechoRecetaId;
  final int? medicoId;
  final int? organizacionId;
  final int? fechaId;
  final int cantidadCopilot;
  final int cantidadDeepseek;

  factory HechoRecetaAnalytics.fromJson(Map<String, dynamic> json) {
    final medico = json['medico'];
    final org = json['organizacion'];
    final tiempo = json['tiempo'];
    return HechoRecetaAnalytics(
      hechoRecetaId: (json['hechoRecetaId'] as num?)?.toInt() ?? 0,
      medicoId: medico is Map ? (medico['medicoId'] as num?)?.toInt() : null,
      organizacionId: org is Map ? (org['organizacionId'] as num?)?.toInt() : null,
      fechaId: tiempo is Map ? (tiempo['fechaId'] as num?)?.toInt() : null,
      cantidadCopilot: (json['cantidadRecetasGeneradasCopilot'] as num?)?.toInt() ?? 0,
      cantidadDeepseek: (json['cantidadRecetasGeneradasDeepseek'] as num?)?.toInt() ?? 0,
    );
  }
}

class HechoPacienteEm {
  const HechoPacienteEm({
    required this.hechoPacienteEmId,
    this.nombreModelo,
    this.medicoId,
    this.organizacionId,
    this.nombreIndicador,
    this.cantidad = 0,
  });

  final int hechoPacienteEmId;
  final String? nombreModelo;
  final int? medicoId;
  final int? organizacionId;
  final String? nombreIndicador;
  final int cantidad;

  factory HechoPacienteEm.fromJson(Map<String, dynamic> json) {
    final modelo = json['modelo'];
    final medico = json['medico'];
    final org = json['organizacion'];
    final indicador = json['indicador'];
    return HechoPacienteEm(
      hechoPacienteEmId: (json['hechoPacienteEmId'] as num?)?.toInt() ?? 0,
      nombreModelo: modelo is Map ? modelo['nombreModelo']?.toString() : null,
      medicoId: medico is Map ? (medico['medicoId'] as num?)?.toInt() : null,
      organizacionId: org is Map ? (org['organizacionId'] as num?)?.toInt() : null,
      nombreIndicador: indicador is Map ? indicador['nombreIndicador']?.toString() : null,
      cantidad: (json['cantidadPacientesDiagnosticadosEm'] as num?)?.toInt() ?? 0,
    );
  }
}

class HechoPacienteAtendido {
  const HechoPacienteAtendido({
    required this.hechoPacienteAtendidoId,
    this.nombreIndicador,
    this.nombrePaciente,
    this.nombreSede,
    this.fechaId,
    this.cantidad = 0,
  });

  final int hechoPacienteAtendidoId;
  final String? nombreIndicador;
  final String? nombrePaciente;
  final String? nombreSede;
  final int? fechaId;
  final int cantidad;

  factory HechoPacienteAtendido.fromJson(Map<String, dynamic> json) {
    final indicador = json['indicador'];
    final paciente = json['paciente'];
    final org = json['organizacion'];
    final tiempo = json['tiempo'];
    return HechoPacienteAtendido(
      hechoPacienteAtendidoId: (json['hechoPacienteAtendidoId'] as num?)?.toInt() ?? 0,
      nombreIndicador: indicador is Map ? indicador['nombreIndicador']?.toString() : null,
      nombrePaciente: paciente is Map ? paciente['nombre']?.toString() : null,
      nombreSede: org is Map ? org['nombreSede']?.toString() : null,
      fechaId: tiempo is Map ? (tiempo['fechaId'] as num?)?.toInt() : null,
      cantidad: (json['cantidadPacientesAtendidos'] as num?)?.toInt() ?? 0,
    );
  }
}

class PuntoIndicador {
  const PuntoIndicador({required this.fechaId, required this.value});
  final int fechaId;
  final double value;
}

class ReportesAnalyticsData {
  const ReportesAnalyticsData({
    required this.hechosIndicadores,
    required this.indicadores,
    required this.medicos,
    required this.organizaciones,
    required this.modelos,
    required this.hechosRecetas,
    required this.hechosPacientesEm,
    required this.hechosPacientesAtendidos,
    required this.recetasTransaccionales,
  });

  final List<HechoIndicador> hechosIndicadores;
  final List<DimIndicadorClinico> indicadores;
  final List<DimMedicoAnalytics> medicos;
  final List<DimOrganizacionAnalytics> organizaciones;
  final List<DimModeloIa> modelos;
  final List<HechoRecetaAnalytics> hechosRecetas;
  final List<HechoPacienteEm> hechosPacientesEm;
  final List<HechoPacienteAtendido> hechosPacientesAtendidos;
  final List<Receta> recetasTransaccionales;
}
