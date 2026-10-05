import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/router/app_router.dart';
import 'package:solarix/core/router/rutas.dart';

import '../helpers/backend_memoria.dart';
import '../helpers/flujo_completo.dart';

void main() {
  group('Rutas sin cuenta', () {
    test('probando sin cuenta se calcula y se simula', () {
      for (final ruta in Rutas.paraInvitados) {
        expect(
          redirigir(autenticado: false, ubicacion: ruta, invitado: true),
          isNull,
          reason: ruta,
        );
      }
    });

    test('el perfil y el historial siguen pidiendo sesión', () {
      for (final ruta in [
        Rutas.perfil,
        Rutas.historial,
        Rutas.detalleSimulacion,
      ]) {
        expect(
          redirigir(autenticado: false, ubicacion: ruta, invitado: true),
          Rutas.bienvenida,
          reason: ruta,
        );
      }
    });

    test('sin elegir "Probar sin cuenta" todo pide sesión', () {
      expect(
        redirigir(autenticado: false, ubicacion: Rutas.calculadora),
        Rutas.bienvenida,
      );
    });
  });

  testWidgets('sin cuenta: calcula, simula y no guarda', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final backend = BackendEnMemoria();
    await abrirConBackendFalso(tester, backend, rapido: true);

    // Bienvenida → probar sin cuenta.
    await esperar(tester, find.text('Bienvenido a Solarix'));
    await tocar(tester, find.text('Probar sin cuenta'));
    expect(find.text('Estás probando Solarix sin cuenta'), findsOneWidget);
    expect(find.byTooltip('Historial'), findsNothing);
    expect(find.byTooltip('Mi perfil'), findsNothing);

    // Calculadora híbrida → resultados: no se guarda.
    await tocar(tester, find.text('Calcular mi sistema solar'));
    await tocar(tester, find.text('Híbrido'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Manual'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Calcular'));
    await buscar(tester, find.text('Crea una cuenta para guardar'));
    expect(find.text('Crea una cuenta para guardar'), findsOneWidget);
    expect(boton('Guardar cálculo'), findsNothing);

    // La batería del cálculo también se simula sin cuenta.
    await tocar(tester, find.text('Simular la salud de esta batería'));
    await tocar(tester, boton('Simular'));
    await esperar(tester, find.text('Con el sistema que dimensionaste'));
    await buscar(tester, find.text('Crea una cuenta para guardar'));
    expect(boton('Guardar simulación'), findsNothing);

    // Sin nada que guardar, vuelve al inicio sin preguntar.
    await tocar(tester, find.text('Volver al inicio'));
    expect(find.textContaining('No has guardado'), findsNothing);
    expect(find.text('Estás probando Solarix sin cuenta'), findsOneWidget);
    expect(backend.filasCalculos, isEmpty);
    expect(backend.filasSimulaciones, isEmpty);

    // El historial sigue pidiendo cuenta.
    ProviderScope.containerOf(tester.element(find.byType(SolarixApp)))
        .read(routerProvider)
        .go(Rutas.historial);
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a Solarix'), findsOneWidget);
  });
}
