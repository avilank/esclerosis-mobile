import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/crud_api.dart';
import '../domain/area.dart';
import '../domain/permiso.dart';
import '../domain/rol.dart';
import '../domain/sede.dart';
import '../domain/usuario_admin.dart';

class AreasApi extends CrudApi<Area> {
  AreasApi(Dio dio) : super(dio: dio, basePath: '/areas', fromJson: Area.fromJson);
}

class SedesApi extends CrudApi<Sede> {
  SedesApi(Dio dio) : super(dio: dio, basePath: '/sedes', fromJson: Sede.fromJson);
}

class RolesApi extends CrudApi<Rol> {
  RolesApi(Dio dio) : super(dio: dio, basePath: '/roles', fromJson: Rol.fromJson);
}

class UsuariosApi extends CrudApi<UsuarioAdmin> {
  UsuariosApi(Dio dio) : super(dio: dio, basePath: '/usuarios', fromJson: UsuarioAdmin.fromJson);
}

/// `/api/permisos`, con las rutas extra de asignacion permiso<->rol (ver
/// `esclerosis-back/src/modules/auth/permisos/controllers/permisos.controller.ts`).
class PermisosApi extends CrudApi<Permiso> {
  PermisosApi(this._dio) : super(dio: _dio, basePath: '/permisos', fromJson: Permiso.fromJson);

  final Dio _dio;

  Future<List<int>> permisosPorRol(int idRol) async {
    try {
      final response = await _dio.get<List<dynamic>>('/permisos/permisos-roles/rol/$idRol');
      final data = response.data ?? const [];
      return data
          .whereType<Map>()
          .map((e) => (e['idPermiso'] as num?)?.toInt() ?? (e['permiso']?['idPermiso'] as num?)?.toInt())
          .whereType<int>()
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> asignarPermisoARol({required int idRol, required int idPermiso}) async {
    try {
      await _dio.post<void>(
        '/permisos/asignar-rol',
        data: {'idRol': idRol, 'idPermiso': idPermiso},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> quitarPermisoDeRol({required int idRol, required int idPermiso}) async {
    try {
      await _dio.delete<void>('/permisos/permisos-roles/rol/$idRol/permiso/$idPermiso');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
