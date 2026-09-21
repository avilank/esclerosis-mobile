import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/administracion_providers.dart';
import '../../../core/validation/password_policy.dart';
import '../domain/rol.dart';

const _generos = ['Masculino', 'Femenino', 'Otro'];

/// Alta de usuario, con campos condicionales segun el rol elegido (medico /
/// paciente / otro). Equivalente a
/// `esclerosis-movil/src/app/(tabs)/(administrador)/usuarios/index.tsx` +
/// `usuarios.schemas.ts`.
class UsuarioCreateScreen extends ConsumerStatefulWidget {
  const UsuarioCreateScreen({super.key});

  @override
  ConsumerState<UsuarioCreateScreen> createState() => _UsuarioCreateScreenState();
}

class _UsuarioCreateScreenState extends ConsumerState<UsuarioCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nombreMedicoController = TextEditingController();
  String? _generoMedico;
  int? _idArea;
  int? _idSede;

  final _dniController = TextEditingController();
  final _nombrePacienteController = TextEditingController();
  final _edadController = TextEditingController();
  String? _generoPaciente;
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  DateTime? _fechaNacimiento;

  Rol? _rolSeleccionado;
  bool _saving = false;

  bool get _esMedico => (_rolSeleccionado?.nombre ?? '').toLowerCase().contains('medico') ||
      (_rolSeleccionado?.nombre ?? '').toLowerCase().contains('médico');
  bool get _esPaciente => (_rolSeleccionado?.nombre ?? '').toLowerCase() == 'paciente';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombreMedicoController.dispose();
    _dniController.dispose();
    _nombrePacienteController.dispose();
    _edadController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _pickFechaNacimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_rolSeleccionado == null) {
      AppToast.warning(context, 'Selecciona un rol');
      return;
    }
    if (_esPaciente && _fechaNacimiento == null) {
      AppToast.warning(context, 'Selecciona la fecha de nacimiento');
      return;
    }

    final body = <String, dynamic>{
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'estado': true,
      'idRol': _rolSeleccionado!.idRol,
    };

    if (_esMedico) {
      body.addAll({
        'nombreMedico': _nombreMedicoController.text.trim(),
        'generoMedico': _generoMedico,
        'idArea': _idArea,
        'idSede': _idSede,
      });
    } else if (_esPaciente) {
      body.addAll({
        'dniPaciente': _dniController.text.trim(),
        'nombrePaciente': _nombrePacienteController.text.trim(),
        'edadPaciente': int.tryParse(_edadController.text.trim()),
        'generoPaciente': _generoPaciente,
        'direccionPaciente': _direccionController.text.trim(),
        'telefonoPaciente': _telefonoController.text.trim(),
        'fechaNacimiento':
            _fechaNacimiento?.toIso8601String().substring(0, 10),
      });
    }

    setState(() => _saving = true);
    try {
      await ref.read(usuariosApiProvider).create(body);
      ref.invalidate(usuariosListProvider);
      if (!mounted) return;
      AppToast.success(context, 'Usuario creado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesListProvider);
    final areasAsync = ref.watch(areasListProvider);
    final sedesAsync = ref.watch(sedesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo usuario')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    helperText: PasswordPolicy.helperText,
                  ),
                  validator: PasswordPolicy.validate,
                ),
                const SizedBox(height: AppSpacing.s3),
                rolesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('No se pudieron cargar roles: $e'),
                  data: (roles) => DropdownButtonFormField<Rol>(
                    initialValue: _rolSeleccionado,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: roles
                        .map((rol) => DropdownMenuItem(value: rol, child: Text(rol.nombre)))
                        .toList(),
                    onChanged: (value) => setState(() => _rolSeleccionado = value),
                    validator: (value) => value == null ? 'Selecciona un rol' : null,
                  ),
                ),
                if (_esMedico) ...[
                  const SizedBox(height: AppSpacing.s5),
                  Text('Datos del médico', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.s2),
                  TextFormField(
                    controller: _nombreMedicoController,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  DropdownButtonFormField<String>(
                    initialValue: _generoMedico,
                    decoration: const InputDecoration(labelText: 'Género *'),
                    items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) => setState(() => _generoMedico = value),
                    // `medico.genero` es NOT NULL en la base.
                    validator: (value) => value == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  areasAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (areas) => DropdownButtonFormField<int>(
                      initialValue: _idArea,
                      decoration: const InputDecoration(labelText: 'Área'),
                      items: areas
                          .map((a) => DropdownMenuItem(value: a.idArea, child: Text(a.descripcion)))
                          .toList(),
                      onChanged: (value) => setState(() => _idArea = value),
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  sedesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (sedes) => DropdownButtonFormField<int>(
                      initialValue: _idSede,
                      decoration: const InputDecoration(labelText: 'Sede'),
                      items: sedes
                          .map((s) => DropdownMenuItem(value: s.idSede, child: Text(s.nombre)))
                          .toList(),
                      onChanged: (value) => setState(() => _idSede = value),
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                ],
                if (_esPaciente) ...[
                  const SizedBox(height: AppSpacing.s5),
                  Text('Datos del paciente', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.s2),
                  TextFormField(
                    controller: _dniController,
                    decoration: const InputDecoration(labelText: 'DNI'),
                    validator: (v) => (v == null || v.trim().length != 8) ? '8 dígitos' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _nombrePacienteController,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _edadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad'),
                    validator: (v) {
                      final edad = int.tryParse(v ?? '') ?? -1;
                      return (edad <= 0 || edad > 120) ? 'Edad inválida (1-120)' : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  DropdownButtonFormField<String>(
                    initialValue: _generoPaciente,
                    decoration: const InputDecoration(labelText: 'Género *'),
                    items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) => setState(() => _generoPaciente = value),
                    validator: (value) => value == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (v) => (v == null || v.trim().length != 9) ? '9 dígitos' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  InkWell(
                    onTap: _pickFechaNacimiento,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
                      child: Text(
                        _fechaNacimiento == null
                            ? 'Seleccionar fecha'
                            : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
