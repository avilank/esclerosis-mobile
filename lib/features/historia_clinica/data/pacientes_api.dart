import 'package:dio/dio.dart';

import '../../../core/network/crud_api.dart';
import '../domain/paciente.dart';

/// Llamadas HTTP contra `/api/pacientes` de esclerosis-back (ver
/// `esclerosis-back/src/modules/pacientes/pacientes.controller.ts`), usado
/// para seleccionar pacientes al crear historias clinicas o diagnosticos.
class PacientesApi {
  PacientesApi(Dio dio) : _crud = CrudApi<Paciente>(dio: dio, basePath: '/pacientes', fromJson: Paciente.fromJson);

  final CrudApi<Paciente> _crud;

  Future<List<Paciente>> getAll() => _crud.getAll();
}
