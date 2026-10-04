import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/errors/error_app.dart';
import 'package:solarix/core/errors/mensajes_error.dart';
import 'package:solarix/core/router/app_router.dart';
import 'package:solarix/core/router/rutas.dart';
import 'package:solarix/core/theme/tema_providers.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/dashboard/application/historial_providers.dart';
import 'package:solarix/features/dashboard/domain/historial.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

import '../helpers/fakes.dart';
import '../helpers/historial_fakes.dart';

final _simulacion = SimulacionGuardada.desdeFila(
  filaSimulacion('s1', DateTime(2026, 10, 1), Politica.convencional),
);

Future<(FakeHistorial, SharedPreferences)> _abrir(
  WidgetTester tester, {
  Size tamano = const Size(1080, 2400),
  Map<String, Object> preferencias = const {},
  ErrorApp? error,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(preferencias);
  final prefs = await SharedPreferences.getInstance();
  final historial = FakeHistorial(
    [CalculoGuardado.desdeFila(filaCalculo('c1', DateTime(2026, 10, 1)))],
    [_simulacion],
    error: error,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
        ),
        perfilRepositoryProvider.overrideWithValue(
          FakePerfilRepository(const Perfil(id: 'u-1', nombre: 'Ana')),
        ),
        historialRepositoryProvider.overrideWithValue(historial),
        preferenciasProvider.overrideWithValue(prefs),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (historial, prefs);
}

void main() {
  testWidgets('el modo oscuro se elige en el perfil y se recuerda', (
    tester,
  ) async {
    final (_, prefs) = await _abrir(tester);
    ThemeMode modo() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
    expect(modo(), ThemeMode.system);

    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Oscuro'));
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(modo(), ThemeMode.dark);
    expect(prefs.getString('modo_tema'), 'dark');
  });

  testWidgets('arranca con el modo guardado', (tester) async {
    await _abrir(tester, preferencias: {'modo_tema': 'light'});
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('el dashboard muestra el error y permite reintentar', (
    tester,
  ) async {
    final (historial, _) = await _abrir(
      tester,
      error: ErrorApp(
        mensajeErrorAuth(CodigosError.pausado),
        codigo: CodigosError.pausado,
      ),
    );
    expect(find.text('No se pudieron cargar tus cálculos'), findsOneWidget);
    expect(find.textContaining('en pausa'), findsNWidgets(2));
    // No confunde un error con "aún no tienes".
    expect(find.text('Aún no tienes cálculos guardados'), findsNothing);

    historial.error = null;
    await tester.tap(find.byTooltip('Reintentar').first);
    await tester.pumpAndSettle();
    expect(find.text('Último cálculo: Casa'), findsOneWidget);
  });

  testWidgets('historial: estado vacío por filtros y "Quitar filtros"', (
    tester,
  ) async {
    await _abrir(tester);
    await tester.tap(find.byTooltip('Historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulaciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consciente'));
    await tester.pumpAndSettle();
    expect(find.text('No hay resultados con estos filtros'), findsOneWidget);
    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Eliminar simulación'), findsOneWidget);
  });

  // Recorre las pantallas en celular pequeño y escritorio, en claro y oscuro:
  // cualquier desborde (overflow) hace fallar la prueba.
  const entradas = EntradasCalculo(
    tipo: TipoSistema.hibrido,
    modo: ModoConsumo.factura,
    consumoFacturaKwhMes: 300,
    hsp: 5,
  );
  final comparacion = simularComparacion((
    parametros: const ParametrosSimulacion(anios: 2),
    semilla: 1,
  ));
  final pantallas = <(String, Object?)>[
    (Rutas.inicio, null),
    (Rutas.perfil, null),
    (Rutas.calculadora, null),
    (Rutas.resultados, (entradas, calcular(entradas))),
    (Rutas.simulacion, null),
    (Rutas.resultadosSimulacion, (comparacion, null)),
    (Rutas.historial, null),
    (Rutas.detalleSimulacion, _simulacion),
  ];
  for (final (nombre, tamano, modo) in [
    ('celular pequeño', const Size(320, 640), 'light'),
    ('celular oscuro', const Size(390, 844), 'dark'),
    ('escritorio', const Size(1440, 900), 'light'),
  ]) {
    testWidgets('todas las pantallas sin desbordes: $nombre', (tester) async {
      await _abrir(tester, tamano: tamano, preferencias: {'modo_tema': modo});
      final router = ProviderScope.containerOf(
        tester.element(find.byType(SolarixApp)),
      ).read(routerProvider);
      for (final (ruta, extra) in pantallas) {
        router.go(ruta, extra: extra);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: ruta);
      }
    });
  }
}
