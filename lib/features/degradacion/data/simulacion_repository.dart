import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/errors/mensajes_error.dart';
import '../../../core/errors/traducir_error.dart';
import '../domain/comparacion.dart';

/// Guarda las simulaciones del usuario en `simulaciones_degradacion`
/// (protegida por RLS: cada usuario solo ve sus filas).
abstract interface class SimulacionRepository {
  /// `calculoId` vincula la simulación con el cálculo del que partió.
  Future<void> guardar(ComparacionSimulacion simulacion, {String? calculoId});
}

class SupabaseSimulacionRepository implements SimulacionRepository {
  SupabaseSimulacionRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<void> guardar(ComparacionSimulacion simulacion, {String? calculoId}) =>
      ejecutarRemoto(() async {
        await _db.from('simulaciones_degradacion').insert({
          ...simulacion.aFila(),
          'calculo_id': ?calculoId,
        });
      }, accion: 'guardar la simulación');
}

class SinBackendSimulacionRepository implements SimulacionRepository {
  const SinBackendSimulacionRepository();

  @override
  Future<void> guardar(ComparacionSimulacion simulacion, {String? calculoId}) =>
      Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
