import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_app.dart';
import 'mensajes_error.dart';

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
