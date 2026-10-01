/// Error con un mensaje listo para mostrar al usuario.
///
/// Las capas de datos convierten las excepciones de Supabase en `ErrorApp`
/// para que la interfaz no dependa de los tipos del backend.
class ErrorApp implements Exception {
  const ErrorApp(this.mensaje, {this.codigo});

  final String mensaje;

  /// Código técnico del error (por ejemplo `email_not_confirmed`), si lo hay.
  final String? codigo;

  @override
  String toString() => mensaje;
}
