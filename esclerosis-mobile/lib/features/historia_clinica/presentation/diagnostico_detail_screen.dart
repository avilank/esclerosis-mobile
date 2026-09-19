import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../application/historia_clinica_providers.dart';
import '../domain/diagnostico.dart';
import '../domain/diagnostico_indicador_registro.dart';
import '../domain/receta.dart';
import '../../indicadores/domain/indicador_unidad.dart';
import 'widgets/estado_salud_tag.dart';

/// Detalle de un diagnostico (paciente, clinica, indicadores y recetas).
class DiagnosticoDetailScreen extends ConsumerWidget {
  const DiagnosticoDetailScreen({super.key, required this.idDiagnostico});

  final int idDiagnostico;

  static String _formatFecha(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar diagnóstico',
      message: '¿Seguro que deseas eliminar este diagnóstico? Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;
    try {
      await ref.read(historiaClinicaRepositoryProvider).eliminarDiagnostico(idDiagnostico);
      ref.invalidate(misDiagnosticosProvider);
      ref.invalidate(misPacientesProvider);
      ref.invalidate(historiasClinicasListProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticoAsync = ref.watch(diagnosticoDetalleProvider(idDiagnostico));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: diagnosticoAsync.when(
        loading: () => Column(
          children: [
            CrudListHeader(
              title: 'Diagnóstico',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
          ],
        ),
        error: (error, _) => Column(
          children: [
            CrudListHeader(
              title: 'Diagnóstico',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        data: (diagnostico) => _DiagnosticoDetailBody(
          diagnostico: diagnostico,
          onDelete: () => _delete(context, ref),
          onRefresh: () => ref.refresh(diagnosticoDetalleProvider(idDiagnostico).future),
        ),
      ),
    );
  }
}

class _DiagnosticoDetailBody extends StatelessWidget {
  const _DiagnosticoDetailBody({
    required this.diagnostico,
    required this.onDelete,
    required this.onRefresh,
  });

  final Diagnostico diagnostico;
  final VoidCallback onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final paciente = diagnostico.paciente;
    final titulo = paciente?.nombrePaciente ?? 'Diagnóstico';

    return Column(
      children: [
        CrudListHeader(
          title: titulo,
          onBack: () => Navigator.of(context).maybePop(),
          trailing: IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Eliminar',
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s6),
              children: [
                _SummaryCard(diagnostico: diagnostico),
                const SizedBox(height: AppSpacing.s5),
                _SectionHeader(icon: Icons.assignment_outlined, label: 'Información clínica'),
                const SizedBox(height: AppSpacing.s3),
                _DetailCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Fecha',
                        value: DiagnosticoDetailScreen._formatFecha(diagnostico.fechaDiagnostico),
                      ),
                      _InfoRow(
                        icon: Icons.speed_outlined,
                        label: 'Grado de enfermedad',
                        value: diagnostico.gradoEnfermedad,
                      ),
                      if (diagnostico.medico != null)
                        _InfoRow(
                          icon: Icons.medical_services_outlined,
                          label: 'Médico',
                          value: diagnostico.medico!.nombre,
                        ),
                      if (diagnostico.esDiagnosticoInicial)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: const Text('Diagnóstico inicial'),
                              backgroundColor: AppColors.secondary,
                              labelStyle: AppTypography.label.copyWith(color: AppColors.primaryHover),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                            ),
                          ),
                        ),
                      if ((diagnostico.observaciones ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text('Observaciones', style: _labelStyle),
                        const SizedBox(height: AppSpacing.s2),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.s3),
                          decoration: BoxDecoration(
                            color: AppColors.subtle,
                            borderRadius: AppRadii.mdAll,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            diagnostico.observaciones!,
                            style: AppTypography.body,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (diagnostico.indicadores.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s5),
                  _SectionHeader(icon: Icons.monitor_heart_outlined, label: 'Indicadores clínicos'),
                  const SizedBox(height: AppSpacing.s3),
                  _IndicadoresCard(indicadores: diagnostico.indicadores),
                ],
                const SizedBox(height: AppSpacing.s5),
                _SectionHeader(icon: Icons.medication_outlined, label: 'Recetas'),
                const SizedBox(height: AppSpacing.s3),
                if (diagnostico.recetas.isEmpty)
                  _DetailCard(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.muted),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: Text(
                            'No hay recetas asociadas a este diagnóstico.',
                            style: AppTypography.body.copyWith(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final receta in diagnostico.recetas) _RecetaCard(receta: receta),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static TextStyle get _labelStyle =>
      AppTypography.label.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.diagnostico});

  final Diagnostico diagnostico;

  @override
  Widget build(BuildContext context) {
    final paciente = diagnostico.paciente;
    return _DetailCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(text: paciente?.nombrePaciente ?? 'NA', size: 52),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente?.nombrePaciente ?? 'Paciente no disponible',
                  style: AppTypography.heading2.copyWith(fontSize: 18),
                ),
                if (paciente != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    'DNI: ${paciente.dniPaciente} · ${paciente.edadPaciente} años',
                    style: AppTypography.caption.copyWith(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s2,
                  runSpacing: AppSpacing.s2,
                  children: [
                    EstadoSaludTag(diagnostico: diagnostico),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
                      decoration: BoxDecoration(
                        color: AppColors.subtle,
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: Text(
                        'ID #${diagnostico.idDiagnostico}',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s2),
        Text(label, style: AppTypography.heading3.copyWith(fontSize: 14)),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadoresCard extends StatelessWidget {
  const _IndicadoresCard({required this.indicadores});

  final List<DiagnosticoIndicadorRegistro> indicadores;

  @override
  Widget build(BuildContext context) {
    final porCategoria = <String, List<DiagnosticoIndicadorRegistro>>{};
    for (final item in indicadores) {
      final key = (item.categoria ?? 'Otros').trim();
      porCategoria.putIfAbsent(key, () => []).add(item);
    }

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in porCategoria.entries) ...[
            Text(
              entry.key.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: AppColors.primaryHover,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const Divider(height: 16, color: AppColors.primaryLight),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - AppSpacing.s3) / 2;
                return Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s3,
                  children: [
                    for (final ind in entry.value)
                      SizedBox(
                        width: itemWidth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.subtle,
                            borderRadius: AppRadii.mdAll,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ind.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(color: AppColors.muted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                IndicadorUnidad.valorParaMostrar(ind.valor, ind.unidad),
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (entry != porCategoria.entries.last) const SizedBox(height: AppSpacing.s4),
          ],
        ],
      ),
    );
  }
}

class _RecetaCard extends StatelessWidget {
  const _RecetaCard({required this.receta});

  final Receta receta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: _DetailCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    receta.tratamiento?.nombre ?? 'Tratamiento',
                    style: AppTypography.heading3,
                  ),
                ),
                if ((receta.modeloIa ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: AppRadii.smAll,
                    ),
                    child: Text(
                      receta.modeloIa!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Fecha: ${DiagnosticoDetailScreen._formatFecha(receta.fechaReceta)}',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
            if ((receta.contenido ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s3),
              Text('Prescripción', style: AppTypography.label.copyWith(fontSize: 12)),
              const SizedBox(height: AppSpacing.s2),
              Text(receta.contenido!, style: AppTypography.body),
            ],
            if ((receta.sustentacion ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s3),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDFA),
                  border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sustento clínico',
                      style: AppTypography.label.copyWith(color: AppColors.primaryHover, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receta.sustentacion!,
                      style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
