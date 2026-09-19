import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Avatar circular con las iniciales (hasta 2 letras) de un nombre, usado en
/// las tarjetas de listado de administracion (sedes, areas, tratamientos,
/// historias clinicas, indicadores). Ver manual de usuario "ESCLEROSIS - BI",
/// figuras 5, 18, 21, 24 (circulo verde claro con iniciales en verde oscuro).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.text,
    this.size = 44,
    this.background = AppColors.secondary,
    this.foreground = AppColors.primaryHover,
  });

  final String text;
  final double size;
  final Color background;
  final Color foreground;

  static String initialsOf(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initialsOf(text),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}
