import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/formato.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/calculadora/data/recurso_solar.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';

const bombillos = Equipo(
  nombre: 'Bombillo',
  potenciaW: 9,
  horasDia: 5,
  cantidad: 4,
);
const nevera = Equipo(
  nombre: 'Nevera',
  potenciaW: 150,
  kwhDia: 1.2,
  factorArranque: 4,
);
const televisor = Equipo(nombre: 'TV', potenciaW: 80, horasDia: 4);
const bomba = Equipo(
  nombre: 'Bomba',
  potenciaW: 750,
  horasDia: 1,
  factorArranque: 4,
);

/// Hogar conectado a la red con 300 kWh/mes de factura y 5 HSP.
const hogarRed = EntradasCalculo(
  tipo: TipoSistema.onGrid,
  modo: ModoConsumo.factura,
  consumoFacturaKwhMes: 300,
  tarifaKwh: 1000,
  hsp: 5,
);

void main() {
  group('Energía diaria', () {
    test('suma equipos por horas y por ciclos (Wh/día)', () {
      // 9·5·4 = 180, nevera 1,2 kWh = 1200, TV 80·4 = 320.
      const e = EntradasCalculo(
        tipo: TipoSistema.offGrid,
        hsp: 5,
        equipos: [bombillos, nevera, televisor],
      );
      expect(energiaDiariaWh(e), 1700);
    });
    test('desde la factura: kWh/mes · 1000 / 30', () {
      expect(energiaDiariaWh(hogarRed), closeTo(10000, 1e-9));
    });
  });

  group('Dimensionamiento', () {
    test('paneles = ceil(E / (HSP · PR) / W_panel)', () {
      // 10000 / (5 · 0,78) = 2564 W → 4,66 paneles de 550 W → 5.
      expect(
        numeroPaneles(
          energiaWh: 10000,
          hsp: 5,
          rendimiento: 0.78,
          potenciaPanelW: 550,
        ),
        5,
      );
      expect(
        numeroPaneles(
          energiaWh: 100,
          hsp: 5,
          rendimiento: 0.78,
          potenciaPanelW: 550,
        ),
        1,
      );
      expect(
        numeroPaneles(
          energiaWh: 0,
          hsp: 5,
          rendimiento: 0.78,
          potenciaPanelW: 550,
        ),
        0,
      );
    });

    test('voltaje del banco: 12 / 24 / 48 V', () {
      expect(voltajeSistema(1499), 12);
      expect(voltajeSistema(1500), 24);
      expect(voltajeSistema(3999), 24);
      expect(voltajeSistema(4000), 48);
    });

    test('batería = E · días / (DoD · η)', () {
      const s = Supuestos();
      // Aislado, plomo: 1700 · 2 / (0,5 · 0,9) = 7555,6 Wh.
      expect(
        capacidadBateriaWh(
          tipo: TipoSistema.offGrid,
          energiaDiaWh: 1700,
          quimica: QuimicaBateria.plomo,
          supuestos: s,
        ),
        closeTo(7555.56, 0.01),
      );
      // Híbrido, litio: 10000 · 0,5 · 1 / (0,9 · 0,9) = 6172,8 Wh.
      expect(
        capacidadBateriaWh(
          tipo: TipoSistema.hibrido,
          energiaDiaWh: 10000,
          quimica: QuimicaBateria.litio,
          supuestos: s,
        ),
        closeTo(6172.84, 0.01),
      );
      expect(
        capacidadBateriaWh(
          tipo: TipoSistema.onGrid,
          energiaDiaWh: 10000,
          quimica: QuimicaBateria.litio,
          supuestos: s,
        ),
        0,
      );
    });

    test('tamaño comercial: el primero que alcanza', () {
      expect(tamanoComercial(300, tamanosInversorW), 300);
      expect(tamanoComercial(1250, tamanosInversorW), 1500);
      expect(tamanoComercial(25000, tamanosInversorW), 40000);
    });

    test('inversor con equipos considera el arranque del motor', () {
      // Continuo 830 W; arranque de la bomba +2250 W → 3080 W → 4000 W.
      const e = EntradasCalculo(
        tipo: TipoSistema.offGrid,
        hsp: 5,
        equipos: [bomba, televisor],
      );
      expect(
        potenciaInversorW(entradas: e, potenciaPanelesW: 0, energiaDiaWh: 0),
        4000,
      );
    });

    test('inversor de red = potencia de paneles; factura sin equipos', () {
      expect(
        potenciaInversorW(
          entradas: hogarRed,
          potenciaPanelesW: 2750,
          energiaDiaWh: 10000,
        ),
        3000,
      );
      // Aislado por factura: 10000 / 24 · 3 · 1,25 = 1562 W → 2000 W.
      const aislado = EntradasCalculo(
        tipo: TipoSistema.offGrid,
        modo: ModoConsumo.factura,
        consumoFacturaKwhMes: 300,
        hsp: 5,
      );
      expect(
        potenciaInversorW(
          entradas: aislado,
          potenciaPanelesW: 2750,
          energiaDiaWh: 10000,
        ),
        2000,
      );
    });

    test('controlador = P / V · 1,25; sin controlador en red', () {
      // 2750 / 48 · 1,25 = 71,6 A → 80 A.
      expect(
        corrienteControladorA(
          tipo: TipoSistema.hibrido,
          potenciaPanelesW: 2750,
          voltaje: 48,
        ),
        80,
      );
      expect(
        corrienteControladorA(
          tipo: TipoSistema.onGrid,
          potenciaPanelesW: 2750,
          voltaje: 0,
        ),
        0,
      );
    });
  });

  test('costos con precios de referencia', () {
    final c = calcularCostos(
      entradas: hogarRed,
      paneles: 5,
      bateriaKwh: 0,
      inversorW: 3000,
      controladorA: 0,
    );
    expect(c.paneles, 2887500); // 5 · 550 W · 1050
    expect(c.inversor, 2700000); // 3000 W · 900
    expect(c.estructura, 1500000); // 5 · 300 000
    expect(c.instalacion, closeTo(2126250, 1e-6)); // 30 % de 7 087 500
    expect(c.total, closeTo(9213750, 1e-6));
  });

  test('el costo por kWp instalado está en el rango del mercado', () {
    // Mercado residencial colombiano 2026: 2 a 5,5 millones COP por kWp
    // instalado, con RETIE y trámites (fuentes en docs/BITACORA.md).
    for (final consumo in [150.0, 300.0, 600.0]) {
      final r = calcular(
        EntradasCalculo(
          tipo: TipoSistema.onGrid,
          modo: ModoConsumo.factura,
          consumoFacturaKwhMes: consumo,
          hsp: 4.5,
        ),
      );
      final porKwp = r.costos.total / r.potenciaInstaladaKw;
      expect(
        porKwp,
        inInclusiveRange(2000000, 5500000),
        reason: '$consumo kWh',
      );
    }
  });

  group('Ahorro mensual', () {
    test('red: autoconsumo a tarifa y excedentes al 70 %', () {
      // Genera 600, consume 300: autoconsumo min(600 · 0,6; 300) = 300.
      final a = ahorroMensual(
        entradas: hogarRed,
        generacionMesKwh: 600,
        consumoMesKwh: 300,
      );
      expect(a.autoconsumo, 300);
      expect(a.excedente, 300);
      expect(a.ahorro, 300 * 1000 + 300 * 700);
    });
    test('aislado: el gasto actual en energía', () {
      const e = EntradasCalculo(
        tipo: TipoSistema.offGrid,
        hsp: 5,
        gastoActualMensual: 120000,
      );
      final a = ahorroMensual(
        entradas: e,
        generacionMesKwh: 50,
        consumoMesKwh: 40,
      );
      expect(a.ahorro, 120000);
      expect(a.excedente, 0);
    });
  });

  group('Flujo de caja', () {
    const sinCrecimiento = Supuestos(
      incrementoTarifa: 0,
      degradacionPaneles: 0,
      mantenimientoAnual: 0,
      tasaDescuento: 0.10,
      anios: 5,
    );

    test('reemplaza la batería cada vida útil, salvo el último año', () {
      final flujo = flujoDeCaja(
        inversion: 1000,
        ahorroAnualInicial: 300,
        costoBaterias: 100,
        vidaBateriaAnios: 2,
        supuestos: sinCrecimiento,
      );
      expect([for (final a in flujo) a.reemplazoBateria], [0, 100, 0, 100, 0]);
      expect([for (final a in flujo) a.acumulado], [-700, -500, -200, 0, 300]);
      final cuatroAnios = flujoDeCaja(
        inversion: 1000,
        ahorroAnualInicial: 300,
        costoBaterias: 100,
        vidaBateriaAnios: 2,
        supuestos: const Supuestos(anios: 4),
      );
      expect(cuatroAnios.last.reemplazoBateria, 0);
    });

    test('recuperación simple, descontada y VPN', () {
      final flujo = flujoDeCaja(
        inversion: 1000,
        ahorroAnualInicial: 300,
        costoBaterias: 100,
        vidaBateriaAnios: 2,
        supuestos: sinCrecimiento,
      );
      expect(
        recuperacionAnios(1000, [for (final a in flujo) a.acumulado]),
        closeTo(4.0, 1e-9),
      );
      // Descontado al 10 % no alcanza a recuperarse en 5 años.
      expect(
        recuperacionAnios(1000, [for (final a in flujo) a.acumuladoDescontado]),
        isNull,
      );
      expect(flujo.last.acumuladoDescontado, closeTo(-13.71, 0.01));
    });

    test('la recuperación interpola dentro del año', () {
      expect(recuperacionAnios(100, [-50, 50]), closeTo(1.5, 1e-9));
    });

    test('el ahorro crece con la tarifa y cae con los paneles', () {
      final flujo = flujoDeCaja(
        inversion: 0,
        ahorroAnualInicial: 1000,
        costoBaterias: 0,
        vidaBateriaAnios: 0,
        supuestos: const Supuestos(
          incrementoTarifa: 0.10,
          degradacionPaneles: 0.01,
          anios: 2,
        ),
      );
      expect(flujo[1].ahorro, closeTo(1000 * 1.10 * 0.99, 1e-9));
    });
  });

  group('Cálculo completo', () {
    test('hogar conectado a la red con factura de 300 kWh/mes', () {
      final r = calcular(hogarRed);
      expect(r.energiaDiaKwh, closeTo(10, 1e-9));
      expect(r.numeroPaneles, 5);
      expect(r.potenciaInstaladaKw, closeTo(2.75, 1e-9));
      // 2,75 kW · 5 HSP · 0,78 · 30 = 321,75 kWh/mes.
      expect(r.generacionMesKwh, closeTo(321.75, 1e-9));
      expect(r.bateriaKwh, 0);
      expect(r.voltajeSistema, 0);
      expect(r.controladorA, 0);
      expect(r.inversorW, 3000);
      expect(r.costos.total, closeTo(9213750, 1e-6));
      // Autoconsumo 193,05 a $1000 + excedente 128,7 a $700.
      expect(r.ahorroMensual, closeTo(283140, 0.01));
      expect(r.flujo, hasLength(20));
      expect(r.paybackAnios, isNotNull);
      expect(r.paybackAnios!, lessThan(20));
    });

    test('vivienda aislada con equipos y batería de plomo', () {
      const e = EntradasCalculo(
        tipo: TipoSistema.offGrid,
        hsp: 4.5,
        equipos: [bombillos, nevera, televisor],
        quimica: QuimicaBateria.plomo,
        gastoActualMensual: 150000,
      );
      final r = calcular(e);
      expect(r.energiaDiaKwh, closeTo(1.7, 1e-9));
      expect(r.voltajeSistema, 24);
      expect(r.bateriaKwh, closeTo(7.5556, 0.0001));
      expect(r.bateriaAh, closeTo(314.8, 0.1));
      // 1700 / (4,5 · 0,78) = 484 W → 1 panel de 550 W; 550 / 24 · 1,25 → 30 A.
      expect(r.numeroPaneles, 1);
      expect(r.controladorA, 30);
      expect(r.excedenteMesKwh, 0);
      expect(r.ahorroMensual, 150000);
      // Plomo dura 4 años: reemplazos en los años 4, 8, 12 y 16.
      expect(
        [
          for (final a in r.flujo)
            if (a.reemplazoBateria > 0) a.anio,
        ],
        [4, 8, 12, 16],
      );
    });

    test('se guarda en Supabase con las columnas esperadas', () {
      final r = calcular(hogarRed);
      final entradas = hogarRed.aMapa();
      expect(entradas['tipo'], 'on_grid');
      expect(entradas['precios'], isA<Map<String, dynamic>>());
      final resultados = r.aMapa();
      expect(resultados['numero_paneles'], 5);
      expect((resultados['flujo'] as List), hasLength(20));
      expect((resultados['costos'] as Map)['total'], closeTo(9213750, 1e-6));
    });
  });

  test('Precios.desdeFilas completa lo que falte con la referencia', () {
    final p = Precios.desdeFilas({'panel_por_wp': 1000});
    expect(p.panelPorWp, 1000);
    expect(p.bateriaLitioPorKwh, Precios.referencia.bateriaLitioPorKwh);
  });

  group('La migración coincide con los valores locales', () {
    final sql = File('supabase/migrations/20261001000100_calculadora.sql')
        .readAsStringSync();

    test('precios de referencia', () {
      final filas = {
        for (final m in RegExp(r"\('(\w+)',\s+([\d.]+),").allMatches(sql))
          m.group(1)!: double.parse(m.group(2)!),
      };
      expect(filas, Precios.referencia.aMapa());
    });

    test('ciudades y HSP', () {
      final filas = [
        for (final m in RegExp(
          r"\('([^']+)',\s+'([^']+)',\s+([\d.]+)\)",
        ).allMatches(sql))
          '${m.group(1)}|${m.group(2)}|${double.parse(m.group(3)!)}',
      ];
      expect(filas, [
        for (final c in ciudadesBase) '${c.nombre}|${c.departamento}|${c.hsp}',
      ]);
    });
  });

  group('Ciudades y zonas', () {
    test('las HSP se clasifican en las zonas del modelo', () {
      expect(zonaParaHsp(5.0), ZonaIrradiancia.alta);
      expect(zonaParaHsp(4.5), ZonaIrradiancia.media);
      expect(zonaParaHsp(3.5), ZonaIrradiancia.baja);
    });
    test('la lista local es válida y sin repetidos', () {
      final nombres = {for (final c in ciudadesBase) c.etiqueta};
      expect(nombres, hasLength(ciudadesBase.length));
      for (final c in ciudadesBase) {
        expect(c.hsp, inInclusiveRange(2, 8));
      }
    });
  });

  group('NASA POWER', () {
    test('lee el promedio anual de la respuesta', () {
      const cuerpo =
          '{"properties":{"parameter":{"ALLSKY_SFC_SW_DWN":'
          '{"JAN":5.1,"ANN":5.0294}}}}';
      expect(hspDesdeRespuestaNasa(cuerpo), closeTo(5.0294, 1e-9));
    });
    test('rechaza respuestas sin dato anual', () {
      const cuerpo =
          '{"properties":{"parameter":{"ALLSKY_SFC_SW_DWN":{"ANN":-999}}}}';
      expect(
        () => hspDesdeRespuestaNasa(cuerpo),
        throwsA(isA<FormatException>()),
      );
    });
    test('arma la URL con las coordenadas', () {
      final uri = uriNasaPower(latitud: 8.24, longitud: -73.35);
      expect(uri.host, 'power.larc.nasa.gov');
      expect(uri.queryParameters['latitude'], '8.240');
      expect(uri.queryParameters['longitude'], '-73.350');
      expect(uri.queryParameters['parameters'], 'ALLSKY_SFC_SW_DWN');
    });
  });

  group('Formato', () {
    test('lee números escritos a la colombiana', () {
      expect(Formato.leer('1.500.000'), 1500000);
      expect(Formato.leer('1.500'), 1500);
      expect(Formato.leer('4,5'), 4.5);
      expect(Formato.leer('4.5'), 4.5);
      expect(Formato.leer(r'$ 950'), 950);
      expect(Formato.leer('abc'), isNull);
      expect(Formato.leer(''), isNull);
    });
    test('muestra pesos con separador de miles', () {
      expect(Formato.cop(1500000), contains('1.500.000'));
      expect(Formato.anios(null, 20), 'Más de 20 años');
    });
  });
}
