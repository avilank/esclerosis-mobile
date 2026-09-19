import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/get_started_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/historia_clinica/domain/historia_clinica.dart';
import '../../features/historia_clinica/presentation/diagnostico_detail_screen.dart';
import '../../features/historia_clinica/presentation/paciente_historia_screen.dart';
import '../../features/home/presentation/role_home_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

const _publicLocations = {'/get-started', '/login', '/register'};

/// Router de la app. Redirige segun el estado de autenticacion:
/// - rehidratando (loading) -> /splash
/// - sin sesion             -> /get-started (o /login, /register)
/// - con sesion             -> /
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading) {
        if (loc == '/splash') return null;
        return _publicLocations.contains(loc) ? null : '/splash';
      }

      final isAuth = auth.value != null;
      if (!isAuth) {
        return _publicLocations.contains(loc) ? null : '/get-started';
      }

      if (loc == '/splash' || _publicLocations.contains(loc)) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleHomeScreen(),
      ),
      GoRoute(
        path: '/pacientes/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! HistoriaClinica) {
            // Se navega siempre con `extra` desde MisPacientesScreen; sin eso
            // no hay forma de reconstruir la pantalla (no existe todavia un
            // GET /historias-clinicas/:id consumido por la app).
            return const RoleHomeScreen();
          }
          return PacienteHistoriaScreen(historia: extra);
        },
      ),
      GoRoute(
        path: '/diagnosticos/:id',
        builder: (context, state) => DiagnosticoDetailScreen(
          idDiagnostico: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
});
