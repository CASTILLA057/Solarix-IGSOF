import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../data/historial_repository.dart';
import '../domain/historial.dart';

final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  if (!Env.supabaseConfigurado) return const SinBackendHistorialRepository();
  return SupabaseHistorialRepository(Supabase.instance.client);
});

/// Cálculos guardados, del más reciente al más antiguo.
final calculosGuardadosProvider =
    FutureProvider.autoDispose<List<CalculoGuardado>>(
      (ref) => ref.watch(historialRepositoryProvider).calculos(),
    );

/// Simulaciones guardadas, de la más reciente a la más antigua.
final simulacionesGuardadasProvider =
    FutureProvider.autoDispose<List<SimulacionGuardada>>(
      (ref) => ref.watch(historialRepositoryProvider).simulaciones(),
    );
