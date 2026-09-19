import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/domain/receta.dart';
import '../application/reportes_providers.dart';
import '../domain/analytics_models.dart';
import 'widgets/reportes_attended_list.dart';
import 'widgets/reportes_comparison_chart.dart';
import 'widgets/reportes_dominance_chart.dart';

/// Reportes alineados a `esclerosis-movil/src/app/(tabs)/reportes.tsx`.
class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ReportesAnalyticsView();
  }
}

class _ReportesAnalyticsView extends ConsumerStatefulWidget {
  const _ReportesAnalyticsView();

  @override
  ConsumerState<_ReportesAnalyticsView> createState() => _ReportesAnalyticsViewState();
}

class _ReportesAnalyticsViewState extends ConsumerState<_ReportesAnalyticsView> {
  DateTime? _inicio;
  DateTime? _fin;
  int? _indicadorId;
  int? _medicoId;
  int? _organizacionId;
  int? _modeloId;
  int _tab = 0;
  bool _medicoLocked = false;
  bool _medicoInitDone = false;

  int? get _inicioId => _inicio == null ? null : _toFechaId(_inicio!);
  int? get _finId => _fin == null ? null : _toFechaId(_fin!);

  static int _toFechaId(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  static DateTime? _fromFechaId(int fechaId) {
    final s = fechaId.toString().padLeft(8, '0');
    if (s.length != 8) return null;
    return DateTime(int.parse(s.substring(0, 4)), int.parse(s.substring(4, 6)), int.parse(s.substring(6, 8)));
  }

  List<String> _tabsFor(String? rol) {
    if (rol == 'paciente') return const ['Indicadores médicos', 'Diagnósticos'];
    return const ['Indicadores médicos', 'Dominancia de IA', 'Diagnósticos'];
  }

  void _initMedicoIfNeeded(ReportesAnalyticsData data, String? rol, int? userId) {
    if (_medicoInitDone || rol != 'medico' || userId == null) return;
    final match = data.medicos.where((m) => m.medicoId == userId).firstOrNull;
    if (match != null) {
      _medicoId = match.medicoId;
      _medicoLocked = true;
    } else {
      _medicoLocked = true;
    }
    _medicoInitDone = true;
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(reportesAnalyticsProvider);
    final usuario = ref.watch(authControllerProvider).value;
    final tabs = _tabsFor(usuario?.rol);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: analyticsAsync.when(
        loading: () => const Column(
          children: [
            CrudListHeader(title: 'Reportes'),
            Expanded(child: LoadingView()),
          ],
        ),
        error: (e, _) => Column(
          children: [
            CrudListHeader(title: 'Reportes'),
            Expanded(
              child: ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(reportesAnalyticsProvider),
              ),
            ),
          ],
        ),
        data: (data) {
          _initMedicoIfNeeded(data, usuario?.rol, usuario?.id);

          var hechos = data.hechosIndicadores;
          if (usuario?.rol == 'paciente') {
            hechos = hechos.where((h) => h.pacienteId == usuario!.id).toList();
          }

          if (_inicio == null || _fin == null) {
            final ids = hechos.map((h) => h.fechaId).whereType<int>().toList();
            if (ids.isNotEmpty) {
              ids.sort();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _inicio != null) return;
                setState(() {
                  _inicio = _fromFechaId(ids.first);
                  _fin = _fromFechaId(ids.last);
                });
              });
            }
          }

          final filtradosInd = hechos.where((h) {
            if (_indicadorId != null && h.indicador?.indicadorId != _indicadorId) return false;
            final fechaId = h.fechaId;
            if (fechaId == null) return false;
            if (_inicioId != null && fechaId < _inicioId!) return false;
            if (_finId != null && fechaId > _finId!) return false;
            return true;
          }).toList();

          final series = _seriesDe(filtradosInd);
          final inicial = _inicialDe(filtradosInd);

          final filtradosRecetasDw = data.hechosRecetas.where((h) {
            if (_medicoId != null && h.medicoId != _medicoId) return false;
            if (_organizacionId != null && h.organizacionId != _organizacionId) return false;
            final fechaId = h.fechaId;
            if (fechaId == null) return false;
            if (_inicioId != null && fechaId < _inicioId!) return false;
            if (_finId != null && fechaId > _finId!) return false;
            return true;
          }).toList();

          final dominance = _dominanceRecetas(filtradosRecetasDw, data.recetasTransaccionales);

          final filtradosEm = data.hechosPacientesEm.where((h) {
            if (_medicoId != null && h.medicoId != _medicoId) return false;
            if (_organizacionId != null && h.organizacionId != _organizacionId) return false;
            if (_modeloId != null) {
              final nombre = data.modelos.where((m) => m.modeloId == _modeloId).firstOrNull?.nombreModelo;
              if (nombre != null && !(h.nombreModelo ?? '').toUpperCase().contains(nombre.toUpperCase())) {
                return false;
              }
            }
            return true;
          }).toList();

