import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../administracion/application/administracion_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../application/reportes_providers.dart';
import '../domain/analytics_models.dart';

/// Reportes de evolucion clinica. Equivalente a
/// `esclerosis-movil/src/app/(tabs)/reportes.tsx` (ver manual de usuario
/// ESCLEROSIS - BI, figuras 11, 40, 41, 42).
///
/// Medico/paciente: metodologia de Promedio de Valores (todos los puntos
/// intermedios, no solo extremos) con grafico de linea, promedio, valor
/// inicial, evolucion % e interpretacion.
/// Admin: mismos cromos visuales + totales del sistema.
class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(authControllerProvider).value?.rol;
    if (rol == 'admin') return const _AdminReportes();
    return const _IndicadoresMedicosReportes();
  }
}

class _AdminReportes extends ConsumerWidget {
  const _AdminReportes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosListProvider);
    final areasAsync = ref.watch(areasListProvider);
    final sedesAsync = ref.watch(sedesListProvider);

    final loading = usuariosAsync.isLoading || areasAsync.isLoading || sedesAsync.isLoading;
    final error = usuariosAsync.error ?? areasAsync.error ?? sedesAsync.error;
    final total = (usuariosAsync.value?.length ?? 0) +
        (areasAsync.value?.length ?? 0) +
        (sedesAsync.value?.length ?? 0);

    return Scaffold(
      body: Column(
        children: [
          CrudListHeader(
            title: 'Reportes',
            trailing: _TotalBadge(total: total),
          ),
          Expanded(
            child: loading
                ? const LoadingView()
                : error != null
                    ? ErrorView(message: error.toString())
                    : _AdminChart(
                        counts: {
                          'Usuarios': usuariosAsync.value?.length ?? 0,
                          'Áreas': areasAsync.value?.length ?? 0,
                          'Sedes': sedesAsync.value?.length ?? 0,
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdminChart extends StatelessWidget {
  const _AdminChart({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final maxY = (counts.values.isEmpty ? 1 : counts.values.reduce((a, b) => a > b ? a : b))
            .toDouble() *
        1.2 +
        1;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s5),
      children: [
        Text('Totales del sistema', style: AppTypography.heading3),
        const SizedBox(height: AppSpacing.s5),
        Container(
          height: 240,
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: AppColors.line),
          ),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: [
                for (final entry in counts.entries.toList().asMap().entries)
                  BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppColors.primary,
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final keys = counts.keys.toList();
                      final i = value.toInt();
                      if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(keys[i], style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _IndicadoresMedicosReportes extends ConsumerStatefulWidget {
  const _IndicadoresMedicosReportes();

  @override
  ConsumerState<_IndicadoresMedicosReportes> createState() => _IndicadoresMedicosReportesState();
}

class _IndicadoresMedicosReportesState extends ConsumerState<_IndicadoresMedicosReportes> {
  DateTime? _inicio;
  DateTime? _fin;
  int? _indicadorId;
  int _tab = 0;

  int? get _inicioId => _inicio == null ? null : _toFechaId(_inicio!);
  int? get _finId => _fin == null ? null : _toFechaId(_fin!);

  static int _toFechaId(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  static DateTime? _fromFechaId(int fechaId) {
    final s = fechaId.toString().padLeft(8, '0');
    if (s.length != 8) return null;
    return DateTime(int.parse(s.substring(0, 4)), int.parse(s.substring(4, 6)), int.parse(s.substring(6, 8)));
  }

  @override
  Widget build(BuildContext context) {
    final hechosAsync = ref.watch(hechosIndicadoresProvider);
    final indicadoresAsync = ref.watch(dimIndicadoresClinicosProvider);
    final usuario = ref.watch(authControllerProvider).value;
    final tabs = usuario?.rol == 'paciente'
        ? const ['Indicadores médicos', 'Diagnósticos']
        : const ['Indicadores médicos', 'Diagnósticos'];

    return Scaffold(
      body: hechosAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(hechosIndicadoresProvider),
        ),
        data: (hechos) {
          final indicadores = indicadoresAsync.value ?? const <DimIndicadorClinico>[];
          var scoped = hechos;
          if (usuario?.rol == 'paciente') {
            scoped = hechos.where((h) => h.pacienteId == usuario!.id).toList();
          }

          if (_inicio == null || _fin == null) {
            final ids = scoped.map((h) => h.fechaId).whereType<int>().toList();
            if (ids.isNotEmpty) {
              ids.sort();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_inicio != null && _fin != null) return;
                setState(() {
                  _inicio = _fromFechaId(ids.first);
                  _fin = _fromFechaId(ids.last);
                });
              });
            }
          }

          final filtrados = scoped.where((h) {
            if (_indicadorId != null && h.indicador?.indicadorId != _indicadorId) return false;
            final fechaId = h.fechaId;
            if (fechaId == null) return false;
            if (_inicioId != null && fechaId < _inicioId!) return false;
            if (_finId != null && fechaId > _finId!) return false;
            return true;
          }).toList();

          final series = _seriesDe(filtrados);
          DimIndicadorClinico? selected;
          for (final indicador in indicadores) {
            if (indicador.indicadorId == _indicadorId) {
              selected = indicador;
              break;
            }
          }

          return Column(
            children: [
              CrudListHeader(
                title: 'Reportes',
                trailing: _TotalBadge(total: series.length),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s5, 0, AppSpacing.s5, AppSpacing.s8),
                  children: [
                    if (selected != null) ...[
                      Text.rich(
                        TextSpan(
                          text: 'Indicador: ',
                          style: AppTypography.body,
                          children: [
                            TextSpan(
                              text: selected.nombreIndicador,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    _DateField(
                      label: 'Fecha inicio',
                      value: _inicio,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _inicio ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _inicio = picked);
                      },
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    _DateField(
                      label: 'Fecha fin',
                      value: _fin,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fin ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _fin = picked);
                      },
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadii.lgAll),
                      child: Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _tab = i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _tab == i ? AppColors.primary : Colors.transparent,
                                    borderRadius: AppRadii.mdAll,
                                  ),
                                  child: Text(
                                    tabs[i],
                                    style: AppTypography.label.copyWith(
                                      color: _tab == i ? Colors.white : AppColors.body,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    if (_tab == 0) ...[
                      Text('Seleccionar Indicador', style: AppTypography.label),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int?>(
                        key: ValueKey(_indicadorId),
                        initialValue: _indicadorId,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                          for (final indicador in indicadores)
                            DropdownMenuItem<int?>(
                              value: indicador.indicadorId,
                              child: Text(indicador.nombreIndicador, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) => setState(() => _indicadorId = value),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      _EvolucionChart(series: series, inicial: _inicialDe(filtrados)),
                      const SizedBox(height: AppSpacing.s4),
                      _ResumenCards(series: series, inicial: _inicialDe(filtrados)),
                    ] else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
                        child: EmptyView(
                          message: 'La vista de diagnósticos usa la misma metodología de promedio sobre los indicadores filtrados.',
                          icon: Icons.medical_information_outlined,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PuntoIndicador> _seriesDe(List<HechoIndicador> hechos) {
    final grouped = <int, List<double>>{};
    for (final h in hechos) {
      final fechaId = h.fechaId;
      final valor = h.valorPromedioIndicador;
      if (fechaId == null || valor == null) continue;
      grouped.putIfAbsent(fechaId, () => []).add(valor);
    }
    final keys = grouped.keys.toList()..sort();
    return [
      for (final key in keys)
        PuntoIndicador(
          fechaId: key,
          value: _round2(grouped[key]!.reduce((a, b) => a + b) / grouped[key]!.length),
        ),
    ];
  }

  double? _inicialDe(List<HechoIndicador> hechos) {
    if (hechos.isEmpty) return null;
    final ordenados = [...hechos]..sort((a, b) => (a.fechaId ?? 0).compareTo(b.fechaId ?? 0));
    return ordenados.first.valorInicialIndicador ?? ordenados.first.valorPromedioIndicador;
  }

  static double _round2(double value) => (value * 100).round() / 100;
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Text(
        'Total: $total',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value == null ? 'Seleccionar' : DateFormat('yyyy-MM-dd').format(value!),
              style: AppTypography.body.copyWith(color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _EvolucionChart extends StatelessWidget {
  const _EvolucionChart({required this.series, required this.inicial});
  final List<PuntoIndicador> series;
  final double? inicial;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadii.lgAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Text('No hay datos para mostrar', style: AppTypography.caption),
      );
    }

    final values = [for (final p in series) p.value, ?inicial];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() < 0.001) ? 1.0 : (maxY - minY) * 0.15;
    final promedio = series.map((p) => p.value).reduce((a, b) => a + b) / series.length;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.line),
      ),
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= series.length) return const SizedBox.shrink();
                  final s = series[i].fechaId.toString().padLeft(8, '0');
                  final label = s.length == 8 ? '${s.substring(6, 8)}/${s.substring(4, 6)}' : '$i';
                  return Text(label, style: const TextStyle(fontSize: 9, color: AppColors.muted));
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: promedio,
                color: AppColors.danger.withValues(alpha: 0.6),
                strokeWidth: 1,
                dashArray: [6, 4],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].value),
              ],
              isCurved: false,
              color: AppColors.primaryHover,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryHover,
                  strokeWidth: 0,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    t.y.toStringAsFixed(1),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenCards extends StatelessWidget {
  const _ResumenCards({required this.series, required this.inicial});
  final List<PuntoIndicador> series;
  final double? inicial;

  @override
  Widget build(BuildContext context) {
    final promedio = series.isEmpty
        ? null
        : ((series.map((p) => p.value).reduce((a, b) => a + b) / series.length) * 100).round() / 100;
    final evolucion = (inicial == null || inicial == 0 || promedio == null)
        ? null
        : ((promedio - inicial!) / inicial! * 1000).round() / 10;
    String? interpretacion;
    if (evolucion != null) {
      final p = evolucion.abs();
      if (p >= 85) {
        interpretacion = 'Excelente';
      } else if (p >= 70) {
        interpretacion = 'Aceptable';
      } else {
        interpretacion = 'Necesita mejora';
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Unidad: valor promedio', style: AppTypography.caption),
              ),
              if (promedio != null)
                Text('Promedio: $promedio', style: AppTypography.heading3),
              if (inicial != null)
                Text('Inicial: ${inicial! % 1 == 0 ? inicial!.toInt() : inicial}', style: AppTypography.caption),
              if (evolucion != null)
                Text(
                  'Evolución: ${evolucion > 0 ? '+' : ''}$evolucion%',
                  style: AppTypography.caption.copyWith(
                    color: evolucion >= 0 ? AppColors.primaryHover : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (interpretacion != null)
                Text('Interpretación: $interpretacion', style: AppTypography.caption),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valor inicial', style: AppTypography.caption),
              Text(
                inicial == null ? '-' : '${inicial! % 1 == 0 ? inicial!.toInt() : inicial}',
                style: AppTypography.heading1.copyWith(color: AppColors.danger, fontSize: 28),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
