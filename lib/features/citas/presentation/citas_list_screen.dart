import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/application/auth_providers.dart';
import '../application/citas_providers.dart';
import '../domain/cita.dart';
import 'cita_detalle_screen.dart';
import 'cita_form_screen.dart';

/// Agenda de citas. Secretaria y admin pueden crear; el médico y el paciente
/// solo ven las propias (el backend ya acota el listado por rol).
class CitasListScreen extends ConsumerWidget {
  const CitasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasAsync = ref.watch(citasListProvider);
    final puedeGestionar = ref.watch(puedeGestionarCitasProvider);
    final fecha = ref.watch(citasFechaFiltroProvider);
    final estado = ref.watch(citasEstadoFiltroProvider);

    Future<void> crear() async {
      final creada = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CitaFormScreen()),
      );
      if (creada == true) invalidarCitasDesdeWidget(ref);
    }

    Future<void> abrir(Cita cita) async {
      final cambio = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CitaDetalleScreen(idCita: cita.idCita),
        ),
      );
      if (cambio == true) invalidarCitasDesdeWidget(ref);
    }

    return CrudListScaffold<Cita>(
      title: 'Citas',
      searchHint: 'Buscar por paciente, médico o motivo...',
      async: citasAsync,
      onAdd: puedeGestionar ? crear : null,
      onRefresh: () => ref.refresh(citasListProvider.future),
      filter: (cita, query) =>
          cita.pacienteNombre.toLowerCase().contains(query) ||
          cita.medicoNombre.toLowerCase().contains(query) ||
          (cita.motivo ?? '').toLowerCase().contains(query) ||
          cita.horaCita.contains(query),
      emptyMessage: 'No hay citas para los filtros seleccionados.',
      emptyIcon: Icons.event_busy_outlined,
      countLabel: (count) =>
          '$count cita${count == 1 ? '' : 's'} encontrada${count == 1 ? '' : 's'}',
      header: _FiltrosCitas(
        fecha: fecha,
        estado: estado,
        onFecha: (value) =>
            ref.read(citasFechaFiltroProvider.notifier).set(value),
        onEstado: (value) =>
            ref.read(citasEstadoFiltroProvider.notifier).set(value),
      ),
      itemBuilder: (context, cita) => CrudListRow(
        avatarText: cita.pacienteNombre,
        title: cita.pacienteNombre,
        subtitle: '${cita.fechaHoraLegible} · ${cita.medicoNombre}',
        subtitleIcon: Icons.schedule_outlined,
        actions: [
          StatusChip(
            label: cita.estado.label,
            color: cita.estado.color,
            background: cita.estado.background,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => abrir(cita),
          ),
        ],
      ),
    );
  }
}

/// Filtro de fecha (por defecto hoy) + chips de estado.
class _FiltrosCitas extends StatelessWidget {
  const _FiltrosCitas({
    required this.fecha,
    required this.estado,
    required this.onFecha,
    required this.onEstado,
  });

  final DateTime? fecha;
  final EstadoCita? estado;
  final ValueChanged<DateTime?> onFecha;
  final ValueChanged<EstadoCita?> onEstado;

  String _etiquetaFecha() {
    if (fecha == null) return 'Todas las fechas';
    final dia = fecha!.day.toString().padLeft(2, '0');
    final mes = fecha!.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        0,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_etiquetaFecha()),
                  onPressed: () async {
                    final elegida = await showDatePicker(
                      context: context,
                      initialDate: fecha ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (elegida != null) onFecha(elegida);
                  },
                ),
              ),
              if (fecha != null)
                TextButton(
                  onPressed: () => onFecha(null),
                  child: const Text('Todas'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ChipEstado(
                  label: 'Todos',
                  seleccionado: estado == null,
                  onTap: () => onEstado(null),
                ),
                for (final e in EstadoCita.values) ...[
                  const SizedBox(width: AppSpacing.s2),
                  _ChipEstado(
                    label: e.label,
                    color: e.color,
                    seleccionado: estado == e,
                    onTap: () => onEstado(estado == e ? null : e),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({
    required this.label,
    required this.seleccionado,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final String label;
  final bool seleccionado;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.label.copyWith(
          color: seleccionado ? Colors.white : color,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: seleccionado,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.10),
      showCheckmark: false,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}
