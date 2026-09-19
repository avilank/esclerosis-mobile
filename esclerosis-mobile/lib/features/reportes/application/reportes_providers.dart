import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/analytics_api.dart';
import '../domain/analytics_models.dart';

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(ref.read(dioProvider));
});

final hechosIndicadoresProvider = FutureProvider.autoDispose<List<HechoIndicador>>((ref) {
  return ref.read(analyticsApiProvider).getHechosIndicadores();
});

final dimIndicadoresClinicosProvider =
    FutureProvider.autoDispose<List<DimIndicadorClinico>>((ref) {
  return ref.read(analyticsApiProvider).getDimIndicadoresClinicos();
});
