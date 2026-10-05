import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/errors/mensajes_error.dart';
import '../../../core/errors/traducir_error.dart';
import '../domain/comparacion.dart';
import '../domain/integracion.dart';

/// Guarda las simulaciones del usuario en `simulaciones_degradacion`
/// (protegida por RLS: cada usuario solo ve sus filas).
abstract interface class SimulacionRepository {
  /// `calculoId` vincula la simulación con el cálculo del que partió;
  /// `impacto` es su efecto en la inversión de ese cálculo (Etapa 12).
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
    ImpactoFinanciero? impacto,
  });
}

class SupabaseSimulacionRepository implements SimulacionRepository {
  SupabaseSimulacionRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
    ImpactoFinanciero? impacto,
  }) => ejecutarRemoto(() async {
    await _db.from('simulaciones_degradacion').insert({
      ...simulacion.aFila(financiero: impacto?.aMapa()),
      'calculo_id': ?calculoId,
    });
  }, accion: 'guardar la simulación');
}

class SinBackendSimulacionRepository implements SimulacionRepository {
  const SinBackendSimulacionRepository();

  @override
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
    ImpactoFinanciero? impacto,
  }) => Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
