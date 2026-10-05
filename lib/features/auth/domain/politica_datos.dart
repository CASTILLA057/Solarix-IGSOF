/// Política de tratamiento de datos personales de Solarix (Ley 1581 de 2012
/// y Decreto 1377 de 2013, compilado en el Decreto 1074 de 2015).
///
/// La versión se guarda con la cuenta al registrarse (metadatos del usuario
/// en Supabase Auth), como prueba de la autorización.
abstract final class PoliticaDatos {
  /// Fecha de esta versión; si el texto cambia, cambia también.
  static const version = '2026-10-05';

  static const correoContacto = 'solarixapp@gmail.com';

  static const secciones = <(String, String)>[
    (
      'Responsable',
      'Santiago Castilla, autor de Solarix, proyecto académico de la '
          'Universidad Francisco de Paula Santander Ocaña (Ocaña, Norte de '
          'Santander, Colombia). Contacto: $correoContacto.',
    ),
    (
      'Qué datos se recogen',
      'Con cuenta: tu correo, tu nombre, la ciudad que elijas en tu '
          'perfil, y los cálculos y simulaciones que guardes (consumo, '
          'equipos, lugar, clima, resultados). Tu contraseña no se guarda: '
          'Supabase guarda solo una huella cifrada que no se puede revertir.\n'
          'Sin cuenta ("Probar sin cuenta") no se guarda ningún dato personal.\n'
          'Si usas "Mi ubicación", tus coordenadas aproximadas se envían a NASA '
          'POWER solo para consultar el clima y no se guardan.',
    ),
    (
      'Para qué se usan',
      'Para crear y proteger tu cuenta, enviarte los códigos de verificación '
          'y de recuperación de contraseña, y guardar tus cálculos y '
          'simulaciones para que los veas en el historial. No se venden ni '
          'se usan para publicidad.',
    ),
    (
      'Quién más los trata',
      'Supabase guarda la cuenta y los datos (servidores en Estados Unidos) y '
          'Brevo envía los correos (Unión Europea). Ambos actúan como '
          'encargados y solo los usan para prestar ese servicio. Al aceptar, '
          'autorizas esta transferencia internacional.',
    ),
    (
      'Tus derechos',
      'Conocer, actualizar y rectificar tus datos; pedir prueba de esta '
          'autorización; saber cómo se usan; revocar la autorización y pedir '
          'que se borren; presentar quejas ante la Superintendencia de '
          'Industria y Comercio; y acceder a ellos gratis.',
    ),
    (
      'Cómo ejercerlos',
      'En la app: edita tus datos en "Mi perfil" y usa "Eliminar mi cuenta" '
          'para borrar la cuenta y todo lo guardado, de inmediato. También '
          'puedes escribir a $correoContacto: las consultas se responden en '
          'máximo 10 días hábiles y los reclamos en máximo 15.',
    ),
    (
      'Seguridad y conservación',
      'Cada usuario solo puede ver y cambiar sus propios datos (reglas de '
          'acceso en la base de datos) y la conexión va cifrada. Los datos se '
          'conservan mientras tengas la cuenta; al eliminarla se borran.',
    ),
    (
      'Vigencia',
      'Esta política rige desde el 5 de octubre de 2026 (versión $version). '
          'Si cambia, la app te lo indicará.',
    ),
  ];
}
