import 'package:flutter/material.dart';

import '../../../core/widgets/app_form_dialog.dart';

/// Formulario generico de 1-2 campos de texto, usado para entidades simples
/// (areas, sedes, roles, permisos, usuarios). Devuelve un `Map` con los
/// valores ingresados (clave = `field.key`) o `null` si se cancela.
class SimpleFormField {
  const SimpleFormField({
    required this.key,
    required this.label,
    this.initialValue,
    this.required = true,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final String? initialValue;
  final bool required;
  final int maxLines;
}

Future<Map<String, String>?> showSimpleFormSheet(
  BuildContext context, {
  required String title,
  required List<SimpleFormField> fields,
  IconData icon = Icons.description_outlined,
  IconData sectionIcon = Icons.folder_outlined,
  String sectionLabel = 'Datos generales',
  String submitLabel = 'Guardar',
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierColor: const Color(0x730F172A),
    builder: (context) => _SimpleFormDialogContent(
      title: title,
      fields: fields,
      icon: icon,
      sectionIcon: sectionIcon,
      sectionLabel: sectionLabel,
      submitLabel: submitLabel,
    ),
  );
}

class _SimpleFormDialogContent extends StatefulWidget {
  const _SimpleFormDialogContent({
    required this.title,
    required this.fields,
    required this.icon,
    required this.sectionIcon,
    required this.sectionLabel,
    required this.submitLabel,
  });

  final String title;
  final List<SimpleFormField> fields;
  final IconData icon;
  final IconData sectionIcon;
  final String sectionLabel;
  final String submitLabel;

  @override
  State<_SimpleFormDialogContent> createState() => _SimpleFormDialogContentState();
}

class _SimpleFormDialogContentState extends State<_SimpleFormDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final _controllers = {
    for (final field in widget.fields) field.key: TextEditingController(text: field.initialValue),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({
      for (final field in widget.fields) field.key: _controllers[field.key]!.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialogChrome(
      icon: widget.icon,
      title: widget.title,
      sectionIcon: widget.sectionIcon,
      sectionLabel: widget.sectionLabel,
      onSubmit: _submit,
      submitLabel: widget.submitLabel,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in widget.fields) ...[
              Text(field.label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              TextFormField(
                controller: _controllers[field.key],
                decoration: const InputDecoration(),
                maxLines: field.maxLines,
                validator: field.required
                    ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
