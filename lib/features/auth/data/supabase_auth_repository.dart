import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/errors/mensajes_error.dart';
import '../../../core/errors/traducir_error.dart';
import '../domain/politica_datos.dart';
import '../domain/usuario.dart';
import 'auth_repository.dart';

/// [AuthRepository] sobre Supabase Auth (correo + contraseña, códigos OTP).
///
/// La sesión la guarda `supabase_flutter` en el dispositivo
/// (SharedPreferences en Android, localStorage en web), así que no se pide
/// login cada vez que se abre la app.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  Usuario? get usuarioActual => _aUsuario(_auth.currentUser);

  @override
  Stream<Usuario?> get cambiosDeSesion async* {
    yield usuarioActual;
    yield* _auth.onAuthStateChange.map((e) => _aUsuario(e.session?.user));
  }

  @override
  Future<void> iniciarSesion({
    required String email,
    required String contrasena,
  }) => _ejecutar(
    () => _auth.signInWithPassword(email: email.trim(), password: contrasena),
  );

  @override
  Future<bool> registrarse({
    required String email,
    required String contrasena,
    required String nombre,
  }) => _ejecutar(() async {
    final respuesta = await _auth.signUp(
      email: email.trim(),
      password: contrasena,
      data: {
        'nombre': nombre.trim(),
        // Prueba de la autorización (Ley 1581): versión y fecha.
        'politica_datos': PoliticaDatos.version,
        'politica_aceptada_en': DateTime.now().toUtc().toIso8601String(),
      },
    );
    // Con confirmación de correo activa, Supabase responde "éxito" para un
    // correo ya registrado pero sin identidades (para no revelar cuentas).
    final identidades = respuesta.user?.identities;
    if (identidades != null && identidades.isEmpty) {
      throw ErrorApp(
        mensajeErrorAuth(CodigosError.usuarioExistente),
        codigo: CodigosError.usuarioExistente,
      );
    }
    return respuesta.session != null;
  }, limite: limiteEnvioCorreo);

  @override
  Future<void> confirmarRegistro({
    required String email,
    required String codigo,
  }) => _ejecutar(
    () => _auth.verifyOTP(
      email: email.trim(),
      token: codigo.trim(),
      type: OtpType.email,
    ),
  );

  @override
  Future<void> reenviarCodigoRegistro(String email) => _ejecutar(
    () => _auth.resend(email: email.trim(), type: OtpType.signup),
    limite: limiteEnvioCorreo,
  );

  @override
  Future<void> enviarCodigoRecuperacion(String email) => _ejecutar(
    () => _auth.resetPasswordForEmail(email.trim()),
    limite: limiteEnvioCorreo,
  );

  @override
  Future<void> verificarCodigoRecuperacion({
    required String email,
    required String codigo,
  }) => _ejecutar(
    () => _auth.verifyOTP(
      email: email.trim(),
      token: codigo.trim(),
      type: OtpType.recovery,
    ),
  );

  @override
  Future<void> cambiarContrasena(String nuevaContrasena) => _ejecutar(
    () => _auth.updateUser(UserAttributes(password: nuevaContrasena)),
  );

  @override
  Future<void> cerrarSesion() => _ejecutar(_auth.signOut);

  static Usuario? _aUsuario(User? user) =>
      user == null ? null : Usuario(id: user.id, email: user.email ?? '');

  static Future<T> _ejecutar<T>(
    Future<T> Function() accion, {
    Duration limite = limiteConsulta,
  }) => ejecutarRemoto(accion, limite: limite);
}
