import 'package:dio/dio.dart';

import '../../../core/network/crud_api.dart';
import '../../historia_clinica/domain/tratamiento.dart';

/// CRUD contra `/api/tratamientos` de esclerosis-back (ver
/// `esclerosis-back/src/modules/tratamientos/controllers/tratamientos.controller.ts`).
class TratamientosApi extends CrudApi<Tratamiento> {
  TratamientosApi(Dio dio)
      : super(dio: dio, basePath: '/tratamientos', fromJson: Tratamiento.fromJson);
}
