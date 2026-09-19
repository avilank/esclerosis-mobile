import 'package:flutter/material.dart';

import '../../../core/widgets/app_form_dialog.dart';
import '../domain/categoria_indicador.dart';
import '../domain/indicador_clinico.dart';
import '../domain/indicador_unidad.dart';

/// Formulario de creacion/edicion de indicador clinico, mostrado como
/// dialogo flotante (ver manual de usuario ESCLEROSIS - BI, figuras 2, 32, 33).
Future<Map<String, dynamic>?> showIndicadorFormSheet(
  BuildContext context, {
  required List<CategoriaIndicador> categorias,
  IndicadorClinico? indicador,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierColor: const Color(0x730F172A),
    builder: (context) => _IndicadorFormDialog(categorias: categorias, indicador: indicador),
  );
}

class _IndicadorFormDialog extends StatefulWidget {
  const _IndicadorFormDialog({required this.categorias, this.indicador});
  final List<CategoriaIndicador> categorias;
  final IndicadorClinico? indicador;

  @override
  State<_IndicadorFormDialog> createState() => _IndicadorFormDialogState();
}

class _IndicadorFormDialogState extends State<_IndicadorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.indicador?.nombre);
  late final _descripcionController = TextEditingController(text: widget.indicador?.descripcion);
  late IndicadorUnidad _unidad;
  int? _categoriaId;

  @override
  void initState() {
    super.initState();
    _unidad = widget.indicador?.unidad ?? IndicadorUnidad.numero;
    _categoriaId = widget.indicador?.idCategoriaIndicador;
  }

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
      'unidad': _unidad.value,
      'idCategoriaIndicador': _categoriaId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.indicador != null;
    return AppFormDialogChrome(
      icon: Icons.description_outlined,
      title: isEditing ? 'Editar indicador clínico' : 'Nuevo indicador clínico',
      sectionIcon: Icons.show_chart,
      sectionLabel: 'Datos del indicador',
      onSubmit: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nombre', style: Theme.of(context).textTheme.labelMedium),
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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Text('Unidad', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            DropdownButtonFormField<IndicadorUnidad>(
              initialValue: _unidad,
              decoration: const InputDecoration(),
              items: IndicadorUnidad.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                  .toList(),
              onChanged: (value) => setState(() => _unidad = value ?? IndicadorUnidad.numero),
            ),
            const SizedBox(height: 12),
            Text('Categoría', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(),
              items: widget.categorias
                  .map(
                    (c) => DropdownMenuItem(value: c.idTipoIndicador, child: Text(c.descripcion)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoriaId = value),
              validator: (value) => value == null ? 'Selecciona una categoría' : null,
            ),
          ],
        ),
      ),
    );
  }
}
