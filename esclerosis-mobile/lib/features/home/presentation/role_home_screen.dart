import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/tab_root_navigator.dart';
import '../../administracion/presentation/roles_permisos_screen.dart';
import '../../administracion/presentation/usuarios_list_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../../historia_clinica/presentation/diagnosticos_list_screen.dart';
import '../../historia_clinica/presentation/mis_pacientes_screen.dart';
import '../../informacion/presentation/informacion_screen.dart';
import '../../reportes/presentation/reportes_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class _TabItem {
  const _TabItem(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}

/// Punto de entrada `/` de la app: shell con tabs inferiores segun el rol del
/// usuario logueado, replicando `tabsConfig.ts` de `esclerosis-movil`.
/// `esclerosis-back` define los roles `paciente`, `medico` y `admin`.
class RoleHomeScreen extends ConsumerStatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  ConsumerState<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends ConsumerState<RoleHomeScreen> {
  int _index = 0;
  String? _rolActual;

  List<_TabItem> _tabsFor(String rol) {
    switch (rol) {
      case 'admin':
        return const [
          _TabItem('Usuarios', Icons.people_outline, UsuariosListScreen()),
          _TabItem('Roles', Icons.shield_outlined, RolesPermisosScreen()),
          _TabItem('Inicio', Icons.home_outlined, DashboardScreen()),
          _TabItem('Reportes', Icons.bar_chart_outlined, ReportesScreen()),
          _TabItem('Perfil', Icons.person_outline, ProfileScreen()),
        ];
      case 'medico':
        return const [
          _TabItem('Diagnósticos', Icons.add_circle_outline, DiagnosticosListScreen()),
          _TabItem('Historia Clínica', Icons.folder_shared_outlined, MisPacientesScreen()),
          _TabItem('Inicio', Icons.home_outlined, DashboardScreen()),
          _TabItem('Reportes', Icons.bar_chart_outlined, ReportesScreen()),
          _TabItem('Perfil', Icons.person_outline, ProfileScreen()),
        ];
      default:
        return const [
          _TabItem('Información', Icons.info_outline, InformacionScreen()),
          _TabItem('Inicio', Icons.home_outlined, DashboardScreen()),
          _TabItem('Perfil', Icons.person_outline, ProfileScreen()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(authControllerProvider).value;
    final rol = usuario?.rol ?? 'paciente';
    final tabs = _tabsFor(rol);

    if (_rolActual != rol) {
      _rolActual = rol;
      final homeIndex = tabs.indexWhere((t) => t.label == 'Inicio');
      _index = homeIndex >= 0 ? homeIndex : 0;
    }
    final safeIndex = _index < tabs.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: [
          for (final tab in tabs) TabRootNavigator(root: tab.screen),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Sin esto, Flutter usa `shifting` por defecto cuando hay mas de 3
        // items (rol admin/medico tienen 5): ese tipo anima el fondo de la
        // barra a blanco y oculta las etiquetas no seleccionadas, dando la
        // sensacion de una barra "en blanco" / rota.
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        onTap: (value) => setState(() => _index = value),
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
