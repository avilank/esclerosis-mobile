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
  // `/recetas` es solo para personal clinico (admin y medico).
  final rol = ref.watch(rolActualProvider);
  final puedeVerRecetas = rol == 'admin' || rol == 'medico';

  // Se lanzan todas juntas y se esperan despues: antes eran 8 peticiones
  // secuenciales, cada una esperando a la anterior (el requisito no funcional
  // pide reportes en menos de 10 s).
  final hechosIndicadoresF = api.getHechosIndicadores();
  final indicadoresF = api.getDimIndicadoresClinicos();
  final medicosF = api.getDimMedicos();
  final organizacionesF = api.getDimOrganizaciones();
  final modelosF = api.getDimModelosIa();
  final hechosRecetasF = api.getHechosRecetas();
  final hechosPacientesEmF = api.getHechosPacientesEm();
  final hechosPacientesAtendidosF = api.getHechosPacientesAtendidos();

  final hechosIndicadores = await hechosIndicadoresF;
  final indicadores = await indicadoresF;
  final medicos = await medicosF;
  final organizaciones = await organizacionesF;
  final modelos = await modelosF;
  final hechosRecetas = await hechosRecetasF;
  final hechosPacientesEm = await hechosPacientesEmF;
  final hechosPacientesAtendidos = await hechosPacientesAtendidosF;

  // Solo la pestaña de dominancia de IA usa este fallback, y solo la ven los
  // roles clínicos.
  var recetasTransaccionales = <Receta>[];
  if (puedeVerRecetas) {
    try {
      recetasTransaccionales = await recetasApi.getAll();
    } catch (_) {}
  }

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
