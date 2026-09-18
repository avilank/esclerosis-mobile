import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';
import 'auth_api.dart';

/// Orquesta login + persistencia de la sesion (token cifrado en
/// [TokenStorage]).
class AuthRepository {
  AuthRepository({required this._api, required this._tokenStorage});

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(email: email, password: password);
    await _tokenStorage.saveToken(session.token);
    return session;
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> get hasSession => _tokenStorage.hasSession;
}
