import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../auth/application/auth_providers.dart';
import '../../indicadores/application/indicadores_providers.dart';
import '../../indicadores/domain/categoria_indicador.dart';
import '../../indicadores/domain/indicador_clinico.dart';
import '../application/historia_clinica_providers.dart';
import '../data/historia_clinica_repository.dart';
import '../domain/historia_clinica.dart';
import '../domain/medico.dart';
import '../domain/plantillas_indicadores.dart';
import '../../citas/domain/cita.dart';
import 'receta_ia_screen.dart';

const _estadosSalud = [
  ('leve', 'Leve'),
  ('moderado', 'Moderado'),
  ('severo', 'Severo'),
  ('crítico', 'Crítico'),
];

/// Formulario de creacion de diagnostico alineado a
/// `esclerosis-movil/.../CreateDiagnosticoModal` (manual ESCLEROSIS - BI, fig. 37).
class DiagnosticoFormScreen extends ConsumerStatefulWidget {
  const DiagnosticoFormScreen({super.key, this.cita});

  /// Cita que se está atendiendo. Si viene, la historia clínica y el médico
  /// quedan fijados por la cita y el POST manda `idCita` (el backend marca la
  /// cita como `atendida`). Sin cita, solo el admin puede crear diagnósticos.
  final Cita? cita;

  @override
  ConsumerState<DiagnosticoFormScreen> createState() => _DiagnosticoFormScreenState();
}

