/// Validadores de los formularios de autenticación y perfil.
///
/// Cada uno devuelve `null` si el valor es válido, o el mensaje de error.
abstract final class Validadores {
  static const longitudMinimaContrasena = 8;
  static const longitudMaximaNombre = 80;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _codigo = RegExp(r'^\d{6,10}$');
  static final _letra = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
  static final _digito = RegExp(r'\d');

  static String? email(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu correo.';
    if (!_email.hasMatch(v)) return 'El correo no es válido.';
    return null;
  }

  /// Contraseña nueva (registro o recuperación).
  static String? contrasena(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Escribe una contraseña.';
    if (v.length < longitudMinimaContrasena) {
      return 'Debe tener al menos $longitudMinimaContrasena caracteres.';
    }
    if (!_letra.hasMatch(v) || !_digito.hasMatch(v)) {
      return 'Debe tener letras y números.';
    }
    return null;
  }

  /// Contraseña para iniciar sesión: solo se exige que no esté vacía.
  static String? contrasenaRequerida(String? valor) =>
      (valor ?? '').isEmpty ? 'Escribe tu contraseña.' : null;

  static String? confirmacion(String? valor, String original) {
    if ((valor ?? '').isEmpty) return 'Repite la contraseña.';
    if (valor != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  /// Código numérico enviado al correo.
  static String? codigo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Escribe el código que llegó a tu correo.';
    if (!_codigo.hasMatch(v)) return 'El código solo tiene números.';
    return null;
  }

  static String? nombre(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu nombre.';
    if (v.length > longitudMaximaNombre) {
      return 'Máximo $longitudMaximaNombre caracteres.';
    }
    return null;
  }
}
