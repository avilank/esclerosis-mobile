import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/app_env.dart';
import '../../../core/network/n8n_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../tratamientos/application/tratamientos_providers.dart';
import '../application/historia_clinica_providers.dart';

/// Asistente de Prescripcion (Copilot / Deepseek). Equivalente a
/// `esclerosis-movil/src/features/diagnosticos/components/RecetaModal.tsx`
/// (ver manual de usuario ESCLEROSIS - BI, figuras 38 y 39).
///
/// Si [AppEnv.n8nWebhookUrl] esta vacio, muestra una vista previa del
/// diseno (sin llamar al webhook) y no persiste receta. Cuando se configure
/// la URL, [N8nService.generateReceta] se activa con el mismo contrato que
/// `N8nService.ts`.
class RecetaIaScreen extends ConsumerStatefulWidget {
  const RecetaIaScreen({
    super.key,
    required this.idDiagnostico,
    required this.diagnosticoData,
  });

  final int idDiagnostico;
  final Map<String, dynamic> diagnosticoData;

  @override
  ConsumerState<RecetaIaScreen> createState() => _RecetaIaScreenState();
}

class _RecetaIaScreenState extends ConsumerState<RecetaIaScreen> {
  static const _modelos = ['COPILOT', 'DEEPSEEK'];

  bool _generating = false;
  bool _saving = false;
  bool _preview = false;
  String _selectedModel = 'COPILOT';
  String _sustentacion = '';
  N8nRecetasResponse? _results;
  String? _error;

  IaResultadoReceta? get _current {
    if (_results == null) return null;
    return _selectedModel == 'COPILOT' ? _results!.copilot : _results!.deepseek;
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final tratamientos = await ref.read(tratamientosListProvider.future);
      final catalogo = [
        for (final t in tratamientos) (idTratamiento: t.idTratamiento, nombre: t.nombre),
      ];
      if (!AppEnv.hasN8nWebhook) {
        setState(() {
          _preview = true;
          _results = _previewResponse(catalogo);
          if (_results!.deepseek != null) _selectedModel = 'DEEPSEEK';
          if (_results!.copilot != null) _selectedModel = 'COPILOT';
        });
        return;
      }
      final response = await ref.read(n8nServiceProvider).generateReceta(
            diagnosticoData: widget.diagnosticoData,
            tratamientos: catalogo,
          );
      setState(() {
        _preview = false;
        _results = response;
        if (response.deepseek != null) {
          _selectedModel = 'DEEPSEEK';
        } else if (response.copilot != null) {
          _selectedModel = 'COPILOT';
        }
      });
    } on N8nNotConfiguredException {
      setState(() {
        _preview = true;
        _results = _previewResponse(const []);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  N8nRecetasResponse _previewResponse(
    List<({int idTratamiento, String nombre})> tratamientos,
  ) {
    final primero = tratamientos.isEmpty ? null : tratamientos.first;
    IaResultadoReceta demo(String modelo, String nombre) {
      return IaResultadoReceta(
        modelo: modelo,
        tratamientoId: primero?.idTratamiento,
        tratamientoNombre: primero?.nombre ?? nombre,
        contenido:
            'Iniciar ${nombre.toLowerCase()} via oral según pauta estándar, con titulación progresiva y controles hematológicos periódicos.',
        justificacion:
            'Paciente con EM recurrente con EDSS bajo pero evidencia de actividad inflamatoria en RM y afectación cognitiva leve. Se recomienda una estrategia de escalado con un DMT oral de eficacia intermedia-alta y perfil de seguridad conocido.',
        avisoSeguridad:
            'Esta recomendación es orientativa y debe ser validada por un neurólogo especialista.',
      );
    }

    return N8nRecetasResponse(
      copilot: demo('COPILOT', 'Dimetilfumarato'),
      deepseek: demo('DEEPSEEK', 'Acetato de glatiramer'),
    );
  }

  Future<void> _save() async {
    final actual = _current;
    if (actual == null) return;
    if (_preview || !AppEnv.hasN8nWebhook) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'IA no configurada: no se guardó receta. Configure N8N_WEBHOOK_URL en env/*.json.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    final tratamientoId = actual.tratamientoId;
    if (tratamientoId == null || tratamientoId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El modelo no devolvió un tratamiento válido')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(recetasApiProvider).create(
            idDiagnostico: widget.idDiagnostico,
            idTratamiento: tratamientoId,
            modeloIa: _selectedModel,
            fechaReceta: DateTime.now(),
            contenido: actual.contenido,
            sustentacion: _sustentacion.trim().isEmpty ? actual.justificacion : _sustentacion.trim(),
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
                              _results == null ? 'Asistente de Prescripción' : 'Editar Receta',
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
                    child: _results == null ? _generatingView() : _resultsView(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s5, 0, AppSpacing.s5, AppSpacing.s5),
                  child: _results == null ? _generatingActions() : _resultsActions(),
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
        if (!AppEnv.hasN8nWebhook) ...[
          const SizedBox(height: AppSpacing.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: AppRadii.mdAll,
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              'IA no configurada. Se mostrará una vista previa del diseño. Para activarla, configure N8N_WEBHOOK_URL en env/dev.json o env/prod.json.',
              style: AppTypography.caption.copyWith(color: const Color(0xFF92400E)),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.s6),
        FilledButton.icon(
          onPressed: _generating ? null : _generate,
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
    final actual = _current;
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
              'Vista previa (IA no configurada). Los tratamientos mostrados no se guardarán.',
              style: AppTypography.caption.copyWith(color: const Color(0xFF92400E)),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.subtle, borderRadius: AppRadii.mdAll),
          child: Row(
            children: [
              for (final modelo in _modelos)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final exists = modelo == 'COPILOT' ? _results?.copilot != null : _results?.deepseek != null;
                      if (exists) setState(() => _selectedModel = modelo);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedModel == modelo ? AppColors.card : Colors.transparent,
                        borderRadius: AppRadii.smAll,
                      ),
                      child: Text(
                        modelo,
                        style: AppTypography.label.copyWith(
                          color: _selectedModel == modelo ? const Color(0xFF2563EB) : AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        if (actual == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s7),
            child: Text('Sin resultados disponibles.', style: AppTypography.caption, textAlign: TextAlign.center),
          )
        else ...[
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
      ],
    );
  }

  Widget _resultsActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _generating ? null : _generate,
            child: Text(_generating ? 'Regenerando...' : 'Regenerar IA'),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving || _current == null ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Guardar Cambios'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }
}
