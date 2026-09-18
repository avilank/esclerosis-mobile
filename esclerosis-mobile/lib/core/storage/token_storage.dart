import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento cifrado del token de sesion (Keychain en iOS, Keystore en
/// Android). Sin Google Play Services de por medio.
///
/// `esclerosis-back` emite un unico JWT sin flujo de refresh (ver
/// `AuthService.login` en el backend), asi que solo se guarda ese token: no
/// hay access/refresh separados como en `app-comunicador`.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  /// Copia en memoria del token. La lectura de secure storage es async, pero
  /// el interceptor de red necesita adjuntarlo de forma sincronica en cada
  /// request; esta cache se mantiene fresca desde login/logout.
  static String? _cachedToken;

  static String? get cachedToken => _cachedToken;

  Future<String?> readToken() async {
    final token = await _storage.read(key: _tokenKey);
    _cachedToken = token;
    return token;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _cachedToken = token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    _cachedToken = null;
  }

  Future<bool> get hasSession async => (await readToken()) != null;
}
