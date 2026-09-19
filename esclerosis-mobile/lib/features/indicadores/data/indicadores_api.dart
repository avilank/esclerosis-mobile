import 'package:dio/dio.dart';

import '../../../core/network/crud_api.dart';
import '../domain/categoria_indicador.dart';
import '../domain/indicador_clinico.dart';

/// CRUD contra `/api/categorias-indicadores` (ver
/// `esclerosis-back/src/modules/indicadores-clinicos/controllers/categorias-indicadores.controller.ts`).
class CategoriasIndicadoresApi extends CrudApi<CategoriaIndicador> {
  CategoriasIndicadoresApi(Dio dio)
      : super(
          dio: dio,
          basePath: '/categorias-indicadores',
          fromJson: CategoriaIndicador.fromJson,
        );
}

/// CRUD contra `/api/indicadores-clinicos` (ver
/// `esclerosis-back/src/modules/indicadores-clinicos/controllers/indicadores-clinicos.controller.ts`).
class IndicadoresClinicosApi extends CrudApi<IndicadorClinico> {
  IndicadoresClinicosApi(Dio dio)
      : super(
          dio: dio,
          basePath: '/indicadores-clinicos',
          fromJson: IndicadorClinico.fromJson,
        );
}
