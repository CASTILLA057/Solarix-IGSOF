import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../auth/domain/mensajes_error.dart';
import '../domain/comparacion.dart';

/// Guarda las simulaciones del usuario en `simulaciones_degradacion`
/// (protegida por RLS: cada usuario solo ve sus filas).
abstract interface class SimulacionRepository {
  Future<void> guardar(ComparacionSimulacion simulacion);
}

class SupabaseSimulacionRepository implements SimulacionRepository {
  SupabaseSimulacionRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<void> guardar(ComparacionSimulacion simulacion) async {
    try {
      await _db.from('simulaciones_degradacion').insert(simulacion.aFila());
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
  Future<void> guardar(ComparacionSimulacion simulacion) =>
      Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
