import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/application/historia_clinica_providers.dart';
import '../../historia_clinica/domain/receta.dart';
import '../data/analytics_api.dart';
import '../domain/analytics_models.dart';

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(ref.read(dioProvider));
});

final reportesAnalyticsProvider = FutureProvider.autoDispose<ReportesAnalyticsData>((ref) async {
  final api = ref.read(analyticsApiProvider);
  final recetasApi = ref.read(recetasApiProvider);

  final hechosIndicadores = await api.getHechosIndicadores();
  final indicadores = await api.getDimIndicadoresClinicos();
  final medicos = await api.getDimMedicos();
  final organizaciones = await api.getDimOrganizaciones();
  final modelos = await api.getDimModelosIa();
  final hechosRecetas = await api.getHechosRecetas();
  final hechosPacientesEm = await api.getHechosPacientesEm();
  final hechosPacientesAtendidos = await api.getHechosPacientesAtendidos();

  var recetasTransaccionales = <Receta>[];
  try {
    recetasTransaccionales = await recetasApi.getAll();
  } catch (_) {}

  return ReportesAnalyticsData(
    hechosIndicadores: hechosIndicadores,
    indicadores: indicadores,
    medicos: medicos,
    organizaciones: organizaciones,
    modelos: modelos,
    hechosRecetas: hechosRecetas,
    hechosPacientesEm: hechosPacientesEm,
    hechosPacientesAtendidos: hechosPacientesAtendidos,
    recetasTransaccionales: recetasTransaccionales,
  );
});

/// Compatibilidad con código que aún use estos providers.
final hechosIndicadoresProvider = FutureProvider.autoDispose<List<HechoIndicador>>((ref) async {
  return (await ref.watch(reportesAnalyticsProvider.future)).hechosIndicadores;
});

final dimIndicadoresClinicosProvider =
    FutureProvider.autoDispose<List<DimIndicadorClinico>>((ref) async {
  return (await ref.watch(reportesAnalyticsProvider.future)).indicadores;
});
