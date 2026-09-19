import 'package:flutter/material.dart';

import '../../../core/widgets/app_form_dialog.dart';
import '../domain/categoria_indicador.dart';

/// Formulario de creacion/edicion de categoria de indicador, mostrado como
/// dialogo flotante (ver manual de usuario ESCLEROSIS - BI, figuras 29, 30).
Future<Map<String, dynamic>?> showCategoriaFormSheet(
  BuildContext context, {
  CategoriaIndicador? categoria,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierColor: const Color(0x730F172A),
    builder: (context) => _CategoriaFormDialog(categoria: categoria),
  );
}

class _CategoriaFormDialog extends StatefulWidget {
  const _CategoriaFormDialog({this.categoria});
  final CategoriaIndicador? categoria;

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _descripcionController = TextEditingController(text: widget.categoria?.descripcion);

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({'descripcion': _descripcionController.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoria != null;
    return AppFormDialogChrome(
      icon: Icons.description_outlined,
      title: isEditing ? 'Editar categoría' : 'Nueva categoría',
      sectionIcon: Icons.folder_outlined,
      sectionLabel: 'Datos de la categoría',
      submitLabel: isEditing ? 'Guardar' : 'Crear',
      submitIcon: isEditing ? Icons.check : Icons.add,
      onSubmit: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Descripción *', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(hintText: 'Ej. Evaluación nutricional'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
          ],
        ),
      ),
    );
  }
}
