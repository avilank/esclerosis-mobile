import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/citas_api.dart';
import '../data/pacientes_alta_api.dart';
import '../domain/cita.dart';

final citasApiProvider = Provider<CitasApi>((ref) {
  return CitasApi(ref.read(dioProvider));
});

final pacientesAltaApiProvider = Provider<PacientesAltaApi>((ref) {
  return PacientesAltaApi(ref.read(dioProvider));
});

/// Filtro de fecha de la pantalla de citas. `null` = todas las fechas.
/// Arranca en el día de hoy.
///
/// Riverpod 3 sacó `StateProvider` del export principal, así que los filtros
/// usan `Notifier` (el patrón vigente).
class _FechaFiltroNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  void set(DateTime? fecha) => state = fecha;
}

final citasFechaFiltroProvider =
    NotifierProvider<_FechaFiltroNotifier, DateTime?>(
  _FechaFiltroNotifier.new,
);

/// Filtro por estado. `null` = todos.
class _EstadoFiltroNotifier extends Notifier<EstadoCita?> {
  @override
  EstadoCita? build() => null;

  void set(EstadoCita? estado) => state = estado;
}

final citasEstadoFiltroProvider =
    NotifierProvider<_EstadoFiltroNotifier, EstadoCita?>(
  _EstadoFiltroNotifier.new,
);

String _aIso(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

/// Citas según los filtros activos. El backend ya acota por rol: el médico
/// recibe solo las suyas y el paciente solo las propias.
final citasListProvider = FutureProvider.autoDispose<List<Cita>>((ref) async {
  final fecha = ref.watch(citasFechaFiltroProvider);
  final estado = ref.watch(citasEstadoFiltroProvider);
  return ref.read(citasApiProvider).getAll(
        fecha: fecha == null ? null : _aIso(fecha),
        estado: estado?.value,
      );
});

/// Detalle de una cita puntual.
final citaDetalleProvider =
    FutureProvider.autoDispose.family<Cita, int>((ref, idCita) {
  return ref.read(citasApiProvider).getById(idCita);
});

/// Agenda del día, para los stats del dashboard.
final citasHoyProvider = FutureProvider.autoDispose<List<Cita>>((ref) {
  return ref.read(citasApiProvider).getHoy();
});

/// Conteo por estado de las citas de hoy (header del dashboard).
final citasHoyStatsProvider =
    FutureProvider.autoDispose<Map<EstadoCita, int>>((ref) async {
  final citas = await ref.watch(citasHoyProvider.future);
  final mapa = <EstadoCita, int>{};
  for (final cita in citas) {
    mapa[cita.estado] = (mapa[cita.estado] ?? 0) + 1;
  }
  return mapa;
});

/// Invalida todo lo que depende de citas (tras crear/editar/cambiar estado).
void invalidarCitas(Ref ref) {
  ref.invalidate(citasListProvider);
  ref.invalidate(citasHoyProvider);
}

/// Versión para usar desde widgets (`WidgetRef`).
void invalidarCitasDesdeWidget(WidgetRef ref) {
  ref.invalidate(citasListProvider);
  ref.invalidate(citasHoyProvider);
}
