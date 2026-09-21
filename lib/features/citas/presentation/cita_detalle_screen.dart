import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/presentation/diagnostico_detail_screen.dart';
import '../../historia_clinica/presentation/diagnostico_form_screen.dart';
import '../application/citas_providers.dart';
import '../domain/cita.dart';
import 'cita_form_screen.dart';

/// Detalle de una cita, con las acciones que corresponden al rol:
/// - secretaria/admin: editar (si programada), cancelar, marcar no asistió
/// - médico: atender (crea el diagnóstico), marcar no asistió
/// - paciente: solo lectura
class CitaDetalleScreen extends ConsumerWidget {
  const CitaDetalleScreen({super.key, required this.idCita});

  final int idCita;

  Future<void> _cambiarEstado(
    BuildContext context,
    WidgetRef ref,
    String estado,
    String titulo,
    String mensaje,
  ) async {
    final confirmado = await showConfirmDialog(
      context,
      title: titulo,
      message: mensaje,
    );
    if (!confirmado) return;
    try {
      await ref.read(citasApiProvider).cambiarEstado(idCita, estado);
      ref.invalidate(citaDetalleProvider(idCita));
      invalidarCitasDesdeWidget(ref);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citaAsync = ref.watch(citaDetalleProvider(idCita));
    final puedeGestionar = ref.watch(puedeGestionarCitasProvider);
    final esMedico = ref.watch(esMedicoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CrudListHeader(
            title: 'Detalle de la cita',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: citaAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(citaDetalleProvider(idCita)),
              ),
              data: (cita) => ListView(
                padding: const EdgeInsets.all(AppSpacing.s5),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cita.pacienteNombre,
                          style: AppTypography.heading2,
                        ),
                      ),
                      StatusChip(
                        label: cita.estado.label,
                        color: cita.estado.color,
                        background: cita.estado.background,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Dato(
                    icon: Icons.schedule_outlined,
                    label: 'Fecha y hora',
                    valor: cita.fechaHoraLegible,
                  ),
                  _Dato(
                    icon: Icons.medical_services_outlined,
                    label: 'Médico',
                    valor: cita.medicoNombre,
                  ),
                  if (cita.sedeNombre != null)
                    _Dato(
                      icon: Icons.apartment_outlined,
                      label: 'Sede',
                      valor: cita.sedeNombre!,
                    ),
                  if (cita.paciente != null)
                    _Dato(
                      icon: Icons.badge_outlined,
                      label: 'DNI',
                      valor: cita.paciente!.dniPaciente,
                    ),
                  if ((cita.motivo ?? '').isNotEmpty)
                    _Dato(
                      icon: Icons.notes_outlined,
                      label: 'Motivo',
                      valor: cita.motivo!,
                    ),
                  if ((cita.observaciones ?? '').isNotEmpty)
                    _Dato(
                      icon: Icons.comment_outlined,
                      label: 'Observaciones',
                      valor: cita.observaciones!,
                    ),
                  const SizedBox(height: AppSpacing.s5),
                  ..._acciones(context, ref, cita, puedeGestionar, esMedico),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _acciones(
    BuildContext context,
    WidgetRef ref,
    Cita cita,
    bool puedeGestionar,
    bool esMedico,
  ) {
    // Cita ya atendida: el único acceso útil es al diagnóstico que generó.
    if (cita.estado == EstadoCita.atendida) {
      return [
        if (cita.idDiagnostico != null)
          FilledButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Ver diagnóstico'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiagnosticoDetailScreen(
                  idDiagnostico: cita.idDiagnostico!,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Esta cita ya fue atendida.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ];
    }

    if (!cita.esProgramada) {
      return [
        Text(
          'Cita ${cita.estado.label.toLowerCase()}: no admite más acciones.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ];
    }

    final acciones = <Widget>[];

    if (esMedico) {
      acciones.add(
        FilledButton.icon(
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Atender'),
          onPressed: () async {
            final creado = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => DiagnosticoFormScreen(cita: cita),
              ),
            );
            if (creado == true) {
              ref.invalidate(citaDetalleProvider(idCita));
              invalidarCitasDesdeWidget(ref);
              if (context.mounted) Navigator.of(context).pop(true);
            }
          },
        ),
      );
      acciones.add(const SizedBox(height: AppSpacing.s3));
    }

    if (puedeGestionar) {
      acciones.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Reprogramar / editar'),
          onPressed: () async {
            final editada = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => CitaFormScreen(cita: cita)),
            );
            if (editada == true) {
              ref.invalidate(citaDetalleProvider(idCita));
              invalidarCitasDesdeWidget(ref);
            }
          },
        ),
      );
      acciones.add(const SizedBox(height: AppSpacing.s3));
    }

    // El médico también puede dejar constancia de la ausencia.
    if (puedeGestionar || esMedico) {
      acciones.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.person_off_outlined),
          label: const Text('Marcar "no asistió"'),
          onPressed: () => _cambiarEstado(
            context,
            ref,
            'no_asistio',
            'Marcar como no asistió',
            '¿Confirmás que el paciente no se presentó?',
          ),
        ),
      );
      acciones.add(const SizedBox(height: AppSpacing.s3));
    }

    if (puedeGestionar) {
      acciones.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar cita'),
          onPressed: () => _cambiarEstado(
            context,
            ref,
            'cancelada',
            'Cancelar cita',
            '¿Seguro que querés cancelar esta cita?',
          ),
        ),
      );
    }

    if (acciones.isEmpty) {
      return [
        Text(
          'Solo lectura.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ];
    }
    return acciones;
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icon,
    required this.label,
    required this.valor,
  });

  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
                Text(valor, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
