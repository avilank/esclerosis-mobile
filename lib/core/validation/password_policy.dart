/// Politica de contraseñas del proyecto. Tiene que coincidir con la del backend
/// (`RegisterDto` / `CreateUsuarioDto`): minimo 8 caracteres, con letras y
/// numeros. Validarlo tambien en el cliente evita un 400 despues de completar
/// todo el formulario.
class PasswordPolicy {
  const PasswordPolicy._();

  static const int minLength = 8;

  static final RegExp _letrasYNumeros = RegExp(r'(?=.*[a-zA-Z])(?=.*\d)');

  /// Devuelve el mensaje de error, o `null` si la contraseña es valida.
  static String? validate(String? value, {bool requerida = true}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return requerida ? 'La contraseña es obligatoria' : null;
    }
    if (password.length < minLength) {
      return 'Mínimo $minLength caracteres';
    }
    if (!_letrasYNumeros.hasMatch(password)) {
      return 'Debe combinar letras y números';
    }
    return null;
  }

  static const String helperText = 'Mínimo 8 caracteres, con letras y números';
}
