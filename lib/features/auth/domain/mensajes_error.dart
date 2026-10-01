/// Códigos de error que la interfaz necesita reconocer.
abstract final class CodigosError {
  static const sinConexion = 'sin_conexion';
  static const sinBackend = 'sin_backend';
  static const correoSinConfirmar = 'email_not_confirmed';
  static const usuarioExistente = 'user_already_exists';
}

/// Traduce un código de error de Supabase Auth a un mensaje en español.
String mensajeErrorAuth(String? codigo) => switch (codigo) {
  'invalid_credentials' => 'Correo o contraseña incorrectos.',
  CodigosError.correoSinConfirmar =>
    'Aún no confirmas tu correo. Escribe el código que te enviamos.',
  CodigosError.usuarioExistente ||
  'email_exists' => 'Ya existe una cuenta con ese correo.',
  'weak_password' => 'La contraseña es muy débil. Usa al menos 8 caracteres con letras y números.',
  'same_password' => 'La nueva contraseña debe ser distinta a la anterior.',
  'otp_expired' => 'El código no es válido o ya expiró. Pide uno nuevo.',
  'over_email_send_rate_limit' =>
    'Se enviaron demasiados correos. Espera unos minutos e intenta de nuevo.',
  'over_request_rate_limit' =>
    'Demasiados intentos. Espera un momento e intenta de nuevo.',
  CodigosError.sinConexion =>
    'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
  CodigosError.sinBackend =>
    'La app no tiene configurado Supabase (falta env.json).',
  _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
};
