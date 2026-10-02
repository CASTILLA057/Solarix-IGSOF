import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../data/calculadora_repository.dart';
import '../data/recurso_solar.dart';
import '../domain/catalogos.dart';
import '../domain/modelos.dart';

final calculadoraRepositoryProvider = Provider<CalculadoraRepository>((ref) {
  if (!Env.supabaseConfigurado) return const SinBackendCalculadoraRepository();
  return SupabaseCalculadoraRepository(Supabase.instance.client);
});

final recursoSolarProvider = Provider<RecursoSolarService>(
  (ref) => NasaPowerRecursoSolar(),
);

final preciosProvider = FutureProvider<Precios>(
  (ref) => ref.watch(calculadoraRepositoryProvider).obtenerPrecios(),
);

final ciudadesProvider = FutureProvider<List<Ciudad>>(
  (ref) => ref.watch(calculadoraRepositoryProvider).obtenerCiudades(),
);
