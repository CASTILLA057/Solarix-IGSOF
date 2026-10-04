import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/router/app_router.dart';
import 'package:solarix/core/router/rutas.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/calculadora/application/calculadora_providers.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/dashboard/application/historial_providers.dart';
import 'package:solarix/features/degradacion/application/simulacion_providers.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

import '../helpers/backend_memoria.dart';
import '../helpers/fakes.dart';

const _entradas = EntradasCalculo(
  tipo: TipoSistema.hibrido,
  modo: ModoConsumo.factura,
  consumoFacturaKwhMes: 300,
  hsp: 5,
);

/// Abre la app con sesión y va a [ruta].
Future<BackendEnMemoria> _abrirEn(
  WidgetTester tester,
  String ruta, {
  Object? extra,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = BackendEnMemoria();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
        ),
        calculadoraRepositoryProvider.overrideWithValue(backend),
        simulacionRepositoryProvider.overrideWithValue(backend),
        historialRepositoryProvider.overrideWithValue(backend),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(SolarixApp)))
      .read(routerProvider)
      .go(ruta, extra: extra);
  await tester.pumpAndSettle();
  return backend;
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

final _enInicio = find.text('Calcular mi sistema solar');
final _iconoInicio = find.byTooltip('Ir al inicio');
final _volverAlInicio = find.text('Volver al inicio');

void main() {
  group('Resultados del cálculo sin guardar', () {
    Future<BackendEnMemoria> abrir(WidgetTester tester) => _abrirEn(
      tester,
      Rutas.resultados,
      extra: (_entradas, calcular(_entradas)),
    );

    testWidgets('"Cancelar" se queda en los resultados', (tester) async {
      await abrir(tester);
      await _tocar(tester, _iconoInicio);
      expect(find.text('No has guardado este cálculo'), findsOneWidget);
      await _tocar(tester, find.text('Cancelar'));
      expect(find.text('Resultados'), findsOneWidget);
      expect(_enInicio, findsNothing);
    });

    testWidgets('"Salir sin guardar" va al inicio sin guardar', (tester) async {
      final backend = await abrir(tester);
      await _tocar(tester, _volverAlInicio);
      await _tocar(tester, find.text('Salir sin guardar'));
      expect(_enInicio, findsOneWidget);
      expect(backend.filasCalculos, isEmpty);
    });

    testWidgets('"Guardar y salir" guarda y va al inicio', (tester) async {
      final backend = await abrir(tester);
      await _tocar(tester, _volverAlInicio);
      await _tocar(tester, find.text('Guardar y salir'));
      expect(backend.filasCalculos, hasLength(1));
      expect(_enInicio, findsOneWidget);
    });

    testWidgets('ya guardado, vuelve al inicio sin preguntar', (tester) async {
      await abrir(tester);
      await _tocar(
        tester,
        find.widgetWithText(FilledButton, 'Guardar cálculo'),
      );
      await _tocar(tester, _volverAlInicio);
      expect(find.text('No has guardado este cálculo'), findsNothing);
      expect(_enInicio, findsOneWidget);
    });
  });

  testWidgets('resultados de la simulación: "Guardar y salir"', (tester) async {
    final comparacion = simularComparacion((
      parametros: const ParametrosSimulacion(anios: 2),
      semilla: 1,
    ));
    final backend = await _abrirEn(
      tester,
      Rutas.resultadosSimulacion,
      extra: (comparacion, null),
    );
    await _tocar(tester, _iconoInicio);
    expect(find.text('No has guardado esta simulación'), findsOneWidget);
    await _tocar(tester, find.text('Guardar y salir'));
    expect(backend.filasSimulaciones, hasLength(1));
    expect(_enInicio, findsOneWidget);
  });

  testWidgets('el ícono de casa está en las pantallas internas', (
    tester,
  ) async {
    await _abrirEn(tester, Rutas.historial);
    for (final ruta in [
      Rutas.calculadora,
      Rutas.simulacion,
      Rutas.perfil,
      Rutas.historial,
    ]) {
      ProviderScope.containerOf(tester.element(find.byType(SolarixApp)))
          .read(routerProvider)
          .go(ruta);
      await tester.pumpAndSettle();
      expect(_iconoInicio, findsOneWidget, reason: ruta);
    }
    await _tocar(tester, _iconoInicio);
    expect(_enInicio, findsOneWidget);
    // En el inicio no hace falta.
    expect(_iconoInicio, findsNothing);
  });
}
