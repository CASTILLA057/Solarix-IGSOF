import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../auth/domain/mensajes_error.dart';
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
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
  }) async {
    try {
      await _db.from('simulaciones_degradacion').insert({
        ...simulacion.aFila(),
        'calculo_id': ?calculoId,
      });
    } on PostgrestException {
      throw const ErrorApp('No se pudo guardar la simulación.');
    } catch (_) {
      throw ErrorApp(mensajeErrorAuth(CodigosError.sinConexion));
    }
  }
}

class SinBackendSimulacionRepository implements SimulacionRepository {
  const SinBackendSimulacionRepository();

  @override
  Future<void> guardar(ComparacionSimulacion simulacion, {String? calculoId}) =>
      Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
