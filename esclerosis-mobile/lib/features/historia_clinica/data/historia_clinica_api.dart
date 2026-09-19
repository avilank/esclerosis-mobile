import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/historia_clinica.dart';

/// Llamadas HTTP contra `/api/historias-clinicas` de esclerosis-back
/// (ver `esclerosis-back/src/modules/historias-clinicas/historias-clinicas.controller.ts`).
class HistoriaClinicaApi {
  HistoriaClinicaApi(this._dio);

  final Dio _dio;

  /// Historia clinica del paciente logueado (`idPaciente` = `Usuario.id`).
  /// `null` si el paciente todavia no tiene una historia clinica creada.
  ///
  /// Nota: cuando no hay historia, Nest responde `200` con body vacio (o
  /// `null`). Dio lo entrega como `null` o `''` (String), no como Map —
  /// hay que tratar esos casos antes de castear.
  Future<HistoriaClinica?> getByPaciente(int idPaciente) async {
    try {
      final response = await _dio.get<dynamic>('/historias-clinicas/paciente/$idPaciente');
      final data = response.data;
      if (data == null) return null;
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.isEmpty || trimmed == 'null') return null;
        throw const ApiException(
          message: 'Respuesta inesperada del servidor (texto en vez de JSON)',
        );
      }
      if (data is! Map) return null;
      return HistoriaClinica.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  /// Historias clinicas de los pacientes atendidos por el medico logueado
  /// (`idMedico` = `Usuario.id`). Solo incluye los diagnosticos hechos por
  /// ese medico (ver `findMedicoHistoriaClinica` en el backend).
  Future<List<HistoriaClinica>> getByMedico(int idMedico) async {
    try {
      final response = await _dio.get<List<dynamic>>('/historias-clinicas/medico/$idMedico');
      final data = response.data ?? const [];
      return data
          .map((e) => HistoriaClinica.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Todas las historias clinicas del sistema (uso administrativo). Ver
  /// `HistoriasClinicasController.findAll`.
  Future<List<HistoriaClinica>> getAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/historias-clinicas');
      final data = response.data ?? const [];
      return data
          .whereType<Map>()
          .map((e) => HistoriaClinica.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Crea una nueva historia clinica para un paciente (uso administrativo).
  Future<HistoriaClinica> create({
    required int idPaciente,
    String? estado,
    DateTime? fechaIngreso,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/historias-clinicas',
        data: {
          'idPaciente': idPaciente,
          if (estado != null && estado.isNotEmpty) 'estado': estado,
          if (fechaIngreso != null) 'fechaIngreso': fechaIngreso.toIso8601String(),
        },
      );
      return HistoriaClinica.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
