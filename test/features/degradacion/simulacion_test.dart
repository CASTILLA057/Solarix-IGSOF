import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/degradacion/application/simulacion_providers.dart';
import 'package:solarix/features/degradacion/data/simulacion_repository.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/integracion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

import '../../helpers/fakes.dart';

class FakeSimulacionRepository implements SimulacionRepository {
  final guardadas = <ComparacionSimulacion>[];
  final calculosVinculados = <String?>[];

  @override
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
    ImpactoFinanciero? impacto,
  }) async {
    guardadas.add(simulacion);
    calculosVinculados.add(calculoId);
  }
}

/// Abre la app con sesión en el inicio, con un ejecutor de 2 años sin
/// isolate para que la prueba sea rápida.
Future<FakeSimulacionRepository> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeSimulacionRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
        ),
        simulacionRepositoryProvider.overrideWithValue(repo),
        ejecutorSimulacionProvider.overrideWithValue(
          (s) async => simularComparacion((
            parametros: s.parametros.copiarCon(anios: 2),
            semilla: 1,
          )),
        ),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('Comparación y serie mensual', () {
    final c = simularComparacion((
      parametros: const ParametrosSimulacion(anios: 2),
      semilla: 3,
    ));

    test('corre la otra política con la misma semilla (mismo clima)', () {
      expect(c.principal.parametros.politica, Politica.convencional);
      expect(c.alternativa.parametros.politica, Politica.consciente);
      expect(c.alternativa.semilla, c.principal.semilla);
      // Mismo clima: la energía generada por los paneles es la misma.
      expect(
        c.alternativa.energiaGeneradaKwh,
        closeTo(c.principal.energiaGeneradaKwh, 1e-6),
      );
      expect(c.consciente.sohFinal, greaterThan(c.convencional.sohFinal));
    });

    test('la serie mensual resume los días sin perder energía', () {
      final meses = serieMensual(c.principal.dias);
      expect(meses, hasLength(24)); // 2 años × 12 meses
      expect(meses.first.anio, 0);
      expect(meses.last.anio, 1);
      expect(meses.last.mes, 11);
      final comprada = meses.fold<double>(0, (s, m) => s + m.compradaKwh);
      expect(comprada, closeTo(c.principal.energiaCompradaKwh, 1e-6));
      expect(meses.last.soh, c.principal.sohFinal);
    });

    test('la fila para Supabase tiene las columnas de la tabla', () {
      final fila = c.aFila();
      expect(fila['politica'], 'convencional');
      expect((fila['parametros'] as Map)['semilla'], 3);
      final resultados = fila['resultados'] as Map;
      expect(resultados['soh_final'], c.principal.sohFinal);
      expect((resultados['comparacion'] as Map)['politica'], 'consciente');
      expect(fila['serie'], hasLength(24));
    });
  });

  testWidgets('simula desde el inicio, compara y guarda', (tester) async {
    final repo = await _abrir(tester);
    Future<void> tocar(Finder f) => _tocar(tester, f);

    await tocar(find.text('Simular degradación de batería'));
    expect(find.text('Simular degradación'), findsOneWidget);
    await tocar(find.text('Consciente'));
    await tocar(find.widgetWithText(FilledButton, 'Simular'));

    expect(find.text('Resultados de la simulación'), findsOneWidget);
    expect(find.text('Convencional frente a consciente'), findsOneWidget);
    expect(find.text('Consciente\n(elegida)'), findsOneWidget);

    await tocar(find.widgetWithText(FilledButton, 'Guardar simulación'));
    expect(repo.guardadas.single.parametros.politica, Politica.consciente);
    expect(find.text('Simulación guardada'), findsOneWidget);
  });

  testWidgets('"Avanzado": escenario de NetLogo sin combinaciones imposibles', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    Future<void> tocar(Finder f) => _tocar(tester, f);
    final lugar = find.byType(DropdownButtonFormField<String>);

    await tocar(find.text('Simular degradación de batería'));
    expect(
      tester.widget<DropdownButtonFormField<String>>(lugar).onChanged,
      isNotNull,
    );
    await tocar(find.text('Avanzado: configuración de NetLogo'));
    await tocar(find.text('Usar un escenario de NetLogo'));
    // Con NetLogo el lugar no se usa.
    expect(
      tester.widget<DropdownButtonFormField<String>>(lugar).onChanged,
      isNull,
    );
    expect(
      find.textContaining('Configuración original de NetLogo'),
      findsOneWidget,
    );

    // Irradiancia baja (casi sin sol): sin zona muy soleada ni polvorienta.
    await tocar(find.text('Baja'));
    await tocar(find.byType(DropdownButtonFormField<ZonaClimatica>));
    expect(find.text('Muy soleada'), findsNothing);
    expect(find.text('Polvorienta'), findsNothing);
    await tocar(find.text('Lluviosa').last);

    await tocar(find.widgetWithText(FilledButton, 'Simular'));
    await tocar(find.widgetWithText(FilledButton, 'Guardar simulación'));
    final p = repo.guardadas.single.parametros;
    expect(p.escenario, EscenarioIrradiancia.baja);
    expect(p.zona, ZonaClimatica.lluviosa);
    // Los valores originales de NetLogo, no los de un lugar.
    expect(p.irradianciaMaxima, EscenarioIrradiancia.baja.irradianciaMaxima);
  });
}
