import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/traducir_error.dart';
import '../domain/historial.dart';

/// Lista y elimina los cálculos y simulaciones del usuario (RLS: cada
/// usuario solo ve y borra sus filas). Al borrar un cálculo, sus
/// simulaciones quedan sin vínculo (`on delete set null`).
abstract interface class HistorialRepository {
  Future<List<CalculoGuardado>> calculos();
  Future<List<SimulacionGuardada>> simulaciones();
  Future<void> eliminarCalculo(String id);
  Future<void> eliminarSimulacion(String id);
}

class SupabaseHistorialRepository implements HistorialRepository {
  SupabaseHistorialRepository(this._db);

  final SupabaseClient _db;

  Future<T> _ejecutar<T>(String que, Future<T> Function() accion) =>
      ejecutarRemoto(accion, accion: que);

  @override
  Future<List<CalculoGuardado>> calculos() => _ejecutar(
    'cargar tus cálculos',
    () async => [
      for (final f
          in await _db
              .from('calculos_consumo')
              .select('id, nombre, tipo_sistema, creado_en, resultados')
              .order('creado_en', ascending: false))
        CalculoGuardado.desdeFila(f),
    ],
  );

  @override
  Future<List<SimulacionGuardada>> simulaciones() => _ejecutar(
    'cargar tus simulaciones',
    () async => [
      for (final f
          in await _db
              .from('simulaciones_degradacion')
              .select(
                'id, politica, calculo_id, creado_en, parametros, resultados, serie',
              )
              .order('creado_en', ascending: false))
        SimulacionGuardada.desdeFila(f),
    ],
  );

  @override
  Future<void> eliminarCalculo(String id) => _ejecutar(
    'eliminar el cálculo',
    () => _db.from('calculos_consumo').delete().eq('id', id),
  );

  @override
  Future<void> eliminarSimulacion(String id) => _ejecutar(
    'eliminar la simulación',
    () => _db.from('simulaciones_degradacion').delete().eq('id', id),
  );
}

/// Sin `env.json`: historial vacío.
class SinBackendHistorialRepository implements HistorialRepository {
  const SinBackendHistorialRepository();

  @override
  Future<List<CalculoGuardado>> calculos() async => const [];

  @override
  Future<List<SimulacionGuardada>> simulaciones() async => const [];

  @override
  Future<void> eliminarCalculo(String id) async {}

  @override
  Future<void> eliminarSimulacion(String id) async {}
}
