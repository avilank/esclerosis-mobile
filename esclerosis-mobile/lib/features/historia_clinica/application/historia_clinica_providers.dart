import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/diagnostico_api.dart';
import '../data/diagnostico_indicadores_api.dart';
import '../data/historia_clinica_api.dart';
import '../data/historia_clinica_repository.dart';
import '../data/ia_receta_api.dart';
import '../data/medicos_api.dart';
import '../data/pacientes_api.dart';
import '../domain/medico.dart';
import '../data/recetas_api.dart';
import '../domain/diagnostico.dart';
import '../domain/historia_clinica.dart';
import '../domain/paciente.dart';

final historiaClinicaApiProvider = Provider<HistoriaClinicaApi>((ref) {
  return HistoriaClinicaApi(ref.read(dioProvider));
});

final diagnosticoApiProvider = Provider<DiagnosticoApi>((ref) {
  return DiagnosticoApi(ref.read(dioProvider));
});

final diagnosticoIndicadoresApiProvider = Provider<DiagnosticoIndicadoresApi>((ref) {
  return DiagnosticoIndicadoresApi(ref.read(dioProvider));
});

final pacientesApiProvider = Provider<PacientesApi>((ref) {
  return PacientesApi(ref.read(dioProvider));
});

final medicosApiProvider = Provider<MedicosApi>((ref) {
  return MedicosApi(ref.read(dioProvider));
});

final recetasApiProvider = Provider<RecetasApi>((ref) {
  return RecetasApi(ref.read(dioProvider));
});

final iaRecetaApiProvider = Provider<IaRecetaApi>((ref) {
  return IaRecetaApi(ref.read(dioProvider));
});

final pacientesListProvider = FutureProvider.autoDispose<List<Paciente>>((ref) {
  return ref.read(pacientesApiProvider).getAll();
});

/// Todas las historias clinicas del sistema (uso administrativo).
final historiasClinicasListProvider = FutureProvider.autoDispose<List<HistoriaClinica>>((ref) {
  return ref.read(historiaClinicaApiProvider).getAll();
});

/// Historias activas para registrar diagnostico (como en esclerosis-movil).
final historiasClinicasActivasProvider = FutureProvider.autoDispose<List<HistoriaClinica>>((ref) async {
  final all = await ref.read(historiaClinicaApiProvider).getAll();
  return all.where((h) => h.isActive).toList();
});

final medicosListProvider = FutureProvider.autoDispose<List<Medico>>((ref) {
  return ref.read(medicosApiProvider).getAll();
});

/// Medicos activos para el selector del formulario de diagnostico.
final medicosActivosProvider = FutureProvider.autoDispose<List<Medico>>((ref) async {
  final all = await ref.read(medicosApiProvider).getAll();
  return all.where((m) => m.isActive).toList();
});

final historiaClinicaRepositoryProvider = Provider<HistoriaClinicaRepository>((ref) {
  return HistoriaClinicaRepository(
    historiaClinicaApi: ref.read(historiaClinicaApiProvider),
    diagnosticoApi: ref.read(diagnosticoApiProvider),
    diagnosticoIndicadoresApi: ref.read(diagnosticoIndicadoresApiProvider),
  );
});

/// Historia clinica del paciente logueado. `null` de dato = todavia no tiene
/// una historia clinica creada (no es un error).
final miHistoriaClinicaProvider = FutureProvider.autoDispose<HistoriaClinica?>((ref) async {
  final usuario = ref.watch(authControllerProvider).value;
  if (usuario == null) return null;
  return ref.read(historiaClinicaRepositoryProvider).miHistoriaClinica(usuario.id);
});

/// Historias clinicas de los pacientes atendidos por el medico logueado.
final misPacientesProvider = FutureProvider.autoDispose<List<HistoriaClinica>>((ref) async {
  final usuario = ref.watch(authControllerProvider).value;
  if (usuario == null) return const [];
  return ref.read(historiaClinicaRepositoryProvider).misPacientes(usuario.id);
});

/// Detalle de un diagnostico puntual (con recetas + tratamiento).
final diagnosticoDetalleProvider =
    FutureProvider.autoDispose.family<Diagnostico, int>((ref, idDiagnostico) {
  return ref.read(historiaClinicaRepositoryProvider).diagnosticoDetalle(idDiagnostico);
});

/// Diagnosticos realizados por el medico logueado.
final misDiagnosticosProvider = FutureProvider.autoDispose<List<Diagnostico>>((ref) async {
  final usuario = ref.watch(authControllerProvider).value;
  if (usuario == null) return const [];
  return ref.read(historiaClinicaRepositoryProvider).diagnosticosDeMedico(usuario.id);
});
