import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/calculadora/application/calculadora_providers.dart';
import 'package:solarix/features/calculadora/data/calculadora_repository.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/degradacion/application/simulacion_providers.dart';
import 'package:solarix/features/degradacion/data/simulacion_repository.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/integracion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';
import 'package:solarix/features/degradacion/domain/simulador.dart';

import '../../helpers/fakes.dart';

/// Casa híbrida de 300 kWh/mes (10 kWh/día) con batería de litio y 5 HSP.
const hibrida = EntradasCalculo(
  tipo: TipoSistema.hibrido,
  modo: ModoConsumo.factura,
  consumoFacturaKwhMes: 300,
  hsp: 5,
  nombre: 'Casa',
);

void main() {
  group('Del cálculo a los parámetros de la simulación', () {
    test('HSP de los escenarios de NetLogo', () {
      // El escenario "alto" da ≈ 4,6 HSP en la zona mixta, el "medio" ≈ 3,2
      // y el "bajo" casi nada (50 W/m² de máximo).
      expect(hspEscenario(EscenarioIrradiancia.alta), closeTo(4.6, 0.5));
      expect(
        hspEscenario(EscenarioIrradiancia.media),
        lessThan(hspEscenario(EscenarioIrradiancia.alta)),
      );
      expect(hspEscenario(EscenarioIrradiancia.baja), lessThan(1));
    });

    test('ajusta el consumo del modelo al consumo calculado', () {
      final r = calcular(hibrida);
      final p = parametrosDesdeCalculo(
        OrigenCalculo(entradas: hibrida, resultado: r),
      );
      expect(p.capacidadBateriaKwh, r.bateriaKwh);
      expect(p.potenciaPanelKw, r.potenciaInstaladaKw);
      expect(p.escenario, EscenarioIrradiancia.alta);
      // Con el factor, la casa simulada consume ≈ 10 kWh/día.
      final simulada = simular(p.copiarCon(anios: 1), semilla: 9);
      expect(simulada.consumoKwh / 365, closeTo(10, 0.5));
    });

    test('vida de la batería: fin de vida o extrapolación a 80 %', () {
      final normal = simular(
        const ParametrosSimulacion(),
        registrarDias: false,
      );
      // ≈ 1,5 %/año durante 10 años: llega al 80 % pasados los 10 años. En
      // este rango el SoH simulado baja casi en línea recta, así que la
      // curva del modelo da casi lo mismo que una recta (≈ 13 años).
      final porUso = aniosHastaFinDeVida(normal)!;
      expect(porUso, greaterThan(normal.aniosSimulados));
      expect(porUso, closeTo(20 / normal.perdidaAnual, 1.5));
      expect(vidaBateriaParaFlujo(normal, calendario: 30), porUso.round());

      final rapida = simular(
        const ParametrosSimulacion(exponenteDegradacion: 1.3),
        registrarDias: false,
      );
      expect(aniosHastaFinDeVida(rapida), rapida.aniosSimulados);

      final sinUso = simular(
        const ParametrosSimulacion(escenario: EscenarioIrradiancia.baja),
        registrarDias: false,
      );
      expect(aniosHastaFinDeVida(sinUso), isNull);
      // Sin desgaste por uso, manda la vida calendario.
      final vida = vidaBateria(sinUso, calendario: 15);
      expect(vida.porUso, isNull);
      expect(vida.efectiva, 15);
      expect(vida.limitaCalendario, isTrue);
      expect(vidaBateriaParaFlujo(sinUso, calendario: 15), 15);
    });

    test('extrapola con la curva del modelo (Z = a·tᵇ), no con una recta', () {
      // SoH = 100·e^(−0,01·t^1,5): llega al 80 % en (ln 1,25 / 0,01)^(1/1,5).
      double soh(double t) => 100 * math.exp(-0.01 * math.pow(t, 1.5));
      final r = ResultadoSimulacion(
        parametros: const ParametrosSimulacion(anios: 5),
        semilla: 1,
        horasSimuladas: 5 * Constantes.horasPorAnio,
        sohFinal: soh(5),
        energiaCompradaKwh: 0,
        energiaGeneradaKwh: 0,
        consumoKwh: 0,
        limpiezas: 0,
        ciclosEquivalentes: 0,
        sohAnual: [for (var t = 0; t <= 5; t++) soh(t.toDouble())],
        dias: const [],
      );
      final esperado = math.pow(math.log(1.25) / 0.01, 1 / 1.5);
      expect(aniosHastaFinDeVida(r), closeTo(esperado, 1e-6));
      // La recta sobre el SoH se pasaría: la degradación se acelera.
      expect(20 / r.perdidaAnual, greaterThan(esperado + 1));
    });

    test('la vida calendario pone tope a la vida por uso', () {
      final normal = simular(
        const ParametrosSimulacion(),
        registrarDias: false,
      );
      final corta = vidaBateria(normal, calendario: 8);
      expect(corta.limitaCalendario, isTrue);
      expect(corta.efectiva, 8);
      expect(corta.porUso, greaterThan(10));
      expect(vidaBateriaParaFlujo(normal, calendario: 8), 8);
      final larga = vidaBateria(normal, calendario: 40);
      expect(larga.limitaCalendario, isFalse);
      expect(larga.efectiva, larga.porUso);
    });

    test('la vida simulada reemplaza a la típica en el flujo de caja', () {
      final tipica = calcular(hibrida); // litio: 10 años → reemplazo en el 10
      final simulada = calcular(hibrida, vidaBateriaAnios: 13);
      int? primerReemplazo(ResultadoCalculo r) =>
          r.flujo.where((a) => a.reemplazoBateria > 0).firstOrNull?.anio;
      expect(primerReemplazo(tipica), 10);
      expect(primerReemplazo(simulada), 13);
      expect(simulada.vpn, greaterThan(tipica.vpn));
    });
  });

  group('Etapa 12: clima por ciudad', () {
    ClimaLugar clima(double mmAnio, double nubes, [double temperatura = 25]) =>
        ClimaLugar(
          lluviaMmDia: mmAnio / 365,
          nubosidadPct: nubes,
          temperaturaC: temperatura,
        );

    test('la zona sale de la lluvia y las nubes del lugar', () {
      expect(zonaParaClima(null), ZonaClimatica.mixta);
      expect(zonaParaClima(clima(4400, 89)), ZonaClimatica.lluviosa);
      expect(zonaParaClima(clima(2500, 50)), ZonaClimatica.lluviosa);
      expect(zonaParaClima(clima(930, 57)), ZonaClimatica.polvorienta);
      expect(zonaParaClima(clima(1120, 57)), ZonaClimatica.muySoleada);
      expect(zonaParaClima(clima(1620, 78)), ZonaClimatica.muyNublada);
      expect(zonaParaClima(clima(1020, 84)), ZonaClimatica.muyNublada);
      expect(zonaParaClima(clima(1010, 71)), ZonaClimatica.mixta);
      expect(zonaParaClima(clima(1599, 79.9)), ZonaClimatica.mixta);
    });

    test('las ciudades de la lista tienen su clima y su zona', () {
      for (final c in ciudadesBase) {
        final cl = climaDeCiudad(c.nombre);
        expect(cl, isNotNull, reason: c.nombre);
        // Temperatura corregida por altitud: de páramo a costa.
        expect(cl!.temperaturaC, inInclusiveRange(10, 30), reason: c.nombre);
      }
      ZonaClimatica zona(String ciudad) => zonaParaClima(climaDeCiudad(ciudad));
      expect(zona('Riohacha'), ZonaClimatica.polvorienta);
      expect(zona('Barranquilla'), ZonaClimatica.muySoleada);
      expect(zona('Quibdó'), ZonaClimatica.lluviosa);
      expect(zona('Bogotá'), ZonaClimatica.muyNublada);
      expect(zona('Ocaña'), ZonaClimatica.mixta);
      // Bogotá (2.640 m) es más fría que Cali (1.000 m) y que la costa.
      expect(
        climaDeCiudad('Bogotá')!.temperaturaC,
        lessThan(climaDeCiudad('Cali')!.temperaturaC),
      );
      expect(climaDeCiudad('No existe'), isNull);
    });

    test('la zona cambia el sol del modelo (las nubes)', () {
      const alta = EscenarioIrradiancia.alta;
      expect(
        hspEscenario(alta, ZonaClimatica.muySoleada),
        greaterThan(hspEscenario(alta)),
      );
      expect(
        hspEscenario(alta, ZonaClimatica.muyNublada),
        lessThan(hspEscenario(alta)),
      );
    });

    test('todas las ciudades: sin pasar el tope y a ±5 % de sus HSP', () {
      for (final c in ciudadesBase) {
        final entorno = entornoDelLugar(
          hsp: c.hsp,
          clima: climaDeCiudad(c.nombre),
        );
        expect(
          entorno.irradianciaMaxima,
          lessThan(irradianciaMaximaTope),
          reason: '${c.nombre}: si llega al tope, su zona está mal asignada',
        );
        // Medido con otra semilla (otro clima) que la que se usó para
        // ajustar la irradiancia, en los 10 años que se simulan.
        final r = simular(entorno, semilla: 11);
        final hsp =
            r.dias.fold<double>(0, (s, d) => s + d.irradianciaMedia * 24) /
            r.dias.length /
            1000;
        expect(
          (hsp - c.hsp).abs() / c.hsp,
          lessThan(0.05),
          reason: '${c.nombre}: ${hsp.toStringAsFixed(2)} HSP',
        );
      }
    });

    test('el entorno del lugar cambia solo las entradas de NetLogo', () {
      final ocana = climaDeCiudad('Ocaña')!;
      final e = entornoDelLugar(hsp: 5.0, clima: ocana);
      expect(e.escenario, escenarioBase);
      expect(e.zona, ZonaClimatica.mixta);
      expect(e.temperaturaMedia, ocana.temperaturaC);
      expect(hspModelo(e), closeTo(5.0, 1e-9));
      expect(e.esDeNetLogo, isFalse);
      expect(e.aMapa()['irradiancia_maxima_lugar'], e.irradianciaMaxima);
      expect(e.aMapa()['temperatura_media_lugar'], ocana.temperaturaC);
      // Sin clima (HSP a mano): zona mixta y temperatura del escenario.
      final aMano = entornoDelLugar(hsp: 5.0);
      expect(aMano.zona, ZonaClimatica.mixta);
      expect(aMano.temperaturaMedia, escenarioBase.temperaturaMedia);
      // Una configuración de NetLogo queda intacta.
      const netLogo = ParametrosSimulacion();
      expect(netLogo.esDeNetLogo, isTrue);
      expect(netLogo.irradianciaMaxima, 800);
      expect(netLogo.temperaturaMedia, 27);
    });

    test('del cálculo: lugar, consumo a la temperatura del lugar', () {
      final riohacha = EntradasCalculo(
        tipo: TipoSistema.hibrido,
        modo: ModoConsumo.factura,
        consumoFacturaKwhMes: 300,
        hsp: 5.5,
        clima: climaDeCiudad('Riohacha'),
      );
      final p = parametrosDesdeCalculo(
        OrigenCalculo(entradas: riohacha, resultado: calcular(riohacha)),
      );
      expect(p.zona, ZonaClimatica.polvorienta);
      expect(p.temperaturaMedia, climaDeCiudad('Riohacha')!.temperaturaC);
      expect(hspModelo(p), closeTo(5.5, 1e-9));
      // La casa simulada consume lo calculado (≈ 10 kWh/día).
      final r = simular(p.copiarCon(anios: 1), semilla: 9);
      expect(r.consumoKwh / 365, closeTo(10, 0.5));
      // El clima se guarda con las entradas del cálculo.
      expect(riohacha.aMapa()['clima'], climaDeCiudad('Riohacha')!.aMapa());
      expect(hibrida.aMapa()['clima'], isNull);
      expect(
        ClimaLugar.desdeMapa(riohacha.aMapa()['clima'])!.temperaturaC,
        climaDeCiudad('Riohacha')!.temperaturaC,
      );
    });
  });

  group('Etapa 12: la degradación cambia el ahorro, no solo el reemplazo', () {
    final origen = OrigenCalculo(
      entradas: hibrida,
      resultado: calcular(hibrida),
    );
    // 10 años, como en la app: cada política y la referencia sin degradación
    // con el mismo clima.
    final c = simularComparacion((
      parametros: parametrosDesdeCalculo(origen).copiarCon(anios: 10),
      semilla: 7,
    ));

    test('la referencia no se degrada y registra la energía de cada año', () {
      final ref = c.referencia!;
      expect(ref.sohFinal, 100);
      expect(ref.autoabastecidoAnual, hasLength(10));
      expect(c.convencional.autoabastecidoAnual, hasLength(10));
    });

    test('el aporte de la batería baja con los años', () {
      final conv = aporteAnual(c.convencional, c.referencia!);
      final consc = aporteAnual(c.consciente, c.referencia!);
      expect(conv, hasLength(10));
      expect(conv.first, closeTo(1, 0.01)); // casi nueva el primer año
      expect(conv.last, lessThan(conv.first - 0.05));
      for (var i = 1; i < conv.length; i++) {
        expect(conv[i], lessThanOrEqualTo(conv[i - 1] + 1e-9));
      }
      // La consciente no carga por encima de 95 %: aporta menos desde el
      // primer año (≈ 4 %), a cambio de degradarse más despacio.
      expect(consc.first, lessThan(conv.first - 0.02));
      expect(consc.first - consc.last, lessThan(conv.first - conv.last));
    });

    test('más allá de lo simulado sigue la tendencia, sin subir', () {
      final f = aportePorEdad([1, 0.98, 0.96]);
      expect(f(1), 1);
      expect(f(3), 0.96);
      expect(f(5), closeTo(0.92, 1e-9));
      expect(f(200), 0); // nunca negativo
      expect(aportePorEdad([0.95, 0.97])(4), 0.97); // no inventa mejoras
      expect(aportePorEdad(const [])(7), 1);
    });

    test('el ahorro de cada año usa el aporte y se recupera al reemplazar', () {
      final sinAporte = calcular(hibrida, vidaBateriaAnios: 5);
      final conAporte = calcular(
        hibrida,
        vidaBateriaAnios: 5,
        aporteBateria: (edad) => 1 - 0.05 * (edad - 1),
      );
      // Año 1: batería nueva, mismo ahorro.
      expect(conAporte.flujo[0].ahorro, closeTo(sinAporte.flujo[0].ahorro, 1));
      // Año 5 (edad 5): menos ahorro; año 6 (batería nueva): se recupera.
      double relativo(int anio) =>
          conAporte.flujo[anio - 1].ahorro / sinAporte.flujo[anio - 1].ahorro;
      expect(relativo(5), lessThan(0.98));
      expect(relativo(6), closeTo(1, 1e-9));
      // Lo que la batería no guarda se vende a la red (factor 0,7): el
      // ahorro cae menos que el aporte.
      expect(relativo(5), greaterThan(0.8));
      expect(conAporte.vpn, lessThan(sinAporte.vpn));
    });

    test('sin batería (conectado a la red) el aporte no cambia nada', () {
      const red = EntradasCalculo(
        tipo: TipoSistema.onGrid,
        modo: ModoConsumo.factura,
        consumoFacturaKwhMes: 300,
        hsp: 5,
      );
      expect(calcular(red, aporteBateria: (_) => 0.5).vpn, calcular(red).vpn);
    });

    test('impacto: compara la calculadora con cada política', () {
      final i = calcularImpacto(
        origen: origen,
        convencional: c.convencional,
        consciente: c.consciente,
        referencia: c.referencia,
        elegida: Politica.consciente,
      );
      expect(i.calculadora.vpn, origen.resultado.vpn);
      expect(i.calculadora.vidaAnios, 10);
      // Las dos vidas de cada política, y la que se usa es la menor.
      for (final f in [i.convencional, i.consciente]) {
        expect(f.vidaCalendarioAnios, 15);
        expect(f.vidaAnios, math.min(f.vidaUsoAnios!, 15));
      }
      expect(i.consciente.vidaAnios, greaterThan(i.convencional.vidaAnios!));
      // Con la energía que deja de aportar, la batería simulada ahorra menos
      // que la que "rinde igual siempre" de la calculadora.
      expect(i.convencional.ahorroTotal, lessThan(i.calculadora.ahorroTotal));
      expect(i.consciente.ahorroTotal, lessThan(i.convencional.ahorroTotal));
      // Contar solo la vida (lo de antes) sobrestimaba el VPN.
      final soloVida = calcularImpacto(
        origen: origen,
        convencional: c.convencional,
        consciente: c.consciente,
        referencia: null,
        elegida: Politica.consciente,
      );
      expect(i.convencional.vpn, lessThan(soloVida.convencional.vpn));
      expect(i.consciente.vpn, lessThan(soloVida.consciente.vpn));

      // Se guarda y se lee igual (columna `resultados.financiero`).
      final leido = ImpactoFinanciero.desdeMapa(i.aMapa());
      expect(leido.elegida, Politica.consciente);
      expect(leido.consciente.vpn, i.consciente.vpn);
      expect(leido.convencional.paybackAnios, i.convencional.paybackAnios);
      expect(leido.consciente.vidaUsoAnios, i.consciente.vidaUsoAnios);
      expect(leido.consciente.valorResidual, i.consciente.valorResidual);
      expect(
        c.aFila(financiero: i.aMapa())['resultados']['financiero'],
        i.aMapa(),
      );
      expect((c.aFila()['resultados'] as Map).containsKey('financiero'), false);
    });
  });

  test('con una vida calendario corta, manda el calendario y hay más '
      'reemplazos', () {
    const corta = EntradasCalculo(
      tipo: TipoSistema.hibrido,
      modo: ModoConsumo.factura,
      consumoFacturaKwhMes: 300,
      hsp: 5,
      supuestos: Supuestos(vidaCalendarioBateria: 6),
    );
    final origen = OrigenCalculo(entradas: corta, resultado: calcular(corta));
    final c = simularComparacion((
      parametros: parametrosDesdeCalculo(origen).copiarCon(anios: 3),
      semilla: 3,
    ));
    final i = calcularImpacto(
      origen: origen,
      convencional: c.convencional,
      consciente: c.consciente,
      referencia: c.referencia,
      elegida: Politica.convencional,
    );
    expect(i.convencional.limitaCalendario, isTrue);
    expect(i.convencional.vidaAnios, 6);
    // Con 6 años en 20: reemplazos en los años 6, 12 y 18; al final la
    // batería tiene 2 de sus 6 años (quedan 4/6 de su valor).
    final r = calcular(corta, vidaBateriaAnios: 6);
    expect(
      [
        for (final a in r.flujo)
          if (a.reemplazoBateria > 0) a.anio,
      ],
      [6, 12, 18],
    );
    expect(r.valorResidual, closeTo(r.costos.baterias * 4 / 6, 1e-6));
  });

  testWidgets('de la calculadora a la simulación vinculada', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calculos = _FakeCalculos();
    final simulaciones = _FakeSimulaciones();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
          ),
          calculadoraRepositoryProvider.overrideWithValue(calculos),
          simulacionRepositoryProvider.overrideWithValue(simulaciones),
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

    Future<void> tocar(Finder f) async {
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Finder boton(String t) => find.widgetWithText(FilledButton, t);

    // Calculadora: sistema híbrido con batería de litio.
    await tocar(find.text('Calcular mi sistema solar'));
    await tocar(find.text('Híbrido'));
    await tocar(boton('Siguiente'));
    await tocar(boton('Siguiente'));
    await tocar(find.text('Manual'));
    await tocar(boton('Siguiente'));
    await tocar(boton('Calcular'));
    await tocar(boton('Guardar cálculo'));

    // Simulación con los valores del cálculo.
    await tocar(find.text('Simular la salud de esta batería'));
    expect(find.text('Valores de tu cálculo'), findsOneWidget);
    // HSP escritas a mano: sin datos del clima, zona mixta.
    expect(
      find.textContaining('Sin datos del clima del lugar'),
      findsOneWidget,
    );
    await tocar(boton('Simular'));

    expect(find.text('Con el sistema que dimensionaste'), findsOneWidget);
    expect(find.text('Calculadora'), findsOneWidget);
    expect(find.textContaining('En plata conviene'), findsOneWidget);
    await tocar(boton('Guardar simulación'));
    expect(simulaciones.calculosVinculados, ['calc-1']);
    // Con el cálculo de origen, se guarda también su impacto en la inversión.
    expect(simulaciones.impactos.single, isNotNull);
  });

  testWidgets('con una ciudad, la simulación usa la zona de su clima', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calculos = _FakeCalculos();
    final simulaciones = _FakeSimulaciones();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
          ),
          calculadoraRepositoryProvider.overrideWithValue(calculos),
          simulacionRepositoryProvider.overrideWithValue(simulaciones),
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

    Future<void> tocar(Finder f) async {
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Finder boton(String t) => find.widgetWithText(FilledButton, t);

    // Calculadora: sistema híbrido con batería de litio.
    await tocar(find.text('Calcular mi sistema solar'));
    await tocar(find.text('Híbrido'));
    await tocar(boton('Siguiente'));
    await tocar(boton('Siguiente'));
    await tocar(find.byType(DropdownButtonFormField<Ciudad>));
    await tocar(find.textContaining('Barranquilla').last);
    await tocar(boton('Siguiente'));
    await tocar(boton('Calcular'));
    await tocar(boton('Guardar cálculo'));

    // Simulación: zona según el clima de Barranquilla (despejada).
    await tocar(find.text('Simular la salud de esta batería'));
    expect(find.textContaining('Del cálculo'), findsOneWidget);
    expect(find.textContaining('Zona muy soleada'), findsOneWidget);
    expect(find.textContaining('Zona según la lluvia'), findsOneWidget);
  });
}

class _FakeCalculos implements CalculadoraRepository {
  @override
  Future<Precios> obtenerPrecios() async => Precios.referencia;

  @override
  Future<List<Ciudad>> obtenerCiudades() async => ciudadesBase;

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) async => 'calc-1';
}

class _FakeSimulaciones implements SimulacionRepository {
  final calculosVinculados = <String?>[];
  final impactos = <ImpactoFinanciero?>[];

  @override
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
    ImpactoFinanciero? impacto,
  }) async {
    calculosVinculados.add(calculoId);
    impactos.add(impacto);
  }
}
