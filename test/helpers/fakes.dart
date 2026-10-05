import 'dart:async';

import 'package:solarix/core/errors/error_app.dart';
import 'package:solarix/features/auth/data/auth_repository.dart';
import 'package:solarix/features/auth/data/perfil_repository.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/auth/domain/usuario.dart';

/// [AuthRepository] en memoria para pruebas: registra las llamadas y permite
/// simular errores con [errorSiguiente].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this._usuario});

  static const usuarioPrueba = Usuario(id: 'u-1', email: 'ana@correo.com');

  Usuario? _usuario;
  final _cambios = StreamController<Usuario?>.broadcast();
  final llamadas = <String>[];

  /// Si no es `null`, la próxima operación lanza este error.
  ErrorApp? errorSiguiente;

  /// Valor que devuelve [registrarse] (cuenta activa de inmediato o no).
  bool registroActivo = false;

  void _emitir(Usuario? usuario) {
    _usuario = usuario;
    _cambios.add(usuario);
  }

  Future<void> _operacion(String nombre, [void Function()? efecto]) async {
    llamadas.add(nombre);
    final error = errorSiguiente;
    if (error != null) {
      errorSiguiente = null;
      throw error;
    }
    efecto?.call();
  }

  @override
  Usuario? get usuarioActual => _usuario;

  @override
  Stream<Usuario?> get cambiosDeSesion async* {
    yield _usuario;
    yield* _cambios.stream;
  }

  @override
  Future<void> iniciarSesion({
    required String email,
    required String contrasena,
  }) => _operacion(
    'iniciarSesion:$email',
    () => _emitir(Usuario(id: 'u-1', email: email)),
  );

  @override
  Future<bool> registrarse({
    required String email,
    required String contrasena,
    required String nombre,
  }) async {
    await _operacion('registrarse:$email:$nombre', () {
      if (registroActivo) _emitir(Usuario(id: 'u-1', email: email));
    });
    return registroActivo;
  }

  @override
  Future<void> confirmarRegistro({
    required String email,
    required String codigo,
  }) => _operacion(
    'confirmarRegistro:$email:$codigo',
    () => _emitir(Usuario(id: 'u-1', email: email)),
  );

  @override
  Future<void> reenviarCodigoRegistro(String email) =>
      _operacion('reenviarCodigoRegistro:$email');

  @override
  Future<void> enviarCodigoRecuperacion(String email) =>
      _operacion('enviarCodigoRecuperacion:$email');

  @override
  Future<void> verificarCodigoRecuperacion({
    required String email,
    required String codigo,
  }) => _operacion(
    'verificarCodigoRecuperacion:$email:$codigo',
    () => _emitir(Usuario(id: 'u-1', email: email)),
  );

  @override
  Future<void> cambiarContrasena(String nuevaContrasena) =>
      _operacion('cambiarContrasena');

  @override
  Future<void> cerrarSesion() =>
      _operacion('cerrarSesion', () => _emitir(null));
}

/// [PerfilRepository] en memoria para pruebas.
class FakePerfilRepository implements PerfilRepository {
  FakePerfilRepository(this.perfil);

  Perfil perfil;
  final guardados = <Perfil>[];

  @override
  Future<Perfil> obtener(String usuarioId) async => perfil;

  @override
  Future<void> guardar(Perfil perfil) async {
    guardados.add(perfil);
    this.perfil = perfil;
  }

  /// Veces que se pidió eliminar la cuenta.
  var cuentasEliminadas = 0;

  @override
  Future<void> eliminarCuenta() async => cuentasEliminadas++;
}
