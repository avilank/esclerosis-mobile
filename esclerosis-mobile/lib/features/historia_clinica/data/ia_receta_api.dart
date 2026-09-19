import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Resultado de una sola sugerencia de receta generada en el backend
/// (`POST /api/ia/recetas/sugerir` via OpenRouter).
class IaResultadoReceta {
  const IaResultadoReceta({
    required this.modelo,
    required this.tratamientoNombre,
    this.tratamientoId,
    required this.contenido,
    this.justificacion,
    this.avisoSeguridad,
  });

  final String modelo;
  final int? tratamientoId;
  final String tratamientoNombre;
  final String contenido;
  final String? justificacion;
  final String? avisoSeguridad;

  factory IaResultadoReceta.fromJson(Map<String, dynamic> json) {
    final idsRaw = json['tratamiento_ids'];
    int? tratamientoId;
    if (idsRaw is List && idsRaw.isNotEmpty) {
      tratamientoId = int.tryParse(idsRaw.first.toString());
    } else if (idsRaw is String && idsRaw.trim().isNotEmpty) {
      tratamientoId = int.tryParse(idsRaw.split(',').first.trim());
    }
    return IaResultadoReceta(
      modelo: json['modelo'] as String? ?? 'OpenRouter',
      tratamientoId: tratamientoId,
      tratamientoNombre:
          json['tratamiento_seleccionado']?.toString() ?? 'Tratamiento no especificado',
      contenido: json['descripcion_receta']?.toString() ?? '',
      justificacion: json['justificacion']?.toString(),
      avisoSeguridad: json['aviso_seguridad']?.toString(),
    );
  }
}

class IaNotConfiguredException implements Exception {
  const IaNotConfiguredException();

  @override
  String toString() =>
      'La IA no está configurada en el backend (OPENROUTER_API_KEY).';
}

/// Cliente de `esclerosis-back` para el Asistente de Prescripción.
class IaRecetaApi {
  IaRecetaApi(this._dio);

  final Dio _dio;

  Future<IaResultadoReceta> sugerir({
    required int idDiagnostico,
    bool regenerar = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/ia/recetas/sugerir',
        data: {
          'idDiagnostico': idDiagnostico,
          if (regenerar) 'regenerar': true,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final data = response.data;
      if (data is! Map) {
        throw const ApiException(message: 'Respuesta inválida de la IA.');
      }
      return IaResultadoReceta.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      final parsed = ApiException.fromDio(e);
      if (parsed.statusCode == 503) {
        throw const IaNotConfiguredException();
      }
      throw parsed;
    }
  }
}
