import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Muestra un dialogo flotante centrado con el "chrome" de los modales de
/// `esclerosis-movil` (icono + titulo + acento + boton "X", seccion con
/// icono, footer Cancelar/Guardar). Ver manual de usuario ESCLEROSIS - BI,
/// figuras 6, 12, 13, 19, 20, 22, 23, 25, 26, 29, 30, 32, 33.
///
/// `contentBuilder` recibe el `BuildContext` del dialogo y debe devolver el
/// contenido del formulario (campos). El formulario en si (validacion,
/// controllers) sigue viviendo en el caller.
Future<T?> showAppFormDialog<T>(
  BuildContext context, {
  required IconData icon,
  required String title,
  IconData? sectionIcon,
  String? sectionLabel,
  required Widget content,
  required VoidCallback onSubmit,
  String submitLabel = 'Guardar',
  IconData submitIcon = Icons.check,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0x730F172A),
    builder: (dialogContext) => AppFormDialogChrome(
      icon: icon,
      title: title,
      sectionIcon: sectionIcon,
      sectionLabel: sectionLabel,
      content: content,
      onSubmit: onSubmit,
      submitLabel: submitLabel,
      submitIcon: submitIcon,
    ),
  );
}

/// "Chrome" visual reutilizable de los modales de crear/editar: icono +
/// titulo + acento + boton "X", seccion con icono, footer Cancelar/Guardar.
/// Se expone como widget publico para que pantallas que ya manejan su propio
/// `showDialog` (formularios con estado propio, como
/// `simple_field_form_sheet.dart`) puedan reutilizar el mismo diseno sin
/// anidar un segundo `showDialog`.
class AppFormDialogChrome extends StatelessWidget {
  const AppFormDialogChrome({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.onSubmit,
    this.sectionIcon,
    this.sectionLabel,
    this.submitLabel = 'Guardar',
    this.submitIcon = Icons.check,
  });

  final IconData icon;
  final String title;
  final IconData? sectionIcon;
  final String? sectionLabel;
  final Widget content;
  final VoidCallback onSubmit;
  final String submitLabel;
  final IconData submitIcon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s7 + MediaQuery.of(context).viewInsets.bottom / 2,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadii.xlAll),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadii.mdAll),
                    child: Icon(icon, color: AppColors.primaryHover, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(title, style: AppTypography.heading2),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.subtle,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              if (sectionLabel != null) ...[
                Row(
                  children: [
                    if (sectionIcon != null)
                      Icon(sectionIcon, size: 16, color: AppColors.primary),
                    if (sectionIcon != null) const SizedBox(width: AppSpacing.s2),
                    Text(sectionLabel!, style: AppTypography.bodyMedium.copyWith(color: AppColors.ink)),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
              Container(
                padding: const EdgeInsets.all(AppSpacing.s4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadii.lgAll,
                  border: Border.all(color: AppColors.line),
                ),
                child: content,
              ),
              const SizedBox(height: AppSpacing.s5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onSubmit,
                      icon: Icon(submitIcon, size: 18),
                      label: Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
