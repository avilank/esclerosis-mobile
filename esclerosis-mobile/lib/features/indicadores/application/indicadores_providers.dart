import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/indicadores_api.dart';
import '../domain/categoria_indicador.dart';
import '../domain/indicador_clinico.dart';

final categoriasIndicadoresApiProvider = Provider<CategoriasIndicadoresApi>((ref) {
  return CategoriasIndicadoresApi(ref.read(dioProvider));
});

final indicadoresClinicosApiProvider = Provider<IndicadoresClinicosApi>((ref) {
  return IndicadoresClinicosApi(ref.read(dioProvider));
});

final categoriasIndicadoresListProvider =
    FutureProvider.autoDispose<List<CategoriaIndicador>>((ref) {
  return ref.read(categoriasIndicadoresApiProvider).getAll();
});

final indicadoresClinicosListProvider = FutureProvider.autoDispose<List<IndicadorClinico>>((ref) {
  return ref.read(indicadoresClinicosApiProvider).getAll();
});
