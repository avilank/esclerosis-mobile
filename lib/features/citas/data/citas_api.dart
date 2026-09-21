import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/cita.dart';

/// Llamadas HTTP contra `/api/citas` de esclerosis-back (ver
/// `esclerosis-back/src/modules/citas/controllers/citas.controller.ts`).
///
/// El backend fuerza el filtro por rol: un médico solo recibe sus citas y un
/// paciente solo las propias, sin importar lo que mande el cliente.
class CitasApi {
  CitasApi(this._dio);

  final Dio _dio;

  List<Cita> _parseLista(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Cita.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Cita>> getAll({
    String? fecha,
    int? idMedico,
    int? idPaciente,
    String? estado,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/citas',
        queryParameters: {
          if (fecha != null && fecha.isNotEmpty) 'fecha': fecha,
          if (idMedico != null) 'idMedico': idMedico,
          if (idPaciente != null) 'idPaciente': idPaciente,
          if (estado != null && estado.isNotEmpty) 'estado': estado,
        },
      );
      return _parseLista(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Agenda del día (la fecha la resuelve el servidor).
  Future<List<Cita>> getHoy() async {
    try {
      final response = await _dio.get<dynamic>('/citas/hoy');
      return _parseLista(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Cita> getById(int idCita) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/citas/$idCita');
      return Cita.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Cita> create({
    required int idPaciente,
    required int idMedico,
    required String fechaCita,
    required String horaCita,
    int? idSede,
    String? motivo,
    String? observaciones,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/citas',
        data: {
          'idPaciente': idPaciente,
          'idMedico': idMedico,
          'fechaCita': fechaCita,
          'horaCita': horaCita,
          if (idSede != null) 'idSede': idSede,
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
        },
      );
      return Cita.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Reprogramar / editar. El backend rechaza (409) si la cita ya no está
  /// `programada`.
  Future<Cita> update(
    int idCita, {
    int? idPaciente,
    int? idMedico,
    String? fechaCita,
    String? horaCita,
    String? motivo,
    String? observaciones,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/citas/$idCita',
        data: {
          if (idPaciente != null) 'idPaciente': idPaciente,
          if (idMedico != null) 'idMedico': idMedico,
          if (fechaCita != null) 'fechaCita': fechaCita,
          if (horaCita != null) 'horaCita': horaCita,
          if (motivo != null) 'motivo': motivo,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );
      return Cita.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Solo `cancelada` o `no_asistio`. `atendida` la setea el backend al
  /// registrar el diagnóstico.
  Future<Cita> cambiarEstado(int idCita, String estado) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/citas/$idCita/estado',
        data: {'estado': estado},
      );
      return Cita.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(int idCita) async {
    try {
      await _dio.delete<void>('/citas/$idCita');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
