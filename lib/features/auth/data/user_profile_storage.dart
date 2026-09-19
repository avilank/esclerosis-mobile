import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/usuario.dart';

/// Persiste el perfil basico del usuario (id, email, username, rol) para
/// poder enrutar por rol al reabrir la app.
///
/// No es informacion sensible (no son credenciales), asi que va en
/// `SharedPreferences` y no en `flutter_secure_storage` (eso queda reservado
/// para el token). `esclerosis-back` no expone un endpoint `/auth/me`, asi
/// que esta es la unica forma de recordar el rol sin volver a loguear.
class UserProfileStorage {
  UserProfileStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'auth_user_profile';

  Future<void> save(Usuario usuario) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'id': usuario.id,
        'email': usuario.email,
        'username': usuario.username,
        'rol': usuario.rol,
      }),
    );
  }

  Usuario? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _prefs.remove(_key);
}
