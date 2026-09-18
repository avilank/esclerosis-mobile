import 'package:dio/dio.dart';

/// Excepcion de dominio para errores de red, desacoplada de Dio.
///
/// `esclerosis-back` (Nest) devuelve, ante un error, el cuerpo generado por
/// `HttpExceptionFilter` (ver `src/common/filters/http-exception.filter.ts`):
/// `exception.getResponse()` tal cual, que puede ser un string o un objeto
/// `{ statusCode, message, error }` (`message` puede ser string o string[]
/// cuando viene de `class-validator`).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    String message = 'Ocurrió un error de conexión';
    if (data is Map) {
      final rawMessage = data['message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage.trim();
      } else if (rawMessage is List) {
        final parts = rawMessage
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) message = parts.join('\n');
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      message = 'No se pudo conectar con el servidor';
    }

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
