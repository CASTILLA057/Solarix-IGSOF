/// Rutas de la app.
abstract final class Rutas {
  static const inicio = '/';
  static const perfil = '/perfil';
  static const login = '/login';
  static const registro = '/registro';
  static const verificar = '/verificar';
  static const recuperar = '/recuperar';

  /// Pantallas que solo tienen sentido sin sesión: con sesión se va al inicio.
  static const soloSinSesion = {login, registro, verificar};

  /// Pantallas accesibles con o sin sesión. Recuperar está aquí porque al
  /// validar el código Supabase abre la sesión antes de cambiar la contraseña.
  static const publicas = {...soloSinSesion, recuperar};

  static String verificarCon(String email) =>
      Uri(path: verificar, queryParameters: {'email': email}).toString();
}

/// Decide a dónde redirigir según haya o no sesión. `null` = no redirigir.
String? redirigir({required bool autenticado, required String ubicacion}) {
  if (!autenticado && !Rutas.publicas.contains(ubicacion)) return Rutas.login;
  if (autenticado && Rutas.soloSinSesion.contains(ubicacion)) {
    return Rutas.inicio;
  }
  return null;
}
