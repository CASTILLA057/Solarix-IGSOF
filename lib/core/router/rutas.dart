/// Rutas de la app.
///
/// Las pantallas de acceso son hijas de la bienvenida, así el botón "atrás"
/// (web y Android) siempre vuelve a ella.
abstract final class Rutas {
  static const inicio = '/';
  static const perfil = '/perfil';
  static const calculadora = '/calculadora';
  static const resultados = '$calculadora/resultados';
  static const simulacion = '/simulacion';
  static const resultadosSimulacion = '$simulacion/resultados';
  static const historial = '/historial';
  static const detalleSimulacion = '$historial/simulacion';
  static const bienvenida = '/bienvenida';
  static const login = '$bienvenida/login';
  static const registro = '$bienvenida/registro';
  static const verificar = '$bienvenida/verificar';
  static const recuperar = '$bienvenida/recuperar';
  static const politicaDatos = '/politica-datos';

  /// Pantallas que solo tienen sentido sin sesión: con sesión se va al inicio.
  static const soloSinSesion = {bienvenida, login, registro, verificar};

  /// Pantallas accesibles con o sin sesión. Recuperar está aquí porque al
  /// validar el código Supabase abre la sesión antes de cambiar la contraseña.
  static const publicas = {...soloSinSesion, recuperar, politicaDatos};

  /// Pantallas para quien prueba sin cuenta (Etapa 12): calcular y simular.
  /// El perfil y el historial siguen pidiendo sesión.
  static const paraInvitados = {
    inicio,
    calculadora,
    resultados,
    simulacion,
    resultadosSimulacion,
  };

  static String verificarCon(String email) =>
      Uri(path: verificar, queryParameters: {'email': email}).toString();
}

/// Decide a dónde redirigir según haya o no sesión (y si se está probando
/// sin cuenta). `null` = no redirigir.
String? redirigir({
  required bool autenticado,
  required String ubicacion,
  bool invitado = false,
}) {
  if (!autenticado &&
      !Rutas.publicas.contains(ubicacion) &&
      !(invitado && Rutas.paraInvitados.contains(ubicacion))) {
    return Rutas.bienvenida;
  }
  if (autenticado && Rutas.soloSinSesion.contains(ubicacion)) {
    return Rutas.inicio;
  }
  return null;
}
