import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/calculadora/application/calculadora_providers.dart';
import 'package:solarix/features/calculadora/data/calculadora_repository.dart';
import 'package:solarix/features/calculadora/data/recurso_solar.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';

import '../../helpers/fakes.dart';

class FakeCalculadoraRepository implements CalculadoraRepository {
  final guardados = <(EntradasCalculo, ResultadoCalculo)>[];

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) async {
    guardados.add((entradas, resultado));
    return 'calc-${guardados.length}';
  }
}

/// Ubicación del GPS sin red: HSP de 4,6 y la [altitud] dada.
class FakeRecursoSolar implements RecursoSolarService {
  FakeRecursoSolar({this.altitud});

  final double? altitud;

  @override
  Future<({double hsp, ClimaLugar? clima, double? altitudM})>
  recursoEnUbicacionActual() async =>
      (hsp: 4.6, clima: null, altitudM: altitud);
}

Future<FakeCalculadoraRepository> abrirCalculadora(
  WidgetTester tester, {
  Perfil perfil = const Perfil(id: 'u-1'),
  RecursoSolarService? recurso,
}) async {
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
        perfilRepositoryProvider.overrideWithValue(
          FakePerfilRepository(perfil),
        ),
        if (recurso != null) recursoSolarProvider.overrideWithValue(recurso),
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
    // Sin batería no hay con qué comparar.
    expect(find.text('¿Y sin batería?'), findsNothing);
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
    // Solo se muestra el paso actual: se vuelve al de equipos y costos.
    for (var i = 0; i < 3; i++) {
      await tocar(tester, boton('Siguiente'));
    }
    await tocar(tester, find.text('Supuestos técnicos y financieros'));
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

  testWidgets('estrato: el subsidio llega al cálculo con la subsistencia de '
      'la ciudad', (tester) async {
    final repo = await abrirCalculadora(
      tester,
      perfil: const Perfil(id: 'u-1', ciudad: 'Bogotá'),
    );
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Estrato 4'));
    await tocar(tester, find.text('Estrato 2 · subsidio hasta 50 %').last);
    expect(find.text('Consumo de subsistencia'), findsOneWidget);
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Calcular'));

    // Bogotá está a más de 1.000 m: 130 kWh/mes.
    expect(
      find.text('Estrato 2 · subsidio hasta 50 % en los primeros 130 kWh/mes'),
      findsOneWidget,
    );
    expect(find.text('Factura de energía hoy (estimada)'), findsOneWidget);
    await tocar(tester, boton('Guardar cálculo'));
    final (entradas, _) = repo.guardados.single;
    expect(entradas.estrato, Estrato.dos);
    expect(entradas.consumoSubsistenciaKwh, 130);
  });

  /// Estrato 1 con "Mi ubicación": devuelve lo que se guardó.
  Future<EntradasCalculo> estratoUnoConGps(
    WidgetTester tester, {
    double? altitud,
    String? subsidio,
    bool avisoEsperado = false,
  }) async {
    final repo = await abrirCalculadora(
      tester,
      recurso: FakeRecursoSolar(altitud: altitud),
    );
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Estrato 4'));
    await tocar(tester, find.text('Estrato 1 · subsidio hasta 60 %').last);
    expect(textoDe(tester, 'Subsidio de tu factura'), '60');
    // Campos cerrados en versión corta, para que no se corten.
    expect(find.text('Estrato 1'), findsOneWidget);
    expect(find.text('Según el lugar'), findsOneWidget);
    if (subsidio != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subsidio de tu factura'),
        subsidio,
      );
    }
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Mi ubicación'));
    await tocar(tester, find.text('Usar mi ubicación'));
    expect(
      find.textContaining('Sin la altura del lugar'),
      avisoEsperado ? findsOneWidget : findsNothing,
    );
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Calcular'));
    await tocar(tester, boton('Guardar cálculo'));
    return repo.guardados.single.$1;
  }

  testWidgets('estrato con "Mi ubicación": la altitud del GPS da 130', (
    tester,
  ) async {
    final e = await estratoUnoConGps(tester, altitud: 2600);
    expect(e.consumoSubsistenciaKwh, 130);
    expect(e.subsidioEstrato, isNull);
    expect(e.subsidioAplicado, 0.6);
  });

  testWidgets('estrato con "Mi ubicación" sin altitud: 173 y aviso', (
    tester,
  ) async {
    final e = await estratoUnoConGps(tester, avisoEsperado: true);
    expect(e.consumoSubsistenciaKwh, 173);
  });

  testWidgets('el subsidio de la factura llega al cálculo', (tester) async {
    final e = await estratoUnoConGps(tester, altitud: 40, subsidio: '45');
    expect(e.subsidioEstrato, closeTo(0.45, 1e-9));
    expect(
      find.text('Estrato 1 · subsidio de 45 % en los primeros 173 kWh/mes'),
      findsOneWidget,
    );
  });

  testWidgets('la ciudad del perfil es el lugar por defecto', (tester) async {
    final repo = await abrirCalculadora(
      tester,
      perfil: const Perfil(id: 'u-1', ciudad: 'Cali'),
    );
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    expect(find.text('Cali (Valle del Cauca)'), findsOneWidget);
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Calcular'));
    await tocar(tester, boton('Guardar cálculo'));
    final (entradas, _) = repo.guardados.single;
    expect(entradas.hsp, 4.2);
    expect(entradas.clima, isNotNull);
  });

  testWidgets('híbrido: se compara con el mismo sistema sin batería', (
    tester,
  ) async {
    await abrirCalculadora(tester);
    await tocar(tester, find.text('Híbrido'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, find.text('Manual'));
    await tocar(tester, boton('Siguiente'));
    await tocar(tester, boton('Calcular'));

    await tester.ensureVisible(find.text('¿Y sin batería?'));
    expect(find.text('VPN sin batería'), findsOneWidget);
    expect(find.textContaining('La batería resta'), findsOneWidget);
    expect(find.textContaining('cubrir los cortes'), findsOneWidget);
    // La nota del ahorro ya no habla del "siguiente módulo".
    expect(find.textContaining('siguiente módulo'), findsNothing);
    expect(
      find.textContaining('"Simular la salud de esta batería" se calcula'),
      findsOneWidget,
    );
  });
}
