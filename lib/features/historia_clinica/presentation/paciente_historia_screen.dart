import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/historia_clinica.dart';
import 'widgets/estado_salud_tag.dart';

/// Historia clinica de UN paciente puntual, vista por su medico. Recibe la
/// [HistoriaClinica] ya cargada desde `MisPacientesScreen` (via `extra` de
/// go_router) para no volver a pegarle a la red.
class PacienteHistoriaScreen extends StatelessWidget {
  const PacienteHistoriaScreen({super.key, required this.historia});

  final HistoriaClinica historia;

  @override
  Widget build(BuildContext context) {
    final paciente = historia.paciente;

    return Scaffold(
      appBar: AppBar(title: Text(paciente?.nombrePaciente ?? 'Paciente')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          if (paciente != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DNI: ${paciente.dniPaciente}'),
                    Text('Edad: ${paciente.edadPaciente} años'),
                    Text('Género: ${paciente.generoPaciente}'),
                    if ((paciente.telefonoPaciente ?? '').isNotEmpty)
                      Text('Teléfono: ${paciente.telefonoPaciente}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s6),
          Text('Diagnósticos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s3),
          if (historia.diagnosticos.isEmpty) const Text('Sin diagnósticos registrados.'),
          for (final diagnostico in historia.diagnosticos)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: ListTile(
                title: Text(diagnostico.fechaDiagnostico),
                subtitle: Text(diagnostico.gradoEnfermedad),
                trailing: EstadoSaludTag(diagnostico: diagnostico),
                onTap: () => context.push('/diagnosticos/${diagnostico.idDiagnostico}'),
              ),
            ),
        ],
      ),
    );
  }
}
