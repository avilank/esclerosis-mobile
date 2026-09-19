import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';
import '../domain/usuario.dart';
import 'auth_api.dart';
import 'user_profile_storage.dart';

/// Orquesta login + persistencia de la sesion: token cifrado en
/// [TokenStorage] y perfil basico (rol incluido) en [UserProfileStorage],
/// para poder enrutar por rol sin depender de un endpoint `/auth/me` (que
/// `esclerosis-back` no expone hoy).
class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
    required UserProfileStorage profileStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _profileStorage = profileStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final UserProfileStorage _profileStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(email: email, password: password);
    await _tokenStorage.saveToken(session.token);
    await _profileStorage.save(session.usuario);
    return session;
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final session = await _api.register(username: username, email: email, password: password);
    await _tokenStorage.saveToken(session.token);
    await _profileStorage.save(session.usuario);
    return session;
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    await _profileStorage.clear();
  }

  Future<bool> get hasSession => _tokenStorage.hasSession;

  /// Perfil persistido de una sesion anterior (rol incluido), o `null` si no
  /// hay sesion o el perfil no se pudo leer.
  Usuario? get persistedUsuario => _profileStorage.read();
}
