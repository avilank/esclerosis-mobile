import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../tratamientos/application/tratamientos_providers.dart';
import '../application/historia_clinica_providers.dart';
import '../data/ia_receta_api.dart';

/// Asistente de Prescripcion (una recomendacion via OpenRouter en el backend).
/// Equivalente a `esclerosis-movil/.../RecetaModal.tsx` (figuras 38 y 39),
/// sin selector de modelos dual.
class RecetaIaScreen extends ConsumerStatefulWidget {
  const RecetaIaScreen({super.key, required this.idDiagnostico});

  final int idDiagnostico;

  @override
  ConsumerState<RecetaIaScreen> createState() => _RecetaIaScreenState();
}

class _RecetaIaScreenState extends ConsumerState<RecetaIaScreen> {
  bool _generating = false;
  bool _saving = false;
  bool _preview = false;
  String _sustentacion = '';
  IaResultadoReceta? _result;
  String? _error;

  Future<void> _generate({bool regenerar = false}) async {
    if (regenerar && _result != null && !_preview) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Regenerar sugerencia'),
          content: const Text(
            'Volver a llamar a la IA consume crédito de OpenRouter. ¿Continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final result = await ref.read(iaRecetaApiProvider).sugerir(
            idDiagnostico: widget.idDiagnostico,
            regenerar: regenerar,
          );
      if (!mounted) return;
      setState(() {
        _preview = false;
        _result = result;
      });
      AppToast.success(context, 'Sugerencia lista');
    } on IaNotConfiguredException {
      final tratamientos = await ref.read(tratamientosListProvider.future);
      if (!mounted) return;
      setState(() {
        _preview = true;
        _result = _previewResult(
          tratamientos.isEmpty ? null : tratamientos.first.nombre,
          tratamientos.isEmpty ? null : tratamientos.first.idTratamiento,
        );
      });
      AppToast.warning(context, 'IA no disponible. Mostramos una vista previa');
    } catch (e) {
      if (mounted) {
        final message = AppToast.messageOf(e);
        setState(() => _error = message);
        AppToast.error(context, message);
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  IaResultadoReceta _previewResult(String? nombre, int? id) {
    final tratamiento = nombre ?? 'Dimetilfumarato';
    return IaResultadoReceta(
      modelo: 'OpenRouter',
      tratamientoId: id,
      tratamientoNombre: tratamiento,
      contenido:
          'Iniciar ${tratamiento.toLowerCase()} via oral según pauta estándar, con titulación progresiva y controles hematológicos periódicos.',
      justificacion:
          'Paciente con EM recurrente. Se recomienda una estrategia de escalado con un DMT oral de eficacia intermedia-alta y perfil de seguridad conocido.',
      avisoSeguridad:
          'Esta recomendación es orientativa y debe ser validada por un neurólogo especialista.',
    );
  }

  Future<void> _save() async {
    final actual = _result;
    if (actual == null) return;
    if (_preview) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
      return;
    }
    final tratamientoId = actual.tratamientoId;
    if (tratamientoId == null || tratamientoId == 0) {
      AppToast.warning(context, 'La IA no devolvió un tratamiento válido');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(recetasApiProvider).create(
            idDiagnostico: widget.idDiagnostico,
            idTratamiento: tratamientoId,
            modeloIa: 'OpenRouter',
            fechaReceta: DateTime.now(),
            contenido: actual.contenido,
            sustentacion: _sustentacion.trim().isEmpty
                ? actual.justificacion
                : _sustentacion.trim(),
          );
      if (!mounted) return;
      AppToast.success(context, 'Receta guardada');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x730F172A),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.s5),
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadii.xlAll),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s3, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: AppRadii.mdAll,
                        ),
                        child: const Icon(Icons.description_outlined, color: AppColors.primaryHover, size: 18),
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
                            Text(
                              _result == null ? 'Asistente de Prescripción' : 'Editar Receta',
                              style: AppTypography.heading2,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _skip,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.subtle,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.s5),
                    child: _result == null ? _generatingView() : _resultsView(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s5, 0, AppSpacing.s5, AppSpacing.s5),
                  child: _result == null ? _generatingActions() : _resultsActions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _generatingView() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.s6),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
          child: const Icon(Icons.monitor_heart_outlined, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.s5),
        Text('Asistente de Prescripción', style: AppTypography.heading1, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'La IA analizará los datos clínicos y sugerirá tratamientos basados en protocolos.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.s6),
        FilledButton.icon(
          onPressed: _generating ? null : () => _generate(regenerar: false),
          icon: _generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_generating ? 'Analizando...' : 'Generar Propuesta'),
        ),
      ],
    );
  }

  Widget _generatingActions() {
    return OutlinedButton(
      onPressed: _skip,
      child: const Text('Continuar sin receta'),
    );
  }

  Widget _resultsView() {
    final actual = _result;
    if (actual == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_preview)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s3),
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: AppRadii.mdAll,
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              'Modo vista previa: el backend no pudo usar la IA (reinicie esclerosis-back tras poner OPENROUTER_API_KEY en .env). '
              'El diagnóstico ya está guardado; esta receta no se almacenará.',
              style: AppTypography.caption.copyWith(color: const Color(0xFF92400E)),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFDBFE),
                    borderRadius: AppRadii.smAll,
                  ),
                  child: const Text(
                    'EDITANDO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                  ),
                ),
              ),
              Text(
                'TRATAMIENTO SUGERIDO',
                style: AppTypography.caption.copyWith(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(actual.tratamientoNombre, style: AppTypography.heading2.copyWith(color: const Color(0xFF1E3A8A))),
            ],
          ),
        ),
        if ((actual.avisoSeguridad ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: AppRadii.mdAll,
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              actual.avisoSeguridad!,
              style: AppTypography.caption.copyWith(color: const Color(0xFF92400E)),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        Text('Detalle de la Receta (IA)', style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s3),
          decoration: BoxDecoration(
            color: AppColors.subtle,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Text(actual.contenido, style: AppTypography.body),
        ),
        if ((actual.justificacion ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDFA),
              border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Por qué la IA sugiere esto:', style: AppTypography.label.copyWith(color: AppColors.primaryHover)),
                const SizedBox(height: 4),
                Text(actual.justificacion!, style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(child: Text('Su Justificación Médica *', style: AppTypography.label)),
            Text('Puede modificar este texto', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          minLines: 4,
          maxLines: 6,
          onChanged: (value) => _sustentacion = value,
          decoration: const InputDecoration(
            hintText: 'Escriba el sustento clínico para validar esta receta...',
          ),
        ),
      ],
    );
  }

  Widget _resultsActions() {
    if (_preview) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _generating ? null : () => _generate(regenerar: false),
              child: Text(_generating ? 'Reintentando...' : 'Reintentar IA'),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: FilledButton(
              onPressed: _save,
              child: const Text('Continuar sin receta'),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _generating ? null : () => _generate(regenerar: true),
            child: Text(_generating ? 'Regenerando...' : 'Regenerar IA'),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving || _result == null ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Guardar receta'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }
}
