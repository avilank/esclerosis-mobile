import 'package:dio/dio.dart';

import '../../../core/network/crud_api.dart';
import '../domain/medico.dart';

/// Llamadas HTTP contra `/api/medicos` de esclerosis-back.
class MedicosApi {
  MedicosApi(Dio dio) : _crud = CrudApi<Medico>(dio: dio, basePath: '/medicos', fromJson: Medico.fromJson);

  final CrudApi<Medico> _crud;

  Future<List<Medico>> getAll() => _crud.getAll();
}
