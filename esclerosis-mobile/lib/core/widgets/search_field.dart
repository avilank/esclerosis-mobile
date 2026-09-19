import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Buscador flotante blanco con icono, usado debajo del `CrudListHeader` en
/// las pantallas de listado. Ver manual de usuario ESCLEROSIS - BI, figuras
/// 5, 18, 21, 24, 27, 28.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hintText, required this.onChanged, this.controller});

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.pillAll,
        boxShadow: const [BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          filled: true,
          fillColor: AppColors.card,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
          border: const OutlineInputBorder(
            borderRadius: AppRadii.pillAll,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.pillAll,
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadii.pillAll,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