          final filtradosAtendidos = data.hechosPacientesAtendidos.where((h) {
            if (_organizacionId != null) {
              final org = data.organizaciones.where((o) => o.organizacionId == _organizacionId).firstOrNull;
              if (org != null && h.nombreSede != org.nombreSede) return false;
            }
            final fechaId = h.fechaId;
            if (fechaId != null) {
              if (_inicioId != null && fechaId < _inicioId!) return false;
              if (_finId != null && fechaId > _finId!) return false;
            }
            return true;
          }).toList();

          final tabName = tabs[_tab.clamp(0, tabs.length - 1)];
          final selectedIndicador = data.indicadores.where((i) => i.indicadorId == _indicadorId).firstOrNull;

          final copilotDiag = _sumEmByModels(filtradosEm, ['COPILOT', 'OPENROUTER']);
          final deepseekDiag = _sumEmByModels(filtradosEm, ['DEEPSEEK']);
          final diagnosedTotal = copilotDiag + deepseekDiag;
          final attendedTotal = filtradosAtendidos.fold<int>(0, (s, h) => s + h.cantidad);

          return Column(
            children: [
              CrudListHeader(
                title: 'Reportes',
                trailing: _TotalBadge(total: series.length),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(reportesAnalyticsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s8),
                    children: [
                      if (selectedIndicador != null) ...[
                        Text.rich(
                          TextSpan(
                            text: 'Indicador: ',
                            style: AppTypography.body,
                            children: [
                              TextSpan(
                                text: selectedIndicador.nombreIndicador,
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
                        onTap: () => _pickDate(isStart: true),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      _DateField(
                        label: 'Fecha fin',
                        value: _fin,
                        onTap: () => _pickDate(isStart: false),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      _TabBar(
                        tabs: tabs,
                        active: _tab,
                        onSelect: (i) => setState(() => _tab = i),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      if (tabName == 'Indicadores médicos') ...[
                        Text('Seleccionar Indicador', style: AppTypography.label),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          key: ValueKey(_indicadorId),
                          initialValue: _indicadorId,
                          isExpanded: true,
                          decoration: const InputDecoration(),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                            for (final i in data.indicadores)
                              DropdownMenuItem<int?>(
                                value: i.indicadorId,
                                child: Text(i.nombreIndicador, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) => setState(() => _indicadorId = v),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        _EvolucionChart(series: series, inicial: inicial),
                        const SizedBox(height: AppSpacing.s4),
                        _MetricRow(series: series, inicial: inicial),
                      ],
                      if (tabName == 'Dominancia de IA') ...[
                        _FilterRow(
                          child1: _dropdown<int?>(
                            label: 'Seleccionar Médico',
                            value: _medicoId,
                            enabled: !_medicoLocked,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                              for (final m in data.medicos)
                                DropdownMenuItem<int?>(value: m.medicoId, child: Text(m.nombre)),
                            ],
                            onChanged: _medicoLocked ? null : (v) => setState(() => _medicoId = v),
                          ),
                          child2: _dropdown<int?>(
                            label: 'Seleccionar Organización',
                            value: _organizacionId,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                              for (final o in data.organizaciones)
                                DropdownMenuItem<int?>(
                                  value: o.organizacionId,
                                  child: Text(o.nombreSede),
                                ),
                            ],
                            onChanged: (v) => setState(() => _organizacionId = v),
                          ),
                        ),
                        if (_medicoLocked)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                            child: Text(
                              'Filtro fijo para el médico autenticado',
                              style: AppTypography.caption.copyWith(color: AppColors.muted),
                            ),
                          ),
                        _Card(
                          child: ReportesDominanceChart(
                            primaryCount: dominance.primary,
                            secondaryCount: dominance.secondary,
                            primaryLabel: dominance.primaryLabel,
                            secondaryLabel: dominance.secondaryLabel,
                          ),
                        ),
                      ],
                      if (tabName == 'Diagnósticos') ...[
                        _FilterRow(
                          child1: _dropdown<int?>(
                            label: 'Seleccionar Médico',
                            value: _medicoId,
                            enabled: !_medicoLocked,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                              for (final m in data.medicos)
                                DropdownMenuItem<int?>(value: m.medicoId, child: Text(m.nombre)),
                            ],
                            onChanged: _medicoLocked ? null : (v) => setState(() => _medicoId = v),
                          ),
                          child2: _dropdown<int?>(
                            label: 'Seleccionar Organización',
                            value: _organizacionId,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                              for (final o in data.organizaciones)
                                DropdownMenuItem<int?>(
                                  value: o.organizacionId,
                                  child: Text(o.nombreSede),
                                ),
                            ],
                            onChanged: (v) => setState(() => _organizacionId = v),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _dropdown<int?>(
                          label: 'Seleccionar Modelo',
                          value: _modeloId,
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                            for (final m in data.modelos)
                              DropdownMenuItem<int?>(value: m.modeloId, child: Text(m.nombreModelo)),
                          ],
                          onChanged: (v) => setState(() => _modeloId = v),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (filtradosEm.isEmpty && filtradosAtendidos.isEmpty)
                                Text(
                                  'No hay diagnósticos para los filtros seleccionados.',
                                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                                ),
                              if (diagnosedTotal > 0)
                                Center(
                                  child: ReportesDominanceChart(
                                    primaryCount: copilotDiag,
                                    secondaryCount: deepseekDiag,
                                    primaryLabel: 'IA principal',
                                    secondaryLabel: 'IA alterna',
                                    size: 140,
                                  ),
                                ),
                              ReportesComparisonChart(diagnosed: diagnosedTotal, attended: attendedTotal),
                              if (attendedTotal > 0)
                                ReportesAttendedList(items: filtradosAtendidos),
                              if (filtradosEm.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.s4),
                                Text('Desglose por modelo IA', style: AppTypography.label),
                                for (final entry in _breakdownEm(filtradosEm).entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(entry.key, style: AppTypography.body)),
                                        Text('${entry.value}', style: AppTypography.label),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _inicio : _fin) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _inicio = picked;
      } else {
        _fin = picked;
      }
    });
  }

  ({int primary, int secondary, String primaryLabel, String secondaryLabel}) _dominanceRecetas(
    List<HechoRecetaAnalytics> dw,
    List<Receta> recetasTx,
  ) {
    var primary = dw.fold<int>(0, (s, h) => s + h.cantidadCopilot);
    var secondary = dw.fold<int>(0, (s, h) => s + h.cantidadDeepseek);
    var pl = 'Copilot';
    var sl = 'Deepseek';

    if (primary + secondary == 0 && recetasTx.isNotEmpty) {
      primary = 0;
      secondary = 0;
      for (final r in recetasTx) {
        final modelo = r.modeloIa?.toLowerCase() ?? '';
        if (modelo.contains('openrouter')) {
          primary++;
        } else {
          secondary++;
        }
      }
      pl = 'OpenRouter';
      sl = 'Otros';
    }

    return (primary: primary, secondary: secondary, primaryLabel: pl, secondaryLabel: sl);
  }

  int _sumEmByModels(List<HechoPacienteEm> list, List<String> models) {
    return list
        .where((h) => models.any((m) => (h.nombreModelo ?? '').toUpperCase().contains(m)))
        .fold<int>(0, (s, h) => s + h.cantidad);
  }

  Map<String, int> _breakdownEm(List<HechoPacienteEm> list) {
    final map = <String, int>{};
    for (final h in list) {
      final key = h.nombreIndicador ?? h.nombreModelo ?? 'Sin indicador';
      map[key] = (map[key] ?? 0) + h.cantidad;
    }
    return map;
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

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.child1, required this.child2});
  final Widget child1;
  final Widget child2;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: AppSpacing.s3),
        Expanded(child: child2),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs, required this.active, required this.onSelect});

  final List<String> tabs;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadii.lgAll),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active == i ? AppColors.primary : Colors.transparent,
                    borderRadius: AppRadii.mdAll,
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      fontSize: 12,
                      color: active == i ? Colors.white : AppColors.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.series, required this.inicial});

  final List<PuntoIndicador> series;
  final double? inicial;

  @override
  Widget build(BuildContext context) {
    final promedio = series.isEmpty
        ? null
        : _round2(series.map((p) => p.value).reduce((a, b) => a + b) / series.length);
    final evolucion = (inicial == null || inicial == 0 || promedio == null)
        ? null
        : _round2((promedio - inicial!) / inicial! * 100);
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

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Valor inicial',
            value: inicial == null ? '-' : _fmt(inicial!),
            valueColor: AppColors.danger,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: _MetricCard(
            label: 'Valor promedio',
            value: promedio == null ? '-' : _fmt(promedio),
            valueColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: _MetricCard(
            label: 'Evolución',
            value: evolucion == null ? '-' : '${evolucion > 0 ? '+' : ''}$evolucion%',
            subtitle: interpretacion,
            valueColor: evolucion != null && evolucion >= 0 ? const Color(0xFF059669) : AppColors.danger,
            center: true,
          ),
        ),
      ],
    );
  }

  static double _round2(double v) => (v * 100).round() / 100;

  static String _fmt(double v) => v % 1 == 0 ? '${v.toInt()}' : '$v';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.subtitle,
    this.center = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.heading1.copyWith(fontSize: 22, color: valueColor)),
          if (subtitle != null) Text(subtitle!, style: AppTypography.caption),
        ],
      ),
    );
  }
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
      child: Text('Total: $total', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
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
      return _Card(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text('No hay datos para mostrar', style: AppTypography.caption),
          ),
        ),
      );
    }

    final values = [for (final p in series) p.value, ?inicial];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() < 0.001) ? 1.0 : (maxY - minY) * 0.15;
    final promedio = series.map((p) => p.value).reduce((a, b) => a + b) / series.length;

    return _Card(
      child: SizedBox(
        height: 200,
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
                spots: [for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].value)],
                isCurved: false,
                color: AppColors.primaryHover,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
