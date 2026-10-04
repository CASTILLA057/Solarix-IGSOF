import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/helpers/flujo_completo.dart';

/// Recorrido de principio a fin en el celular contra el Supabase real
/// (`solarix`), con una cuenta de prueba ya confirmada. Lo que guarda lleva
/// un nombre único y se borra al terminar, aunque la prueba falle.
///
///     flutter test integration_test/supabase_real_test.dart
///       --dart-define-from-file=env.json --dart-define-from-file=prueba.json
///
/// `prueba.json` (fuera de git, ver `prueba.example.json`) tiene
/// PRUEBA_EMAIL y PRUEBA_CONTRASENA. Sin él, la prueba se omite.
const _email = String.fromEnvironment('PRUEBA_EMAIL');
const _contrasena = String.fromEnvironment('PRUEBA_CONTRASENA');
final _configurada =
    Env.supabaseConfigurado && _email.isNotEmpty && _contrasena.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login → calculadora → simulación → guardar → historial (Supabase real)',
    skip: !_configurada,
    (tester) async {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabasePublishableKey,
      );
      final cliente = Supabase.instance.client;
      // Empieza sin sesión (cierra la que hubiera en este celular).
      await cliente.auth.signOut();

      final nombre =
          'Prueba de integración ${DateTime.now().millisecondsSinceEpoch}';
      addTearDown(() => _limpiar(cliente, nombre));

      await tester.pumpWidget(const ProviderScope(child: SolarixApp()));
      await tester.pumpAndSettle();

      await iniciarSesion(tester, email: _email, contrasena: _contrasena);
      await calcularSimularYRevisar(tester, nombreCalculo: nombre);

      // En la base de datos: el cálculo y su simulación vinculada.
      final calculos = await cliente
          .from('calculos_consumo')
          .select('id')
          .eq('nombre', nombre);
      expect(calculos, hasLength(1));
      final simulaciones = await cliente
          .from('simulaciones_degradacion')
          .select('id')
          .eq('calculo_id', calculos.single['id'] as String);
      expect(simulaciones, hasLength(1));
    },
  );
}

/// Borra lo que guardó la prueba (solo filas con su nombre único, de la
/// cuenta de prueba: RLS no deja tocar otras) y cierra la sesión.
Future<void> _limpiar(SupabaseClient cliente, String nombre) async {
  try {
    final filas = await cliente
        .from('calculos_consumo')
        .select('id')
        .eq('nombre', nombre);
    final ids = [for (final f in filas) f['id'] as String];
    if (ids.isNotEmpty) {
      await cliente
          .from('simulaciones_degradacion')
          .delete()
          .inFilter('calculo_id', ids);
      await cliente.from('calculos_consumo').delete().inFilter('id', ids);
    }
  } finally {
    await cliente.auth.signOut();
  }
}