class _DiagnosticoFormScreenState extends ConsumerState<DiagnosticoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final Map<int, TextEditingController> _indicadorControllers = {};

  HistoriaClinica? _historiaSeleccionada;
  int? _idMedico;
  String? _estadoSalud;
  DateTime _fecha = DateTime.now();
  bool _esInicial = false;
  bool _saving = false;
  String? _plantillaNivel;
  bool _medicoAutoAsignado = false;

  /// Con cita: la historia y el médico salen de ella y no se pueden cambiar.
  Cita? get _cita => widget.cita;
  bool get _esAtencionDeCita => _cita != null;

  @override
  void initState() {
    super.initState();

    final cita = widget.cita;
    if (cita != null) {
      _idMedico = cita.idMedico;
      _medicoAutoAsignado = true;
      // La fecha del diagnóstico arranca en la de la cita.
      _fecha = DateTime.tryParse(cita.fechaCita) ?? DateTime.now();
      // La historia del paciente de la cita se resuelve del listado.
      ref.listenManual(historiasClinicasActivasProvider, (previous, next) {
        next.whenData(_fijarHistoriaDeLaCita);
      });
    }

    ref.listenManual(medicosActivosProvider, (previous, next) {
      next.whenData(_asignarMedicoSiCorresponde);
    });
  }

  /// Fija la historia clínica del paciente de la cita.
  void _fijarHistoriaDeLaCita(List<HistoriaClinica> historias) {
    final cita = widget.cita;
    if (cita == null || _historiaSeleccionada != null) return;
    final historia = historias
        .where((h) => h.idPaciente == cita.idPaciente)
        .firstOrNull;
    if (historia != null && mounted) {
      setState(() => _historiaSeleccionada = historia);
    }
  }

  @override
  void dispose() {
    _gradoController.dispose();
    _observacionesController.dispose();
    for (final c in _indicadorControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int idIndicador) {
    return _indicadorControllers.putIfAbsent(idIndicador, () => TextEditingController());
  }

  void _asignarMedicoSiCorresponde(List<Medico> medicos) {
    if (_medicoAutoAsignado) return;
    final usuario = ref.read(authControllerProvider).value;
    if (usuario?.rol != 'medico') return;
    if (!medicos.any((m) => m.idMedico == usuario!.id)) return;
    _medicoAutoAsignado = true;
    setState(() => _idMedico = usuario!.id);
  }

  void _aplicarPlantilla(String? nivel) {
    setState(() {
      _plantillaNivel = nivel;
      if (nivel == null || nivel.isEmpty) {
        for (final c in _indicadorControllers.values) {
          c.clear();
        }
        return;
      }
      final plantilla = kPlantillasIndicadores[nivel];
      if (plantilla == null) return;
      for (final item in plantilla) {
        _controllerFor(item.idIndicador).text = item.valor;
      }
    });
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_historiaSeleccionada == null || _estadoSalud == null || _idMedico == null) {
      AppToast.warning(context, 'Completa historia clínica, médico y estado de salud');
      return;
    }

    setState(() => _saving = true);
    try {
      final indicadores = [
        for (final entry in _indicadorControllers.entries)
          if (entry.value.text.trim().isNotEmpty)
            IndicadorValor(idIndicador: entry.key, valor: entry.value.text.trim()),
      ];
      final diagnostico = await ref.read(historiaClinicaRepositoryProvider).crearDiagnostico(
            idHistoriaClinica: _historiaSeleccionada!.idHistoriaClinica,
            idMedico: _idMedico!,
            fechaDiagnostico: _fecha,
            estadoSalud: _estadoSalud!,
            gradoEnfermedad: _gradoController.text.trim(),
            observaciones: _observacionesController.text.trim(),
            esDiagnosticoInicial: _esInicial,
            indicadores: indicadores,
            idCita: _cita?.idCita,
          );
      if (!mounted) return;
      AppToast.success(context, 'Diagnóstico guardado');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecetaIaScreen(
            idDiagnostico: diagnostico.idDiagnostico,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historiasAsync = ref.watch(historiasClinicasActivasProvider);
    final medicosAsync = ref.watch(medicosActivosProvider);
    final categoriasAsync = ref.watch(categoriasIndicadoresListProvider);
    final indicadoresAsync = ref.watch(indicadoresClinicosListProvider);
    final usuario = ref.watch(authControllerProvider).value;
    final isMedico = usuario?.rol == 'medico';

    final loadingData = historiasAsync.isLoading ||
        medicosAsync.isLoading ||
        categoriasAsync.isLoading ||
        indicadoresAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CrudListHeader(
            title: _esAtencionDeCita ? 'Atender cita' : 'Nuevo Diagnóstico',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          if (loadingData)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s4),
                  children: [
                    _SectionTitle(icon: Icons.person_outline, label: 'Información del Paciente'),
                    const SizedBox(height: AppSpacing.s3),
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          historiasAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('No se pudieron cargar historias: $e'),
                            data: (historias) {
                              return DropdownButtonFormField<HistoriaClinica>(
                                value: _historiaSeleccionada,
                                decoration: _fieldDecoration('Historia Clínica *'),
                                isExpanded: true,
                                hint: const Text('Buscar paciente...'),
                                items: historias
                                    .map(
                                      (h) => DropdownMenuItem(
                                        value: h,
                                        child: Text(
                                          h.paciente != null
                                              ? '${h.paciente!.nombrePaciente} - DNI: ${h.paciente!.dniPaciente}'
                                              : 'Historia #${h.idHistoriaClinica}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _esAtencionDeCita
                                    ? null
                                    : (value) => setState(
                                          () => _historiaSeleccionada = value,
                                        ),
                                validator: (value) => value == null ? 'Selecciona una historia clínica' : null,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: medicosAsync.when(
                                  loading: () => const SizedBox.shrink(),
                                  error: (e, _) => Text('Médicos: $e'),
                                  data: (medicos) {
                                    return DropdownButtonFormField<int>(
                                      value: _idMedico,
                                      decoration: _fieldDecoration('Médico *'),
                                      isExpanded: true,
                                      hint: const Text('Seleccionar'),
                                      items: medicos
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m.idMedico,
                                              child: Text(m.nombre, overflow: TextOverflow.ellipsis),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: isMedico || _esAtencionDeCita
                                          ? null
                                          : (value) =>
                                              setState(() => _idMedico = value),
                                      validator: (value) =>
                                          value == null ? 'Selecciona un médico' : null,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Fecha *', style: _labelStyle),
                                    const SizedBox(height: AppSpacing.s1),
                                    InkWell(
                                      onTap: _pickFecha,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        height: 48,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                                        decoration: BoxDecoration(
                                          color: AppColors.subtle,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.line),
                                        ),
                                        child: Text(
                                          DateFormat('dd/MM/yyyy').format(_fecha),
                                          style: AppTypography.body,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    categoriasAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (categorias) {
                        if (categorias.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: _SectionTitle(
                                    icon: Icons.monitor_heart_outlined,
                                    label: 'Indicadores Clínicos',
                                  ),
                                ),
                                DropdownButton<String?>(
                                  value: _plantillaNivel,
                                  underline: const SizedBox.shrink(),
                                  isDense: true,
                                  hint: Text('Plantilla', style: AppTypography.label.copyWith(fontSize: 12)),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Plantilla')),
                                    DropdownMenuItem(value: 'leve', child: Text('Leve')),
                                    DropdownMenuItem(value: 'moderado', child: Text('Moderado')),
                                    DropdownMenuItem(value: 'severo', child: Text('Severo')),
                                    DropdownMenuItem(value: 'crítico', child: Text('Crítico')),
                                  ],
                                  onChanged: _aplicarPlantilla,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s3),
                            _FormCard(
                              child: indicadoresAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text('Indicadores: $e'),
                                data: (indicadores) => _IndicadoresPorCategoria(
                                  categorias: categorias,
                                  indicadores: indicadores,
                                  controllerFor: _controllerFor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _estadoSalud,
                                  decoration: _fieldDecoration('Estado de Salud *'),
                                  isExpanded: true,
                                  items: _estadosSalud
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.$1,
                                          child: Text(e.$2),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(() => _estadoSalud = value),
                                  validator: (value) => value == null ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _gradoController,
                                  decoration: _fieldDecoration('Grado *'),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          TextFormField(
                            controller: _observacionesController,
                            decoration: _fieldDecoration('Observaciones'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Diagnóstico inicial', style: AppTypography.body),
                            value: _esInicial,
                            activeThumbColor: AppColors.primary,
                            onChanged: (value) => setState(() => _esInicial = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _FormFooter(
            saving: _saving,
            onCancel: () => Navigator.of(context).maybePop(),
            onSave: _submit,
          ),
        ],
      ),
    );
  }

  static TextStyle get _labelStyle =>
      AppTypography.label.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12);

  static InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: _labelStyle,
      filled: true,
      fillColor: AppColors.subtle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s2),
        Flexible(
          child: Text(
            label,
            style: AppTypography.heading3.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
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

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s3, AppSpacing.s5, bottom + AppSpacing.s3),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: saving ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancelar', style: AppTypography.label.copyWith(color: AppColors.body)),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 18, color: Colors.white),
                        const SizedBox(width: AppSpacing.s2),
                        Text('Guardar', style: AppTypography.label.copyWith(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadoresPorCategoria extends StatelessWidget {
  const _IndicadoresPorCategoria({
    required this.categorias,
    required this.indicadores,
    required this.controllerFor,
  });

  final List<CategoriaIndicador> categorias;
  final List<IndicadorClinico> indicadores;
  final TextEditingController Function(int idIndicador) controllerFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final categoria in categorias) ...[
          Builder(
            builder: (context) {
              final lista = indicadores
                  .where((i) => i.idCategoriaIndicador == categoria.idTipoIndicador)
                  .toList();
              if (lista.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      categoria.descripcion.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.primaryHover,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
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
                            for (final indicador in lista)
                              SizedBox(
                                width: itemWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      indicador.nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.label.copyWith(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s1),
                                    TextFormField(
                                      controller: controllerFor(indicador.idIndicador),
                                      keyboardType: indicador.unidad.value == 'numero'
                                          ? const TextInputType.numberWithOptions(decimal: true)
                                          : TextInputType.text,
                                      decoration: InputDecoration(
                                        hintText: '0.0',
                                        isDense: true,
                                        filled: true,
                                        fillColor: AppColors.subtle,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.s3,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.line),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
