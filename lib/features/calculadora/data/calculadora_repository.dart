import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/errors/mensajes_error.dart';
import '../../../core/errors/traducir_error.dart';
import '../domain/modelos.dart';

/// Cálculos guardados en Supabase (tabla `calculos_consumo`, protegida por
/// RLS). Los precios de referencia y las ciudades viven solo en Dart
/// ([Precios.referencia], `ciudadesBase`): la calculadora no depende de la
/// conexión ni de la sesión (Etapa 12).
abstract interface class CalculadoraRepository {
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
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) => ejecutarRemoto(() async {
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
  }, accion: 'guardar el cálculo');
}

/// Sin `env.json` (CI, pruebas): sin guardado.
class SinBackendCalculadoraRepository implements CalculadoraRepository {
  const SinBackendCalculadoraRepository();

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) => Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
