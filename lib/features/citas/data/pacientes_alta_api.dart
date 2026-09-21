import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../historia_clinica/domain/paciente.dart';

/// Alta completa de un paciente: `POST /api/pacientes/con-usuario`.
///
/// Crea usuario (rol paciente) + ficha + historia clínica en una transacción.
/// Es la vía de la secretaria; `POST /usuarios` (que permite crear admins y
/// médicos) le está vedado.
class PacientesAltaApi {
  PacientesAltaApi(this._dio);

  final Dio _dio;

  Future<Paciente> crear({
    required String username,
    required String email,
    required String password,
    required String dniPaciente,
    required String nombrePaciente,
    required int edadPaciente,
    required String generoPaciente,
    required String fechaNacimiento,
    String? direccionPaciente,
    String? telefonoPaciente,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/pacientes/con-usuario',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'dniPaciente': dniPaciente,
          'nombrePaciente': nombrePaciente,
          'edadPaciente': edadPaciente,
          'generoPaciente': generoPaciente,
          'fechaNacimiento': fechaNacimiento,
          if (direccionPaciente != null && direccionPaciente.isNotEmpty)
            'direccionPaciente': direccionPaciente,
          if (telefonoPaciente != null && telefonoPaciente.isNotEmpty)
            'telefonoPaciente': telefonoPaciente,
        },
      );
      return Paciente.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
