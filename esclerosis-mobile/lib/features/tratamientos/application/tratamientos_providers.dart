import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/domain/tratamiento.dart';
import '../data/tratamientos_api.dart';

final tratamientosApiProvider = Provider<TratamientosApi>((ref) {
  return TratamientosApi(ref.read(dioProvider));
});

final tratamientosListProvider = FutureProvider.autoDispose<List<Tratamiento>>((ref) {
  return ref.read(tratamientosApiProvider).getAll();
});
