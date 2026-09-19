import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../application/historia_clinica_providers.dart';
import '../domain/diagnostico.dart';
import 'diagnostico_detail_screen.dart';
import 'widgets/estado_salud_tag.dart';

/// Historia clinica del paciente logueado (rol `paciente`).
class MiHistoriaClinicaScreen extends ConsumerWidget {
  const MiHistoriaClinicaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiaAsync = ref.watch(miHistoriaClinicaProvider);

    final onBack =
        Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(miHistoriaClinicaProvider.future),
        child: historiaAsync.when(
          loading: () => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CrudListHeader(title: 'Mi historia clínica', onBack: onBack)),
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (error, _) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CrudListHeader(title: 'Mi historia clínica', onBack: onBack)),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s6),
                  child: Text(error.toString(), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          data: (historia) {
            if (historia == null) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: CrudListHeader(title: 'Mi historia clínica', onBack: onBack)),
                  const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s6),
                      child: Text(
                        'Todavía no tenés una historia clínica registrada.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            final paciente = historia.paciente;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: CrudListHeader(title: 'Mi historia clínica', onBack: onBack)),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.s5),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (paciente != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paciente.nombrePaciente,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.s1),
                                Text('DNI: ${paciente.dniPaciente}'),
                                Text('Edad: ${paciente.edadPaciente} años'),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.s6),
                      Text('Diagnósticos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.s3),
                      if (historia.diagnosticos.isEmpty)
                        const Text('Sin diagnósticos registrados todavía.'),
                      for (final diagnostico in historia.diagnosticos)
                        _DiagnosticoListTile(diagnostico: diagnostico),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DiagnosticoListTile extends StatelessWidget {
  const _DiagnosticoListTile({required this.diagnostico});

  final Diagnostico diagnostico;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: ListTile(
        title: Text(diagnostico.fechaDiagnostico),
        subtitle: Text(
          [diagnostico.gradoEnfermedad, diagnostico.medico?.nombre]
              .where((e) => e != null && e.isNotEmpty)
              .join(' · '),
        ),
        trailing: EstadoSaludTag(diagnostico: diagnostico),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DiagnosticoDetailScreen(idDiagnostico: diagnostico.idDiagnostico),
          ),
        ),

      ),
    );
  }
}
