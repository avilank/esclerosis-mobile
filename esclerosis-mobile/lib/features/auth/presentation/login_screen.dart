import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/auth_providers.dart';

/// Pantalla de login con el estilo "SCLERK / MEDICAL PORTAL" de
/// `esclerosis-movil` (ver `src/app/(auth)/login.tsx`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    final error = ref.read(authControllerProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.s4,
              left: AppSpacing.s4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: AppRadii.mdAll,
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: const Text(
                  'ACCESO SEGURO',
                  style: TextStyle(color: AppColors.primaryHover, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.s9),
                    Text(
                      'SCLERK',
                      style: AppTypography.display.copyWith(
                        color: AppColors.primaryHover,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      'MEDICAL PORTAL',
                      style: AppTypography.caption.copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.s5),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadii.xlAll,
                        border: Border.all(color: AppColors.subtle),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A0F172A), blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Iniciar sesión', style: AppTypography.heading1),
                            const SizedBox(height: 4),
                            Text('Usa tus credenciales institucionales', style: AppTypography.caption),
                            const SizedBox(height: AppSpacing.s5),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu correo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.s6),
                            FilledButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('ENTRAR'),
                            ),
                            const SizedBox(height: AppSpacing.s3),
                            OutlinedButton(
                              onPressed: () => context.push('/register'),
                              child: const Text('Crear nueva cuenta'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
