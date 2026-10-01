import '../../../core/errors/error_app.dart';
import '../domain/mensajes_error.dart';
import '../domain/usuario.dart';

/// Operaciones de autenticación. Todos los métodos lanzan [ErrorApp] con un
/// mensaje en español cuando algo falla.
abstract interface class AuthRepository {
  Usuario? get usuarioActual;

  /// Emite el usuario actual al escuchar y luego cada cambio de sesión.
  Stream<Usuario?> get cambiosDeSesion;

  Future<void> iniciarSesion({
    required String email,
    required String contrasena,
  });

  /// Devuelve `true` si la cuenta quedó activa de inmediato y `false` si
  /// falta confirmar el correo con el código enviado.
  Future<bool> registrarse({
    required String email,
    required String contrasena,
    required String nombre,
  });

  Future<void> confirmarRegistro({
    required String email,
    required String codigo,
  });

  Future<void> reenviarCodigoRegistro(String email);

  Future<void> enviarCodigoRecuperacion(String email);

  /// Valida el código de recuperación (abre sesión) y cambia la contraseña.
  Future<void> restablecerContrasena({
    required String email,
    required String codigo,
    required String nuevaContrasena,
  });

  Future<void> cerrarSesion();
}

/// Implementación usada cuando la app corre sin `env.json` (CI, pruebas):
/// nunca hay sesión y cualquier operación informa que falta el backend.
class SinBackendAuthRepository implements AuthRepository {
  const SinBackendAuthRepository();

  static final _error = ErrorApp(
    mensajeErrorAuth(CodigosError.sinBackend),
    codigo: CodigosError.sinBackend,
  );

  @override
  Usuario? get usuarioActual => null;

  @override
  Stream<Usuario?> get cambiosDeSesion => Stream.value(null);

  @override
  Future<void> iniciarSesion({
    required String email,
    required String contrasena,
  }) => Future.error(_error);

  @override
  Future<bool> registrarse({
    required String email,
    required String contrasena,
    required String nombre,
  }) => Future.error(_error);

  @override
  Future<void> confirmarRegistro({
    required String email,
    required String codigo,
  }) => Future.error(_error);

  @override
  Future<void> reenviarCodigoRegistro(String email) => Future.error(_error);

  @override
  Future<void> enviarCodigoRecuperacion(String email) => Future.error(_error);

  @override
  Future<void> restablecerContrasena({
    required String email,
    required String codigo,
    required String nuevaContrasena,
  }) => Future.error(_error);

  @override
  Future<void> cerrarSesion() async {}
}
