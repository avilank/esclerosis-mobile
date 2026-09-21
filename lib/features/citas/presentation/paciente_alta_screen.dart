import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/password_policy.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../historia_clinica/domain/paciente.dart';
import '../application/citas_providers.dart';

const _generos = ['Masculino', 'Femenino', 'Otro'];

/// Alta de paciente por la secretaria: `POST /pacientes/con-usuario`.
///
/// Crea usuario + ficha + historia clínica en una transacción. Devuelve el
/// [Paciente] creado por `Navigator.pop`, para que el formulario de cita lo
/// deje seleccionado.
class PacienteAltaScreen extends ConsumerStatefulWidget {
  const PacienteAltaScreen({super.key});

  @override
  ConsumerState<PacienteAltaScreen> createState() => _PacienteAltaScreenState();
}

class _PacienteAltaScreenState extends ConsumerState<PacienteAltaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();

  String? _genero;
  DateTime? _fechaNacimiento;
  bool _guardando = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dniController.dispose();
    _nombreController.dispose();
    _edadController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _elegirFechaNacimiento() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _fechaNacimiento = elegida);
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_genero == null || _fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá género y fecha de nacimiento')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final paciente = await ref.read(pacientesAltaApiProvider).crear(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            dniPaciente: _dniController.text.trim(),
            nombrePaciente: _nombreController.text.trim(),
            edadPaciente: int.parse(_edadController.text.trim()),
            generoPaciente: _genero!,
            fechaNacimiento:
                _fechaNacimiento!.toIso8601String().substring(0, 10),
            direccionPaciente: _direccionController.text.trim(),
            telefonoPaciente: _telefonoController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(paciente);
    } catch (e) {
      // DNI/email/username duplicado llega como 409 con el mensaje del backend.
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CrudListHeader(
            title: 'Nuevo paciente',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s5),
                children: [
                  Text('Datos del paciente',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'DNI *'),
                    validator: (v) => (v == null || v.trim().length != 8)
                        ? '8 dígitos'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _nombreController,
                    decoration:
                        const InputDecoration(labelText: 'Nombre completo *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _edadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad *'),
                    validator: (v) {
                      final edad = int.tryParse(v ?? '') ?? -1;
                      return (edad <= 0 || edad > 120)
                          ? 'Edad inválida (1-120)'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  DropdownButtonFormField<String>(
                    initialValue: _genero,
                    decoration: const InputDecoration(labelText: 'Género *'),
                    items: _generos
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => _genero = value),
                    validator: (value) => value == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  InkWell(
                    onTap: _elegirFechaNacimiento,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento *',
                      ),
                      child: Text(
                        _fechaNacimiento == null
                            ? 'Seleccionar fecha'
                            : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                                '${_fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                                '${_fechaNacimiento!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (v) {
                      final texto = (v ?? '').trim();
                      if (texto.isEmpty) return null;
                      return texto.length != 9 ? '9 dígitos' : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Text('Acceso a la app',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _usernameController,
                    decoration:
                        const InputDecoration(labelText: 'Usuario *'),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Mínimo 3 caracteres'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico *',
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Correo inválido'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña *',
                      helperText: PasswordPolicy.helperText,
                    ),
                    validator: PasswordPolicy.validate,
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: Text(
                      _guardando ? 'Creando...' : 'Crear paciente',
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
}
