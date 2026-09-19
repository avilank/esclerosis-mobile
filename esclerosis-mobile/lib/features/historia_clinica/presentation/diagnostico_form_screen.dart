import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/application/auth_providers.dart';
import '../../indicadores/application/indicadores_providers.dart';
import '../../indicadores/domain/categoria_indicador.dart';
import '../../indicadores/domain/indicador_clinico.dart';
import '../application/historia_clinica_providers.dart';
import '../data/historia_clinica_repository.dart';
import '../domain/historia_clinica.dart';
import 'receta_ia_screen.dart';

const _estadosSalud = ['Leve', 'Moderado', 'Crítico', 'Estable', 'En remisión'];

/// Formulario de creacion de diagnostico para un paciente del medico
/// logueado, con indicadores clinicos dinamicos agrupados por categoria
/// (ver manual de usuario ESCLEROSIS - BI, figura 37 "Registrar nuevo
/// diagnóstico"). Equivalente a
/// `esclerosis-movil/src/app/(tabs)/diagnosticos/create.tsx`.
class DiagnosticoFormScreen extends ConsumerStatefulWidget {
  const DiagnosticoFormScreen({super.key});

  @override
  ConsumerState<DiagnosticoFormScreen> createState() => _DiagnosticoFormScreenState();
}

