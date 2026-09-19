import 'package:flutter/material.dart';

import '../../../core/widgets/app_form_dialog.dart';
import '../../historia_clinica/domain/tratamiento.dart';

/// Formulario de creacion/edicion de tratamiento, mostrado como dialogo
/// flotante (ver manual de usuario ESCLEROSIS - BI, figuras 25, 26).
/// Devuelve un `Map` con los campos si se guarda, o `null` si se cancela.
Future<Map<String, dynamic>?> showTratamientoFormSheet(
  BuildContext context, {
  Tratamiento? tratamiento,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierColor: const Color(0x730F172A),
    builder: (context) => _TratamientoFormDialog(tratamiento: tratamiento),
  );
}

class _TratamientoFormDialog extends StatefulWidget {
  const _TratamientoFormDialog({this.tratamiento});
  final Tratamiento? tratamiento;

  @override
  State<_TratamientoFormDialog> createState() => _TratamientoFormDialogState();
}

class _TratamientoFormDialogState extends State<_TratamientoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.tratamiento?.nombre);
  late final _descripcionController =
      TextEditingController(text: widget.tratamiento?.descripcion);

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tratamiento != null;
    return AppFormDialogChrome(
      icon: Icons.description_outlined,
      title: isEditing ? 'Editar Tratamiento' : 'Nuevo Tratamiento',
      sectionIcon: Icons.medication_outlined,
      sectionLabel: 'Información del Tratamiento',
      onSubmit: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nombre del Tratamiento *', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Text('Descripción', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
