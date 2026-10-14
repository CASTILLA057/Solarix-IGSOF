import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/dashboard/application/historial_providers.dart';
import 'package:solarix/features/dashboard/domain/historial.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

import '../../helpers/fakes.dart';
import '../../helpers/historial_fakes.dart';

final _ahora = DateTime(2026, 10, 2, 12);

void main() {
  final calculo = CalculoGuardado.desdeFila(filaCalculo('c1', _ahora));
  final reciente = SimulacionGuardada.desdeFila(
    filaSimulacion('s1', _ahora, Politica.consciente),
  );
  final antigua = SimulacionGuardada.desdeFila(
    filaSimulacion('s2', DateTime(2025, 3, 1), Politica.convencional),
  );

  group('Lectura de las filas de Supabase', () {
    test('cálculo guardado', () {
      expect(calculo.titulo, 'Casa');
      expect(calculo.tipo, TipoSistema.hibrido);
      expect(calculo.numeroPaneles, greaterThan(0));
      expect(calculo.costoTotal, greaterThan(0));
      expect(calculo.creadoEn, _ahora);
    });
    test('simulación guardada con su serie mensual y la comparación', () {
      expect(reciente.politica, Politica.consciente);
      expect(reciente.politicaAlternativa, Politica.convencional);
      expect(reciente.serie, hasLength(24));
      expect(reciente.serie.last.indice, 23);
      expect(reciente.sohAnual, hasLength(3));
      expect(reciente.sohAnualAlternativa, hasLength(3));
      expect(reciente.sohFinal, greaterThan(reciente.sohFinalAlternativa));
    });
  });

  test('filtros por fecha y por política', () {
    final todas = [reciente, antigua];
    expect(filtrarSimulaciones(todas, FiltroFecha.todas, null, _ahora), todas);
    expect(filtrarSimulaciones(todas, FiltroFecha.semana, null, _ahora), [
      reciente,
    ]);
    expect(
      filtrarSimulaciones(
        todas,
        FiltroFecha.todas,
        Politica.convencional,
        _ahora,
      ),
      [antigua],
    );
    expect(filtrarSimulaciones(todas, FiltroFecha.anio, null, _ahora), [
      reciente,
    ]);
    expect(filtrarCalculos([calculo], FiltroFecha.mes, _ahora), [calculo]);
  });

  Future<FakeHistorial> abrir(
    WidgetTester tester, {
    required List<CalculoGuardado> calculos,
    required List<SimulacionGuardada> simulaciones,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeHistorial(calculos, simulaciones);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
          ),
          historialRepositoryProvider.overrideWithValue(repo),
        ],
        child: const SolarixApp(),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('el dashboard muestra lo último guardado y la gráfica', (
    tester,
  ) async {
    await abrir(tester, calculos: [calculo], simulaciones: [reciente]);
    // En web: "Último cálculo · Casa".
    expect(find.textContaining('Último cálculo'), findsOneWidget);
    expect(find.textContaining('Casa'), findsWidgets);
    expect(find.textContaining('Última simulación'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('sin datos muestra los estados vacíos', (tester) async {
    await abrir(tester, calculos: const [], simulaciones: const []);
    expect(find.text('Aún no tienes cálculos guardados'), findsOneWidget);
    expect(find.text('Aún no tienes simulaciones guardadas'), findsOneWidget);
  });

  testWidgets('historial: al tocar un cálculo se abren sus resultados '
      'guardados', (tester) async {
    await abrir(tester, calculos: [calculo], simulaciones: const []);
    await tocar(tester, find.byTooltip('Historial'));
    await tocar(tester, find.text('Casa'));

    // Los mismos resultados del cálculo, ya en estado "Cálculo guardado".
    expect(find.text('Cálculo guardado'), findsOneWidget);
    expect(find.text('Guardar cálculo'), findsNothing);
    // Título de la tarjeta (y subtítulo del encabezado, sin ciudad).
    expect(find.text('Sistema híbrido'), findsWidgets);
    expect(find.textContaining('recomendado'), findsNothing);
    expect(find.text('Simular la salud de esta batería'), findsOneWidget);

    // Desde el historial vuelve al historial, no a la calculadora.
    expect(find.text('Volver a la calculadora'), findsNothing);
    await tocar(tester, find.text('Volver al historial'));
    expect(find.byTooltip('Eliminar cálculo'), findsOneWidget);
  });

  testWidgets('historial: un cálculo con datos ilegibles avisa en vez de no '
      'hacer nada', (tester) async {
    final fila = filaCalculo('c9', _ahora);
    (fila['resultados'] as Map<String, dynamic>).remove('flujo');
    await abrir(
      tester,
      calculos: [CalculoGuardado.desdeFila(fila)],
      simulaciones: const [],
    );
    await tocar(tester, find.byTooltip('Historial'));
    await tocar(tester, find.text('Casa'));

    expect(
      find.text('No se pueden abrir los datos de este cálculo.'),
      findsOneWidget,
    );
    expect(find.text('Cálculo guardado'), findsNothing);
  });

  testWidgets('historial: filtra por política, abre el detalle y elimina', (
    tester,
  ) async {
    final repo = await abrir(
      tester,
      calculos: [calculo],
      simulaciones: [reciente, antigua],
    );
    await tocar(tester, find.byTooltip('Historial'));
    expect(find.byTooltip('Eliminar cálculo'), findsOneWidget);
    await tocar(tester, find.text('Simulaciones'));
    expect(find.byTooltip('Eliminar simulación'), findsNWidgets(2));

    await tocar(tester, find.text('Convencional'));
    expect(find.byTooltip('Eliminar simulación'), findsOneWidget);
    await tocar(tester, find.text('Todas'));

    // Detalle con sus tres gráficas.
    await tocar(tester, find.textContaining('· Consciente'));
    expect(find.text('Simulación guardada'), findsOneWidget);
    expect(find.byType(LineChart), findsNWidgets(3));
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tocar(tester, find.byTooltip('Eliminar simulación').first);
    await tocar(tester, find.widgetWithText(FilledButton, 'Eliminar'));
    expect(repo.eliminadas, ['s1']);
    expect(find.byTooltip('Eliminar simulación'), findsOneWidget);
  });
}