class _DiagnosticoFormScreenState extends ConsumerState<DiagnosticoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final Map<int, TextEditingController> _indicadorControllers = {};

  HistoriaClinica? _historiaSeleccionada;
  String? _estadoSalud;
  DateTime _fecha = DateTime.now();
  bool _esInicial = false;
  bool _saving = false;
  int? _plantillaCategoriaId;

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

  Map<String, dynamic> _n8nPayload(int idMedico, List<IndicadorValor> valores) {
    final categorias = ref.read(categoriasIndicadoresListProvider).value ?? const [];
    final indicadores = ref.read(indicadoresClinicosListProvider).value ?? const [];
    return {
      'idhistoriaClinica': _historiaSeleccionada!.idHistoriaClinica,
      'idMedico': idMedico,
      'fechaDiagnostico': DateFormat('yyyy-MM-dd').format(_fecha),
      'estadoSalud': _estadoSalud,
      'observaciones': _observacionesController.text.trim(),
      'gradoEnfermedad': _gradoController.text.trim(),
      'es_diagnostico_inicial': _esInicial,
      'indicadores': [
        for (final valor in valores) _indicadorPayload(valor, indicadores, categorias),
      ],
    };
  }

  Map<String, dynamic> _indicadorPayload(
    IndicadorValor valor,
    List<IndicadorClinico> indicadores,
    List<CategoriaIndicador> categorias,
  ) {
    IndicadorClinico? indicador;
    for (final item in indicadores) {
      if (item.idIndicador == valor.idIndicador) {
        indicador = item;
        break;
      }
    }
    String? categoria;
    if (indicador?.idCategoriaIndicador != null) {
      for (final c in categorias) {
        if (c.idTipoIndicador == indicador!.idCategoriaIndicador) {
          categoria = c.descripcion;
          break;
        }
      }
    }
    return {
      'idIndicador': valor.idIndicador,
      'nombre': indicador?.nombre ?? '',
      'valor': valor.valor,
      'unidad': indicador?.unidad.value,
      'categoria': categoria,
    };
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
    if (_historiaSeleccionada == null || _estadoSalud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona paciente y estado de salud')),
      );
      return;
    }
    final usuario = ref.read(authControllerProvider).value;
    if (usuario == null) return;

    setState(() => _saving = true);
    try {
      final indicadores = [
        for (final entry in _indicadorControllers.entries)
          if (entry.value.text.trim().isNotEmpty)
            IndicadorValor(idIndicador: entry.key, valor: entry.value.text.trim()),
      ];
      final diagnostico = await ref.read(historiaClinicaRepositoryProvider).crearDiagnostico(
            idHistoriaClinica: _historiaSeleccionada!.idHistoriaClinica,
            idMedico: usuario.id,
            fechaDiagnostico: _fecha,
            estadoSalud: _estadoSalud!,
            gradoEnfermedad: _gradoController.text.trim(),
            observaciones: _observacionesController.text.trim(),
            esDiagnosticoInicial: _esInicial,
            indicadores: indicadores,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecetaIaScreen(
            idDiagnostico: diagnostico.idDiagnostico,
            diagnosticoData: _n8nPayload(usuario.id, indicadores),
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pacientesAsync = ref.watch(misPacientesProvider);
    final categoriasAsync = ref.watch(categoriasIndicadoresListProvider);
    final indicadoresAsync = ref.watch(indicadoresClinicosListProvider);
    final usuario = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Diagnóstico')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(icon: Icons.person_outline, label: 'Información del Paciente'),
                const SizedBox(height: AppSpacing.s3),
                pacientesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('No se pudieron cargar pacientes: $e'),
                  data: (historias) {
                    return DropdownButtonFormField<HistoriaClinica>(
                      initialValue: _historiaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Historia Clínica *'),
                      isExpanded: true,
                      items: historias
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(
                                h.paciente != null
                                    ? '${h.paciente!.nombrePaciente} - DNI: ${h.paciente!.dniPaciente}'
                                    : 'Paciente #${h.idPaciente}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _historiaSeleccionada = value),
                      validator: (value) => value == null ? 'Selecciona un paciente' : null,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s4),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Médico *'),
                  child: Text(usuario != null ? 'Dr./Dra. ${usuario.username}' : ''),
                ),
                const SizedBox(height: AppSpacing.s4),
                InkWell(
                  onTap: _pickFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha *'),
                    child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                DropdownButtonFormField<String>(
                  initialValue: _estadoSalud,
                  decoration: const InputDecoration(labelText: 'Estado de salud *'),
                  items: _estadosSalud
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _estadoSalud = value),
                  validator: (value) => value == null ? 'Selecciona un estado' : null,
                ),
                const SizedBox(height: AppSpacing.s4),
                TextFormField(
                  controller: _gradoController,
                  decoration: const InputDecoration(labelText: 'Grado de la enfermedad *'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: AppSpacing.s4),
                TextFormField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.s2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Diagnóstico inicial'),
                  value: _esInicial,
                  onChanged: (value) => setState(() => _esInicial = value),
                ),
                const SizedBox(height: AppSpacing.s5),
                Row(
                  children: [
                    Expanded(
                      child: _SectionLabel(icon: Icons.monitor_heart_outlined, label: 'Indicadores Clínicos'),
                    ),
                    categoriasAsync.maybeWhen(
                      data: (categorias) => DropdownButton<int?>(
                        value: _plantillaCategoriaId,
                        underline: const SizedBox.shrink(),
                        hint: const Text('Plantilla'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                          for (final c in categorias)
                            DropdownMenuItem<int?>(value: c.idTipoIndicador, child: Text(c.descripcion)),
                        ],
                        onChanged: (value) => setState(() => _plantillaCategoriaId = value),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                categoriasAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text('No se pudieron cargar las categorías: $e'),
                  data: (categorias) {
                    return indicadoresAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
                        child: LinearProgressIndicator(),
                      ),
                      error: (e, _) => Text('No se pudieron cargar los indicadores: $e'),
                      data: (indicadores) => _IndicadoresPorCategoria(
                        categorias: _plantillaCategoriaId == null
                            ? categorias
                            : categorias
                                .where((c) => c.idTipoIndicador == _plantillaCategoriaId)
                                .toList(),
                        indicadores: indicadores,
                        controllerFor: _controllerFor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s6),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar diagnóstico'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s2),
        Text(label, style: AppTypography.heading3),
      ],
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
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s3, bottom: AppSpacing.s2),
            child: Text(
              categoria.descripcion.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: AppColors.primaryHover,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.s3,
            mainAxisSpacing: AppSpacing.s3,
            childAspectRatio: 2.6,
            children: [
              for (final indicador in indicadores.where(
                (i) => i.idCategoriaIndicador == categoria.idTipoIndicador,
              ))
                TextFormField(
                  controller: controllerFor(indicador.idIndicador),
                  keyboardType: indicador.unidad.value == 'numero'
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: indicador.nombre),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
