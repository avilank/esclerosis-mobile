import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../historia_clinica/application/historia_clinica_providers.dart';
import '../../historia_clinica/domain/medico.dart';
import '../../historia_clinica/domain/paciente.dart';
import '../application/citas_providers.dart';
import '../domain/cita.dart';
import 'paciente_alta_screen.dart';

/// Horarios de atención: 08:00 a 18:00 cada 30 min. El API acepta cualquier
/// `HH:mm`; esto es solo para acelerar la carga.
List<String> _horariosDisponibles() {
  final horarios = <String>[];
  for (var minutos = 8 * 60; minutos <= 18 * 60; minutos += 30) {
    final h = (minutos ~/ 60).toString().padLeft(2, '0');
    final m = (minutos % 60).toString().padLeft(2, '0');
    horarios.add('$h:$m');
  }
  return horarios;
}

/// Alta y edición de una cita. Con [cita] != null edita (el backend solo lo
/// permite mientras esté `programada`).
class CitaFormScreen extends ConsumerStatefulWidget {
  const CitaFormScreen({super.key, this.cita});

  final Cita? cita;

  @override
  ConsumerState<CitaFormScreen> createState() => _CitaFormScreenState();
}

class _CitaFormScreenState extends ConsumerState<CitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _buscadorController = TextEditingController();

  int? _idPaciente;
  int? _idMedico;
  late DateTime _fecha;
  String? _hora;
  bool _guardando = false;
  String _filtroPaciente = '';

  bool get _esEdicion => widget.cita != null;

  @override
  void initState() {
    super.initState();
    final cita = widget.cita;
    if (cita != null) {
      _idPaciente = cita.idPaciente;
      _idMedico = cita.idMedico;
      _hora = cita.horaCita;
      _motivoController.text = cita.motivo ?? '';
      _observacionesController.text = cita.observaciones ?? '';
      _fecha = DateTime.tryParse(cita.fechaCita) ?? DateTime.now();
    } else {
      final ahora = DateTime.now();
      _fecha = DateTime(ahora.year, ahora.month, ahora.day);
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _observacionesController.dispose();
    _buscadorController.dispose();
    super.dispose();
  }

  String get _fechaIso {
    final mes = _fecha.month.toString().padLeft(2, '0');
    final dia = _fecha.day.toString().padLeft(2, '0');
    return '${_fecha.year}-$mes-$dia';
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _crearPaciente() async {
    final nuevo = await Navigator.of(context).push<Paciente>(
      MaterialPageRoute(builder: (_) => const PacienteAltaScreen()),
    );
    if (nuevo == null) return;
    ref.invalidate(pacientesListProvider);
    setState(() {
      _idPaciente = nuevo.idPaciente;
      _filtroPaciente = '';
      _buscadorController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paciente ${nuevo.nombrePaciente} creado')),
      );
    }
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_idPaciente == null || _idMedico == null || _hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá paciente, médico, fecha y hora')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final api = ref.read(citasApiProvider);
      if (_esEdicion) {
        await api.update(
          widget.cita!.idCita,
          idPaciente: _idPaciente,
          idMedico: _idMedico,
          fechaCita: _fechaIso,
          horaCita: _hora,
          motivo: _motivoController.text.trim(),
          observaciones: _observacionesController.text.trim(),
        );
      } else {
        await api.create(
          idPaciente: _idPaciente!,
          idMedico: _idMedico!,
          fechaCita: _fechaIso,
          horaCita: _hora!,
          motivo: _motivoController.text.trim(),
          observaciones: _observacionesController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // El 409 de choque de horario llega acá con el mensaje del backend.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pacientesAsync = ref.watch(pacientesListProvider);
    final medicosAsync = ref.watch(medicosActivosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CrudListHeader(
            title: _esEdicion ? 'Editar cita' : 'Nueva cita',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s5),
                children: [
                  _Seccion(
                    icon: Icons.person_outline,
                    label: 'Paciente',
                    child: pacientesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('No se pudieron cargar: $e'),
                      data: (pacientes) =>
                          _selectorPaciente(pacientes, context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Seccion(
                    icon: Icons.medical_services_outlined,
                    label: 'Médico',
                    child: medicosAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('No se pudieron cargar: $e'),
                      data: (medicos) => _selectorMedico(medicos),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Seccion(
                    icon: Icons.schedule_outlined,
                    label: 'Fecha y hora',
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _elegirFecha,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha *',
                            ),
                            child: Text(
                              '${_fecha.day.toString().padLeft(2, '0')}/'
                              '${_fecha.month.toString().padLeft(2, '0')}/'
                              '${_fecha.year}',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        DropdownButtonFormField<String>(
                          initialValue: _hora,
                          decoration: const InputDecoration(labelText: 'Hora *'),
                          items: [
                            for (final h in _horariosDisponibles())
                              DropdownMenuItem(value: h, child: Text(h)),
                          ],
                          onChanged: (value) => setState(() => _hora = value),
                          validator: (value) =>
                              value == null ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Seccion(
                    icon: Icons.notes_outlined,
                    label: 'Detalle',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _motivoController,
                          decoration: const InputDecoration(
                            labelText: 'Motivo de la consulta',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        TextFormField(
                          controller: _observacionesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: Text(
                      _guardando
                          ? 'Guardando...'
                          : (_esEdicion ? 'Guardar cambios' : 'Agendar cita'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorPaciente(List<Paciente> pacientes, BuildContext context) {
    final filtrados = _filtroPaciente.isEmpty
        ? pacientes
        : pacientes
            .where((p) =>
                p.nombrePaciente.toLowerCase().contains(_filtroPaciente) ||
                p.dniPaciente.toLowerCase().contains(_filtroPaciente))
            .toList();

    final seleccionado = pacientes
        .where((p) => p.idPaciente == _idPaciente)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _buscadorController,
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre o DNI',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) =>
              setState(() => _filtroPaciente = value.trim().toLowerCase()),
        ),
        const SizedBox(height: AppSpacing.s3),
        DropdownButtonFormField<int>(
          initialValue: _idPaciente,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Paciente *'),
          hint: const Text('Seleccioná un paciente'),
          items: [
            for (final p in filtrados)
              DropdownMenuItem(
                value: p.idPaciente,
                child: Text(
                  '${p.nombrePaciente} · DNI ${p.dniPaciente}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _idPaciente = value),
          validator: (value) => value == null ? 'Requerido' : null,
        ),
        if (seleccionado == null && _filtroPaciente.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Sin resultados para "$_filtroPaciente".',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.s2),
        OutlinedButton.icon(
          onPressed: _crearPaciente,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          label: const Text('Crear paciente'),
        ),
      ],
    );
  }

  Widget _selectorMedico(List<Medico> medicos) {
    return DropdownButtonFormField<int>(
      initialValue: _idMedico,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Médico *'),
      hint: const Text('Seleccioná un médico'),
      items: [
        for (final m in medicos)
          DropdownMenuItem(
            value: m.idMedico,
            child: Text(
              m.sedeNombre == null ? m.nombre : '${m.nombre} · ${m.sedeNombre}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => setState(() => _idMedico = value),
      validator: (value) => value == null ? 'Requerido' : null,
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.s2),
            Text(label, style: AppTypography.label),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.subtle),
          ),
          child: child,
        ),
      ],
    );
  }
}
