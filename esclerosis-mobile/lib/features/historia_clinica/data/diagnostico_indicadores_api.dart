import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Llamadas HTTP contra `/api/diagnostico-indicadores` de esclerosis-back
/// (ver `esclerosis-back/src/modules/diagnosticos/controllers/diagnostico-indicadores.controller.ts`).
/// Guarda el valor de un indicador clinico para un diagnostico puntual
/// (tabla `diagnostico_indicador_clinico`).
class DiagnosticoIndicadoresApi {
  DiagnosticoIndicadoresApi(this._dio);

  final Dio _dio;

  Future<void> create({
    required int idDiagnostico,
    required int idIndicador,
    required String valor,
    required DateTime fechaMedicion,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/diagnostico-indicadores',
        data: {
          'idDiagnostico': idDiagnostico,
          'idIndicador': idIndicador,
          'valor': valor,
          'fechaMedicion': fechaMedicion.toIso8601String().substring(0, 10),
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
