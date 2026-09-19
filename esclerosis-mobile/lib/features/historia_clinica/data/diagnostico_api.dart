import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/diagnostico.dart';

/// Llamadas HTTP contra `/api/diagnosticos` de esclerosis-back (ver
/// `esclerosis-back/src/modules/diagnosticos/controllers/diagnosticos.controller.ts`).
class DiagnosticoApi {
  DiagnosticoApi(this._dio);

  final Dio _dio;

  /// Detalle completo de un diagnostico, con recetas + tratamiento (los
  /// listados de historia clinica no traen esa relacion).
  Future<Diagnostico> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/diagnosticos/$id');
      return Diagnostico.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Diagnosticos realizados por el medico logueado (`idMedico` = `Usuario.id`).
  Future<List<Diagnostico>> getByMedico(int idMedico) async {
    try {
      final response = await _dio.get<List<dynamic>>('/diagnosticos/medico/$idMedico');
      final data = response.data ?? const [];
      return data.whereType<Map>().map((e) => Diagnostico.fromJson(e.cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Diagnostico> create({
    required int idHistoriaClinica,
    required int idMedico,
    required DateTime fechaDiagnostico,
    required String estadoSalud,
    required String gradoEnfermedad,
    String? observaciones,
    bool esDiagnosticoInicial = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/diagnosticos',
        data: {
          'idhistoriaClinica': idHistoriaClinica,
          'idMedico': idMedico,
          'fechaDiagnostico': fechaDiagnostico.toIso8601String(),
          'estadoSalud': estadoSalud,
          'gradoEnfermedad': gradoEnfermedad,
          if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
          'es_diagnostico_inicial': esDiagnosticoInicial,
        },
      );
      return Diagnostico.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Diagnostico> update(
    int id, {
    DateTime? fechaDiagnostico,
    String? estadoSalud,
    String? gradoEnfermedad,
    String? observaciones,
    bool? esDiagnosticoInicial,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/diagnosticos/$id',
        data: {
          if (fechaDiagnostico != null) 'fechaDiagnostico': fechaDiagnostico.toIso8601String(),
          if (estadoSalud != null) 'estadoSalud': estadoSalud,
          if (gradoEnfermedad != null) 'gradoEnfermedad': gradoEnfermedad,
          if (observaciones != null) 'observaciones': observaciones,
          if (esDiagnosticoInicial != null) 'es_diagnostico_inicial': esDiagnosticoInicial,
        },
      );
      return Diagnostico.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(int id) async {
    try {
      await _dio.delete<void>('/diagnosticos/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
