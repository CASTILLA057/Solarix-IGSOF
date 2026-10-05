import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_app.dart';
import 'mensajes_error.dart';

/// Tiempo máximo de espera de una consulta al servidor. Sin internet, una
/// petición puede quedar colgada minutos (red que no responde, o Supabase
/// reintentando renovar la sesión); pasado este tiempo se avisa "sin
/// conexión" en vez de dejar la pantalla cargando.
const limiteConsulta = Duration(seconds: 5);

/// Operaciones que envían un correo (registro, reenviar código, recuperar
/// contraseña): el envío por SMTP puede tardar varios segundos aun con
/// buena conexión.
const limiteEnvioCorreo = Duration(seconds: 15);

/// Ejecuta una consulta al backend con [limite] de tiempo y traduce
/// cualquier error con [errorDesde].
Future<T> ejecutarRemoto<T>(
  Future<T> Function() consulta, {
  String accion = 'completar la operación',
  Duration limite = limiteConsulta,
}) async {
  try {
    return await consulta().timeout(limite);
  } catch (e) {
    throw errorDesde(e, accion: accion);
  }
}

/// Convierte cualquier error del backend en un [ErrorApp] con un mensaje
/// claro. [accion] completa el mensaje genérico: "No se pudo [accion]."
ErrorApp errorDesde(Object e, {String accion = 'completar la operación'}) {
  if (e is ErrorApp) return e;
  final codigo = switch (e) {
    _ when _proyectoPausado(e) => CodigosError.pausado,
    AuthRetryableFetchException() ||
    ClientException() ||
    TimeoutException() => CodigosError.sinConexion,
    // JWT vencido o inválido en una consulta a las tablas.
    PostgrestException(code: 'PGRST301' || 'PGRST303') =>
      CodigosError.sesionExpirada,
    // Límites de la migración de seguridad (Etapa 12).
    PostgrestException(:final message)
        when message.startsWith(CodigosError.limiteFilas) =>
      CodigosError.limiteFilas,
    PostgrestException(code: '23514', :final message)
        when message.contains('_tamano') =>
      CodigosError.datosMuyGrandes,
    AuthException(:final code?) => code,
    _ => null,
  };
  return codigo == null
      ? ErrorApp('No se pudo $accion. Intenta de nuevo.')
      : ErrorApp(mensajeErrorAuth(codigo), codigo: codigo);
}

/// Un proyecto pausado responde con el estado HTTP 540 ("Project paused").
bool _proyectoPausado(Object e) {
  final (estado, mensaje) = switch (e) {
    PostgrestException(:final code, :final message) => (code, message),
    AuthException(:final statusCode, :final message) => (statusCode, message),
    _ => (null, ''),
  };
  return estado == '540' || mensaje.toLowerCase().contains('project paused');
}
