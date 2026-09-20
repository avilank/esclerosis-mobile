import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/module_card.dart';
import '../../../core/widgets/role_header.dart';
import '../../administracion/application/administracion_providers.dart';
import '../../administracion/presentation/areas_list_screen.dart';
import '../../administracion/presentation/sedes_list_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/application/historia_clinica_providers.dart';
import '../../historia_clinica/presentation/diagnostico_form_screen.dart';
import '../../historia_clinica/presentation/diagnosticos_admin_list_screen.dart';
import '../../historia_clinica/presentation/historias_clinicas_list_screen.dart';
import '../../historia_clinica/presentation/mi_historia_clinica_screen.dart';
import '../../indicadores/presentation/indicadores_home_screen.dart';
import '../../informacion/presentation/informacion_screen.dart';
import '../../reportes/presentation/reportes_screen.dart';
import '../../tratamientos/presentation/tratamientos_list_screen.dart';

/// Pantalla "Inicio" del dashboard por rol, con tarjetas de acceso a los
/// modulos que no viven en los tabs inferiores. Equivalente a
/// `esclerosis-movil/src/features/dashboard/screens/DashboardScreen.tsx`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).value;
    if (usuario == null) return const SizedBox.shrink();

    final List<Widget> cards;
    String subtitle;
    List<RoleHeaderStat> stats = const [];

    switch (usuario.rol) {
      case 'admin':
        subtitle = 'Admin';
        // Stats reales del sistema: usuarios, areas y sedes (ver manual de
        // usuario ESCLEROSIS - BI, figura 35 "Dashboard principal rol
        // Administrador").
        final usuariosCount = ref.watch(usuariosListProvider).value?.length;
        final areasCount = ref.watch(areasListProvider).value?.length;
        final sedesCount = ref.watch(sedesListProvider).value?.length;
        stats = [
          RoleHeaderStat(label: 'Usuarios', value: usuariosCount ?? '—'),
          RoleHeaderStat(label: 'Áreas', value: areasCount ?? '—'),
          RoleHeaderStat(label: 'Sedes', value: sedesCount ?? '—'),
        ];
        cards = [
          ModuleCard(
            title: 'Historia Clínica',
            icon: Icons.folder_shared_outlined,
            onTap: () => _open(context, const HistoriasClinicasListScreen()),
          ),
          ModuleCard(
            title: 'Diagnósticos',
            icon: Icons.medical_information_outlined,
            onTap: () => _open(context, const DiagnosticosAdminListScreen()),
          ),
          ModuleCard(
            title: 'Sedes',
            icon: Icons.map_outlined,
            onTap: () => _open(context, const SedesListScreen()),
          ),
          ModuleCard(
            title: 'Áreas',
            icon: Icons.business_outlined,
            onTap: () => _open(context, const AreasListScreen()),
          ),
          ModuleCard(
            title: 'Tratamientos',
            icon: Icons.medication_outlined,
            onTap: () => _open(context, const TratamientosListScreen()),
          ),
          ModuleCard(
            title: 'Información',
            icon: Icons.info_outline,
            onTap: () => _open(context, const InformacionScreen()),
          ),
          ModuleCard(
            title: 'Indicadores',
            icon: Icons.bar_chart_outlined,
            onTap: () => _open(context, const IndicadoresHomeScreen()),
          ),
        ];
        break;
      case 'medico':
        subtitle = 'Médico: ${usuario.username}';
        // Stats: PACIENTES criticos / controlados. Se piden al backend
        // (`/diagnosticos/stats/:idMedico`), que toma el ultimo diagnostico de
        // cada paciente; contarlos aca sobre la lista de diagnosticos hacia que
        // un paciente con varios diagnosticos se contara varias veces.
        final estadisticas = ref.watch(misEstadisticasProvider).value;
        stats = [
          RoleHeaderStat(label: 'Críticos', value: estadisticas?.criticos ?? '—'),
          RoleHeaderStat(
            label: 'Controlados',
            value: estadisticas?.controlados ?? '—',
          ),
        ];
        cards = [
          ModuleCard(
            title: 'Tratamientos',
            icon: Icons.medication_outlined,
            onTap: () => _open(context, const TratamientosListScreen()),
          ),
          ModuleCard(
            title: 'Indicadores',
            icon: Icons.bar_chart_outlined,
            onTap: () => _open(context, const IndicadoresHomeScreen()),
          ),
          ModuleCard(
            title: 'Diagnosticar',
            subtitle: 'Crear un nuevo diagnóstico',
            icon: Icons.add_chart_outlined,
            onTap: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const DiagnosticoFormScreen()),
              );
              if (created == true) {
                ref.invalidate(misDiagnosticosProvider);
                ref.invalidate(misEstadisticasProvider);
              }
            },
          ),
          ModuleCard(
            title: 'Información',
            icon: Icons.info_outline,
            onTap: () => _open(context, const InformacionScreen()),
          ),
        ];
        break;
      default:
        subtitle = 'Paciente: ${usuario.username}';
        // Stat: numero de diagnosticos registrados (ver manual, figura 10).
        final historia = ref.watch(miHistoriaClinicaProvider).value;
        stats = [
          RoleHeaderStat(label: 'Diagnósticos', value: historia?.diagnosticos.length ?? 0),
        ];
        cards = [
          ModuleCard(
            title: 'Mi historia clínica',
            icon: Icons.folder_shared_outlined,
            onTap: () => _open(context, const MiHistoriaClinicaScreen()),
          ),
          ModuleCard(
            title: 'Reportes',
            icon: Icons.insert_chart_outlined,
            onTap: () => _open(context, const ReportesScreen()),
          ),
        ];
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          RoleHeader(title: 'Sclerk', subtitle: subtitle, stats: stats),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final card in cards) ...[card, const SizedBox(height: AppSpacing.s3)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
