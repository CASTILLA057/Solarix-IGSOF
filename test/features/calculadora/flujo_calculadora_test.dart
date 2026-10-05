import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/calculadora/application/calculadora_providers.dart';
import 'package:solarix/features/calculadora/data/calculadora_repository.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';

import '../../helpers/fakes.dart';

class FakeCalculadoraRepository implements CalculadoraRepository {
  final guardados = <(EntradasCalculo, ResultadoCalculo)>[];

  @override
  Future<Precios> obtenerPrecios() async => Precios.referencia;

  @override
  Future<List<Ciudad>> obtenerCiudades() async => ciudadesBase;

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) async {
    guardados.add((entradas, resultado));
    return 'calc-${guardados.length}';
  }
}

Future<FakeCalculadoraRepository> abrirCalculadora(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeCalculadoraRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
        ),
        calculadoraRepositoryProvider.overrideWithValue(repo),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tocar(tester, find.text('Calcular mi sistema solar'));
  return repo;
}

Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Finder boton(String texto) => find.widgetWithText(FilledButton, texto);

/// Texto actual del campo numérico con esa etiqueta.
String textoDe(WidgetTester tester, String etiqueta) => tester
    .widget<TextFormField>(find.widgetWithText(TextFormField, etiqueta))
    .controller!
    .text;

void main() {
  testWidgets('calcula un sistema conectado a la red y lo guarda', (
    tester,
  ) async {
    final repo = await abrirCalculadora(tester);
    expect(find.text('Calculadora solar'), findsOneWidget);

    // 1. Tipo de sistema: conectado a la red (por defecto).
    await tocar(tester, boton('Siguiente'));
    // 2. Consumo: los equipos de ejemplo y la tarifa por defecto.
    expect(find.text('Agregar equipo'), findsOneWidget);
    await tocar(tester, boton('Siguiente'));
    // 3. Ubicación: HSP a mano (4,5 por defecto).
    await tocar(tester, find.text('Manual'));
    await tocar(tester, boton('Siguiente'));
    // 4. Equipos y costos → calcular.
    await tocar(tester, boton('Calcular'));

    expect(find.text('Resultados'), findsOneWidget);
    expect(
      find.text('Sistema recomendado (conectado a la red)'),
      findsOneWidget,
    );
    await tocar(tester, boton('Guardar cálculo'));

    final (entradas, resultado) = repo.guardados.single;
    expect(entradas.tipo, TipoSistema.onGrid);
    expect(entradas.hsp, 4.5);
    expect(resultado.numeroPaneles, greaterThan(0));
    expect(find.text('Cálculo guardado'), findsOneWidget);
  });

  testWidgets('no avanza sin elegir la ubicación', (tester) async {
    await abrirCalculadora(tester);
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    expect(
      find.text('Elige una ciudad o escribe las horas solares pico.'),
      findsOneWidget,
    );
    expect(boton('Calcular'), findsNothing);
  });

  testWidgets('supuestos explicados e incentivos de la Ley 1715 llegan al '
      'cálculo', (tester) async {
    final repo = await abrirCalculadora(tester);
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Manual'));
    await tocar(tester, boton('Siguiente'));

    await tocar(tester, find.text('Supuestos técnicos y financieros'));
    expect(textoDe(tester, 'Autoconsumo'), '60');
    expect(find.widgetWithText(TextFormField, 'Consumo sin sol'), findsNothing);
    // La explicación del precio de bolsa cita su fuente.
    await tocar(
      tester,
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Precio de bolsa'),
        matching: find.byTooltip('Qué es y de dónde sale'),
      ),
    );
    expect(find.textContaining('según XM'), findsOneWidget);
    await tocar(tester, find.text('Entendido'));

    await tocar(tester, find.text('Incentivos de la Ley 1715'));
    await tocar(tester, find.text('Comprar sin IVA'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tu tarifa marginal de renta'),
      '35',
    );
    await tocar(tester, boton('Calcular'));

    expect(find.textContaining('Sin IVA (Ley 1715)'), findsOneWidget);
    expect(find.text('Deducción de renta (año 1)'), findsOneWidget);
    await tocar(tester, boton('Guardar cálculo'));
    final (entradas, resultado) = repo.guardados.single;
    expect(entradas.supuestos.exclusionIva, isTrue);
    expect(entradas.supuestos.tarifaRenta, closeTo(0.35, 1e-9));
    expect(entradas.supuestos.autoconsumo, closeTo(0.6, 1e-9));
    expect(entradas.supuestos.precioBolsa, 300);
    expect(resultado.costos.ivaExcluido, greaterThan(0));
    expect(resultado.beneficioRenta, greaterThan(0));
  });

  testWidgets('el autoconsumo sigue al tipo de sistema salvo que se edite', (
    tester,
  ) async {
    await abrirCalculadora(tester);
    await tocar(tester, find.text('Híbrido'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Manual'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Supuestos técnicos y financieros'));
    expect(textoDe(tester, 'Autoconsumo'), '90');
    expect(textoDe(tester, 'Consumo sin sol'), '50');

    // Escrito a mano: ya no cambia con el tipo.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Autoconsumo'),
      '70',
    );
    await tocar(tester, find.text('Tipo de sistema'));
    await tocar(tester, find.text('Conectado a la red'));
    expect(textoDe(tester, 'Autoconsumo'), '70');
  });

  testWidgets('pide al menos un equipo', (tester) async {
    await abrirCalculadora(tester);
    await tocar(tester, boton('Siguiente'));
    while (find.byTooltip('Quitar').evaluate().isNotEmpty) {
      await tocar(tester, find.byTooltip('Quitar').first);
    }
    await tocar(tester, boton('Siguiente'));
    expect(find.text('Agrega al menos un equipo.'), findsOneWidget);
  });
}
