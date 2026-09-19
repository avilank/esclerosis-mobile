import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/crud_list_header.dart';
import '../../../core/widgets/module_card.dart';
import 'categorias_indicadores_list_screen.dart';
import 'indicadores_clinicos_list_screen.dart';

/// Pantalla de entrada al modulo de Indicadores: ofrece los dos accesos
/// "Categorías" e "Indicadores clínicos" (ver manual de usuario ESCLEROSIS -
/// BI, figura 27 "Vista de indicadores").
class IndicadoresHomeScreen extends StatelessWidget {
  const IndicadoresHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CrudListHeader(
            title: 'Indicadores',
            onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModuleCard(
                  title: 'Categorías',
                  subtitle: 'Categorías de indicadores clínicos',
                  icon: Icons.folder_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriasIndicadoresListScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                ModuleCard(
                  title: 'Indicadores clínicos',
                  subtitle: 'Catálogo de indicadores usados en diagnósticos',
                  icon: Icons.show_chart,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const IndicadoresClinicosListScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
