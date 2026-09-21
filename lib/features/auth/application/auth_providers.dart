import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/user_profile_storage.dart';
import '../domain/usuario.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Se sobreescribe en `main.dart` con la instancia ya inicializada
/// (`SharedPreferences.getInstance()` es async y tiene que resolverse antes
/// de `runApp`).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider no fue inicializado');
});

final userProfileStorageProvider = Provider<UserProfileStorage>((ref) {
  return UserProfileStorage(ref.read(sharedPreferencesProvider));
});

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
    profileStorage: ref.read(userProfileStorageProvider),
  );
});

/// Estado de sesion: `null` = sin sesion, `Usuario` = logueado (con rol).
///
/// `esclerosis-back` no expone un endpoint `/auth/me`, asi que el rol se
/// persiste localmente en el login (ver [UserProfileStorage]) para poder
/// enrutar por rol al reabrir la app sin tener que volver a loguear.
class AuthController extends AsyncNotifier<Usuario?> {
  @override
  Future<Usuario?> build() async {
    final repository = ref.read(authRepositoryProvider);
    final hasSession = await repository.hasSession;
    if (!hasSession) return null;

    final usuario = repository.persistedUsuario;
    if (usuario == null) {
      // Token valido pero sin perfil persistido (instalacion previa a este
      // cambio, o perfil corrupto): se limpia todo para forzar un login
      // limpio y no mostrar una UI sin rol.
      await repository.logout();
      return null;
    }
    return usuario;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session =
          await ref.read(authRepositoryProvider).login(email: email, password: password);
      return session.usuario;
    });
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authRepositoryProvider).register(
            username: username,
            email: email,
            password: password,
          );
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

/// Rol del usuario logueado (`admin` | `medico` | `paciente`), o `null` sin
/// sesion.
final rolActualProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).value?.rol;
});

/// `true` solo para el rol admin. El backend restringe la escritura de los
/// catalogos (tratamientos, indicadores, categorias) a admin: la UI oculta esas
/// acciones para que el medico no reciba un 403 al pulsarlas.
final esAdminProvider = Provider<bool>((ref) {
  return ref.watch(rolActualProvider) == 'admin';
});

/// `true` solo para el rol paciente. Antes trataba `null` como paciente, lo
/// que ocultaba funciones a los demás roles mientras la sesión rehidrataba.
final esPacienteProvider = Provider<bool>((ref) {
  return ref.watch(rolActualProvider) == 'paciente';
});

/// `true` para el rol médico.
final esMedicoProvider = Provider<bool>((ref) {
  return ref.watch(rolActualProvider) == 'medico';
});

/// `true` para el rol secretaria (agenda citas y da de alta pacientes).
final esSecretariaProvider = Provider<bool>((ref) {
  return ref.watch(rolActualProvider) == 'secretaria';
});

/// Roles que pueden administrar la agenda (crear, reprogramar, cancelar).
final puedeGestionarCitasProvider = Provider<bool>((ref) {
  final rol = ref.watch(rolActualProvider);
  return rol == 'admin' || rol == 'secretaria';
});
