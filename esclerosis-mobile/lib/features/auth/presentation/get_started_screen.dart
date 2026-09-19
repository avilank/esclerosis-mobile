import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Pantalla de bienvenida mostrada antes de iniciar sesion. Equivalente a
/// `esclerosis-movil/src/app/(auth)/get-started.tsx`.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  static const _bullets = [
    'Historia clinica y diagnosticos en un solo lugar.',
    'Seguimiento de tratamientos e indicadores clinicos.',
    'Pensada para pacientes, medicos y administradores.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadii.pillAll),
                  child: const Text(
                    'QUICKCARE',
                    style: TextStyle(color: AppColors.primaryHover, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text('SCLERK', style: AppTypography.display.copyWith(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Agenda, gestiona pacientes y revisa diagnosticos con una experiencia clara y rapida.',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.s6),
              Container(
                height: 180,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: AppRadii.xlAll),
                alignment: Alignment.center,
                child: const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 56),
              ),
              const SizedBox(height: AppSpacing.s6),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadii.xlAll,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final bullet in _bullets) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(child: Text(bullet, style: AppTypography.body)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    const SizedBox(height: AppSpacing.s2),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Comenzar'),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Ya tengo una cuenta'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
