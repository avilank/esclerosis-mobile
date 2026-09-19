import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../data/informacion_data.dart';

/// Contenido educativo (indicadores y tratamientos) para pacientes y
/// medicos. Equivalente a
/// `esclerosis-movil/src/features/informacion/screens/InformacionScreen.tsx`,
/// simplificado a una sola version de contenido.
class InformacionScreen extends StatelessWidget {
  const InformacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onBack =
        Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CrudListHeader(title: 'Información', onBack: onBack),
            Material(
              color: AppColors.card,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Indicadores'),
                  Tab(text: 'Tratamientos'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [_IndicadoresTab(), _TratamientosTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadoresTab extends StatelessWidget {
  const _IndicadoresTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s5),
      itemCount: indicadoresInfo.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, index) {
        final item = indicadoresInfo[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primary),
            title: Text(item.titulo, style: Theme.of(context).textTheme.titleSmall),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            children: [
              _InfoRow(label: '¿Qué es?', value: item.queEs),
              _InfoRow(label: '¿Por qué importa?', value: item.porQueImporta),
              _InfoRow(label: 'Qué puedes hacer', value: item.accion),
            ],
          ),
        );
      },
    );
  }
}

class _TratamientosTab extends StatelessWidget {
  const _TratamientosTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s5),
      itemCount: tratamientosInfo.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, index) {
        final bucket = tratamientosInfo[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
            title: Text(bucket.grupo, style: Theme.of(context).textTheme.titleSmall),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            children: [
              for (final item in bucket.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                bucket.nota,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.primaryHover, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}
