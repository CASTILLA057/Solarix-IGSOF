import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/dashboard/application/historial_providers.dart';
import 'package:solarix/features/dashboard/data/historial_repository.dart';
import 'package:solarix/features/dashboard/domain/historial.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

import '../../helpers/fakes.dart';

final _ahora = DateTime(2026, 10, 2, 12);

/// Fila como la devuelve Supabase, a partir de un cálculo real.
Map<String, dynamic> filaCalculo(String id, DateTime fecha) {
  const e = EntradasCalculo(
    tipo: TipoSistema.hibrido,
    modo: ModoConsumo.factura,
    consumoFacturaKwhMes: 300,
    hsp: 5,
    nombre: 'Casa',
  );
  return {
    'id': id,
    'nombre': e.nombre,
    'tipo_sistema': e.tipo.valorBd,
    'creado_en': fecha.toUtc().toIso8601String(),
    'resultados': calcular(e).aMapa(),
  };
}

/// Fila como la devuelve Supabase, a partir de una simulación real.
Map<String, dynamic> filaSimulacion(String id, DateTime fecha, Politica p) => {
  'id': id,
  'creado_en': fecha.toUtc().toIso8601String(),
  'calculo_id': null,
  ...simularComparacion((
    parametros: ParametrosSimulacion(anios: 2, politica: p),
    semilla: 2,
  )).aFila(),
};

class FakeHistorial implements HistorialRepository {
  FakeHistorial(this._calculos, this._simulaciones);

  final List<CalculoGuardado> _calculos;
  final List<SimulacionGuardada> _simulaciones;
  final eliminadas = <String>[];

  @override
  Future<List<CalculoGuardado>> calculos() async => [
    for (final c in _calculos)
      if (!eliminadas.contains(c.id)) c,
  ];

  @override
  Future<List<SimulacionGuardada>> simulaciones() async => [
    for (final s in _simulaciones)
      if (!eliminadas.contains(s.id)) s,
  ];

  @override
  Future<void> eliminarCalculo(String id) async => eliminadas.add(id);

  @override
  Future<void> eliminarSimulacion(String id) async => eliminadas.add(id);
}

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
    expect(find.text('Último cálculo: Casa'), findsOneWidget);
    expect(find.textContaining('Última simulación'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('sin datos muestra los estados vacíos', (tester) async {
    await abrir(tester, calculos: const [], simulaciones: const []);
    expect(find.text('Aún no tienes cálculos guardados'), findsOneWidget);
    expect(find.text('Aún no tienes simulaciones guardadas'), findsOneWidget);
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
