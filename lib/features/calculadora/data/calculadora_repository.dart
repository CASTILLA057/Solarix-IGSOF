import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../auth/domain/mensajes_error.dart';
import '../domain/catalogos.dart';
import '../domain/modelos.dart';

/// Datos de la calculadora en Supabase: precios de referencia, ciudades y
/// cálculos guardados (tabla `calculos_consumo`, protegida por RLS).
abstract interface class CalculadoraRepository {
  /// Precios de referencia; si la tabla no responde, los valores locales.
  Future<Precios> obtenerPrecios();

  /// Ciudades con HSP; si la tabla no responde, la lista local.
  Future<List<Ciudad>> obtenerCiudades();

  /// Guarda el cálculo del usuario con sesión activa y devuelve su `id`
  /// (para vincular la simulación de degradación, Etapa 6).
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  );
}

class SupabaseCalculadoraRepository implements CalculadoraRepository {
  SupabaseCalculadoraRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<Precios> obtenerPrecios() async {
    try {
      final filas = await _db.from('precios_referencia').select('clave, valor');
      return Precios.desdeFilas({
        for (final f in filas)
          f['clave'] as String: (f['valor'] as num).toDouble(),
      });
    } catch (_) {
      return Precios.referencia;
    }
  }

  @override
  Future<List<Ciudad>> obtenerCiudades() async {
    try {
      final filas = await _db
          .from('ciudades')
          .select('nombre, departamento, hsp')
          .order('nombre');
      final ciudades = [for (final f in filas) Ciudad.desdeMapa(f)];
      return ciudades.isEmpty ? ciudadesBase : ciudades;
    } catch (_) {
      return ciudadesBase;
    }
  }

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) async {
    try {
      final fila = await _db
          .from('calculos_consumo')
          .insert({
            'nombre': entradas.nombre.trim().isEmpty
                ? null
                : entradas.nombre.trim(),
            'tipo_sistema': entradas.tipo.valorBd,
            'entradas': entradas.aMapa(),
            'resultados': resultado.aMapa(),
          })
          .select('id')
          .single();
      return fila['id'] as String;
    } on PostgrestException {
      throw const ErrorApp('No se pudo guardar el cálculo.');
    } catch (_) {
      throw ErrorApp(mensajeErrorAuth(CodigosError.sinConexion));
    }
  }
}

/// Sin `env.json` (CI, pruebas): datos locales y sin guardado.
class SinBackendCalculadoraRepository implements CalculadoraRepository {
  const SinBackendCalculadoraRepository();

  @override
  Future<Precios> obtenerPrecios() async => Precios.referencia;

  @override
  Future<List<Ciudad>> obtenerCiudades() async => ciudadesBase;

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) => Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
