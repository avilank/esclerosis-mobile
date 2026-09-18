import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_placeholder_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router de la app. Redirige segun el estado de autenticacion:
/// - rehidratando (loading) -> /splash
/// - sin sesion             -> /login
/// - con sesion             -> /
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading) {
        if (loc == '/login' || loc == '/splash') return null;
        return '/splash';
      }

      final isAuth = auth.value != null;
      if (!isAuth) {
        return loc == '/login' ? null : '/login';
      }

      if (loc == '/splash' || loc == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
});
