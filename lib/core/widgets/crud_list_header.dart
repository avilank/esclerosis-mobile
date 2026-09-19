import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'curved_teal_header_shell.dart';

/// Header curvo teal usado en las pantallas de listado/CRUD (Sedes, Areas,
/// Tratamientos, Categorias/Indicadores, Historias Clinicas), con titulo y
/// boton circular de accion (tipicamente "+"). Reemplaza al `AppBar` plano en
/// estas pantallas para acercarse al diseno de `esclerosis-movil` (ver manual
/// de usuario ESCLEROSIS - BI, figuras 5, 18, 21, 24, 27).
class CrudListHeader extends StatelessWidget {
  const CrudListHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onAdd,
    this.addIcon = Icons.add,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;
  final IconData addIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return CurvedTealHeaderShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s5,
          topInset + AppSpacing.s3,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading1.copyWith(color: Colors.white, fontSize: 24),
              ),
            ),
            ?trailing,
            if (onAdd != null)
              InkWell(
                onTap: onAdd,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(addIcon, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
