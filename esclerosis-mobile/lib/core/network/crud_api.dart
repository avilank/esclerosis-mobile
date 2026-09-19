import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Cliente REST generico para entidades CRUD simples de `esclerosis-back`
/// (`GET/POST/PATCH/DELETE /<basePath>` y `/<basePath>/:id`), evitando repetir
/// el mismo boilerplate en cada modulo (areas, sedes, roles, permisos,
/// tratamientos, indicadores, categorias-indicadores, usuarios).
class CrudApi<T> {
  CrudApi({
    required Dio dio,
    required String basePath,
    required T Function(Map<String, dynamic> json) fromJson,
  })  : _dio = dio,
        _basePath = basePath,
        _fromJson = fromJson;

  final Dio _dio;
  final String _basePath;
  final T Function(Map<String, dynamic> json) _fromJson;

  List<Map<String, dynamic>> _asListOfMaps(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  Future<List<T>> getAll() async {
    try {
      final response = await _dio.get<dynamic>(_basePath);
      return _asListOfMaps(response.data).map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> getOne(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_basePath/$id');
      return _fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> create(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(_basePath, data: body);
      return _fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> update(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('$_basePath/$id', data: body);
      return _fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(int id) async {
    try {
      await _dio.delete<void>('$_basePath/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
