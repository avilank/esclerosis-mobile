import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/administracion_api.dart';
import '../domain/area.dart';
import '../domain/permiso.dart';
import '../domain/rol.dart';
import '../domain/sede.dart';
import '../domain/usuario_admin.dart';

final areasApiProvider = Provider<AreasApi>((ref) => AreasApi(ref.read(dioProvider)));
final sedesApiProvider = Provider<SedesApi>((ref) => SedesApi(ref.read(dioProvider)));
final rolesApiProvider = Provider<RolesApi>((ref) => RolesApi(ref.read(dioProvider)));
final permisosApiProvider = Provider<PermisosApi>((ref) => PermisosApi(ref.read(dioProvider)));
final usuariosApiProvider = Provider<UsuariosApi>((ref) => UsuariosApi(ref.read(dioProvider)));

final areasListProvider = FutureProvider.autoDispose<List<Area>>((ref) {
  return ref.read(areasApiProvider).getAll();
});

final sedesListProvider = FutureProvider.autoDispose<List<Sede>>((ref) {
  return ref.read(sedesApiProvider).getAll();
});

final rolesListProvider = FutureProvider.autoDispose<List<Rol>>((ref) {
  return ref.read(rolesApiProvider).getAll();
});

final permisosListProvider = FutureProvider.autoDispose<List<Permiso>>((ref) {
  return ref.read(permisosApiProvider).getAll();
});

final usuariosListProvider = FutureProvider.autoDispose<List<UsuarioAdmin>>((ref) {
  return ref.read(usuariosApiProvider).getAll();
});
