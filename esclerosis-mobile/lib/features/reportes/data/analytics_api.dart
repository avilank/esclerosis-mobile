import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/analytics_models.dart';

/// Cliente HTTP contra `/api/analytics/etl` de esclerosis-back
/// (ver `esclerosis-back/src/modules/analytics/controllers/analytics.controller.ts`).
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
}
