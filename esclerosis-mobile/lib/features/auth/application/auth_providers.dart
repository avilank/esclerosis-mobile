import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../domain/usuario.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// [Dio] cableado con el interceptor de auth. Ante una sesion expirada,
/// invalida [authControllerProvider] para que el router redirija a /login.
final dioProvider = Provider<Dio>((ref) {
  return buildDioClient(
    tokenStorage: ref.read(tokenStorageProvider),
    onSessionExpired: () async {
      await ref.read(authControllerProvider.notifier).logout();
    },
  );
});

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.read(authApiProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

/// Estado de sesion: `null` = sin sesion, `Usuario` = logueado.
///
/// Nota: como `esclerosis-back` no expone un endpoint `/auth/me`, al
/// rehidratar (abrir la app con un token ya guardado) solo se puede verificar
/// que exista un token, no recuperar el `Usuario` completo sin volver a
/// loguear. `_usuario` queda en memoria solo tras un login exitoso en esta
/// sesion de la app.
class AuthController extends AsyncNotifier<Usuario?> {
  @override
  Future<Usuario?> build() async {
    final hasSession = await ref.read(authRepositoryProvider).hasSession;
    if (!hasSession) return null;
    // Hay token guardado pero no el perfil (sin endpoint /auth/me todavia).
    // Se trata como sesion valida; las pantallas que necesiten datos del
    // usuario deberán pedirlos a un endpoint propio cuando exista.
    return const Usuario(id: 0, email: '', username: '', rol: '');
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session =
          await ref.read(authRepositoryProvider).login(email: email, password: password);
      return session.usuario;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Usuario?>(
  AuthController.new,
);
