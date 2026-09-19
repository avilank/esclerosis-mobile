import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/receta.dart';

/// Llamadas HTTP contra `/api/recetas` de esclerosis-back (ver
/// `esclerosis-back/src/modules/recetas/recetas.controller.ts`).
class RecetasApi {
  RecetasApi(this._dio);

  final Dio _dio;

  Future<List<Receta>> getAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/recetas');
      final data = response.data ?? const [];
      return data
          .whereType<Map>()
          .map((e) => Receta.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Receta> create({
    required int idDiagnostico,
    required int idTratamiento,
    required String modeloIa,
    required DateTime fechaReceta,
    String? contenido,
    String? sustentacion,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/recetas',
        data: {
          'idDiagnostico': idDiagnostico,
          'idTratamiento': idTratamiento,
          'Modelo_IA': modeloIa,
          'fechaReceta': fechaReceta.toIso8601String().substring(0, 10),
          if (contenido != null) 'contenido': contenido,
          if (sustentacion != null) 'sustentacion': sustentacion,
        },
      );
      final data = response.data;
      if (data is Map) {
        return Receta.fromJson(Map<String, dynamic>.from(data));
      }
      return Receta.fromJson(const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
