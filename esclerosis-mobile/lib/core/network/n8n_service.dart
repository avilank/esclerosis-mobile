import 'package:dio/dio.dart';

import '../env/app_env.dart';

/// Resultado sugerido por un modelo de IA (Copilot o Deepseek) para un
/// diagnostico, igual al `IAResult` de
/// `esclerosis-movil/src/features/diagnosticos/services/N8nService.ts`.
class IaResultadoReceta {
  const IaResultadoReceta({
    required this.modelo,
    required this.tratamientoNombre,
    this.tratamientoId,
    required this.contenido,
    this.justificacion,
    this.avisoSeguridad,
  });

  final String modelo; // 'COPILOT' | 'DEEPSEEK'
  final int? tratamientoId;
  final String tratamientoNombre;
  final String contenido;
  final String? justificacion;
  final String? avisoSeguridad;
}

class N8nRecetasResponse {
  const N8nRecetasResponse({this.copilot, this.deepseek});
  final IaResultadoReceta? copilot;
  final IaResultadoReceta? deepseek;
}

/// Cliente del webhook n8n usado por el "Asistente de Prescripción" (ver
/// manual de usuario ESCLEROSIS - BI, figuras 4, 38, 39). No forma parte de
/// `esclerosis-back`: es infraestructura n8n externa (Copilot/Deepseek) a la
/// que `esclerosis-movil` llama directo desde el cliente.
///
/// Mientras [AppEnv.n8nWebhookUrl] este vacio, [generateReceta] lanza
/// [N8nNotConfiguredException] y la UI muestra un estado "IA no
/// configurada" en vez de intentar la llamada.
class N8nNotConfiguredException implements Exception {
  const N8nNotConfiguredException();
  @override
  String toString() =>
      'La URL del webhook de n8n no está configurada (N8N_WEBHOOK_URL en env/*.json).';
}

class N8nService {
  N8nService([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<N8nRecetasResponse> generateReceta({
    required Map<String, dynamic> diagnosticoData,
    required List<({int idTratamiento, String nombre})> tratamientos,
  }) async {
    if (!AppEnv.hasN8nWebhook) {
      throw const N8nNotConfiguredException();
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppEnv.n8nWebhookUrl,
        data: diagnosticoData,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
          contentType: 'application/json',
        ),
      );
      final body = response.data ?? const {};
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return N8nRecetasResponse(
        copilot: _parseModelo(data['copilot'] as Map<String, dynamic>?, 'COPILOT', tratamientos),
        deepseek: _parseModelo(data['deepseek'] as Map<String, dynamic>?, 'DEEPSEEK', tratamientos),
      );
    } on DioException catch (e) {
      throw Exception(
        'No se pudo generar la receta con IA: ${e.response?.data?['message'] ?? e.message}',
      );
    }
  }

  IaResultadoReceta? _parseModelo(
    Map<String, dynamic>? modeloData,
    String modelo,
    List<({int idTratamiento, String nombre})> tratamientos,
  ) {
    if (modeloData == null) return null;
    final idsRaw = modeloData['tratamiento_ids'];
    int? tratamientoId;
    if (idsRaw is List && idsRaw.isNotEmpty) {
      tratamientoId = int.tryParse(idsRaw.first.toString());
    } else if (idsRaw is String && idsRaw.trim().isNotEmpty) {
      tratamientoId = int.tryParse(idsRaw.split(',').first.trim());
    }
    final nombreSugerido = modeloData['tratamiento_seleccionado']?.toString();
    final encontrado = tratamientoId != null
        ? tratamientos.where((t) => t.idTratamiento == tratamientoId).firstOrNull
        : tratamientos.where((t) => t.nombre == nombreSugerido).firstOrNull;

    return IaResultadoReceta(
      modelo: modelo,
      tratamientoId: encontrado?.idTratamiento ?? tratamientoId,
      tratamientoNombre: encontrado?.nombre ?? nombreSugerido ?? 'Tratamiento no especificado',
      contenido: modeloData['descripcion_receta']?.toString() ?? '',
      justificacion: modeloData['justificacion']?.toString(),
      avisoSeguridad: modeloData['aviso_seguridad']?.toString(),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
