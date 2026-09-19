import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/analytics_models.dart';

/// Cliente HTTP contra `/api/analytics/etl` de esclerosis-back.
class AnalyticsApi {
  AnalyticsApi(this._dio);

  final Dio _dio;

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  Future<List<HechoIndicador>> getHechosIndicadores() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/hechos/indicadores');
      return _asList(response.data).map(HechoIndicador.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DimIndicadorClinico>> getDimIndicadoresClinicos() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/dimensiones/indicadores-clinicos');
      return _asList(response.data).map(DimIndicadorClinico.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DimMedicoAnalytics>> getDimMedicos() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/dimensiones/medicos');
      return _asList(response.data).map(DimMedicoAnalytics.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DimOrganizacionAnalytics>> getDimOrganizaciones() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/dimensiones/organizaciones');
      return _asList(response.data).map(DimOrganizacionAnalytics.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DimModeloIa>> getDimModelosIa() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/dimensiones/modelos-ia');
      return _asList(response.data).map(DimModeloIa.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<HechoRecetaAnalytics>> getHechosRecetas() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/hechos/recetas');
      return _asList(response.data).map(HechoRecetaAnalytics.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<HechoPacienteEm>> getHechosPacientesEm() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/hechos/pacientes-em');
      return _asList(response.data).map(HechoPacienteEm.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<HechoPacienteAtendido>> getHechosPacientesAtendidos() async {
    try {
      final response = await _dio.get<dynamic>('/analytics/etl/hechos/pacientes-atendidos');
      return _asList(response.data).map(HechoPacienteAtendido.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
