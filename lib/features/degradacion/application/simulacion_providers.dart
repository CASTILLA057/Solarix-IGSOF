import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../data/simulacion_repository.dart';
import '../domain/comparacion.dart';

final simulacionRepositoryProvider = Provider<SimulacionRepository>((ref) {
  if (!Env.supabaseConfigurado) return const SinBackendSimulacionRepository();
  return SupabaseSimulacionRepository(Supabase.instance.client);
});

typedef EjecutorSimulacion = Future<ComparacionSimulacion> Function(
  SolicitudSimulacion solicitud,
);

/// Corre la simulación fuera del hilo de la interfaz con `compute()` (un
/// isolate en Android; en web se ejecuta en el mismo hilo, pero tarda poco).
/// Las pruebas lo reemplazan por una ejecución directa.
final ejecutorSimulacionProvider = Provider<EjecutorSimulacion>(
  (ref) =>
      (solicitud) => compute(simularComparacion, solicitud),
);
