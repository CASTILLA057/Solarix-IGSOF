import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/formato.dart';
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

  group('Ahorro mensual (CREG 174 de 2021)', () {
    test('excedente hasta lo importado se permuta a tarifa menos Cv', () {
      // Genera 400, consume 300: autoconsumo min(400 · 0,6; 300) = 240,
      // excedente 160, importa 60. Se permutan 60 a $1000 − $100 y los otros
      // 100 se venden a bolsa ($300).
      final a = ahorroMensual(
        entradas: hogarRed,
        generacionMesKwh: 400,
        consumoMesKwh: 300,
      );
      expect(a.autoconsumo, 240);
      expect(a.excedente, 160);
      expect(a.permutado, 60);
      expect(a.vendido, 100);
      expect(a.ahorro, 240 * 1000 + 60 * 900 + 100 * 300);
    });
    test('sin importación todo el excedente va a bolsa', () {
      // Genera 600, consume 300: autoconsumo 300, no importa nada.
      final a = ahorroMensual(
        entradas: hogarRed,
        generacionMesKwh: 600,
        consumoMesKwh: 300,
      );
      expect(a.autoconsumo, 300);
      expect(a.permutado, 0);
      expect(a.vendido, 300);
      expect(a.ahorro, 300 * 1000 + 300 * 300);
    });
    test('excedente menor que lo importado: todo se permuta', () {
      final a = valorEnergiaMes(
        autoconsumo: 100,
        excedente: 50,
        consumo: 300,
        tarifa: 1000,
        supuestos: const Supuestos(),
      );
      expect(a.permutado, 50);
      expect(a.vendido, 0);
      expect(a.ahorro, 100 * 1000 + 50 * 900);
    });
    test('si Cv supera la tarifa, la permuta no vale negativo', () {
      final a = valorEnergiaMes(
        autoconsumo: 0,
        excedente: 10,
        consumo: 100,
        tarifa: 80,
        supuestos: const Supuestos(costoComercializacion: 100),
      );
      expect(a.ahorro, 0);
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
      // La batería del año 4 se usa solo 1 de sus 2 años: al final se
      // devuelve la mitad de su costo como valor residual (Etapa 12).
      expect([for (final a in flujo) a.valorResidual], [0, 0, 0, 0, 50]);
      expect([for (final a in flujo) a.acumulado], [-700, -500, -200, 0, 350]);
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
      // Descontado al 10 %, el valor residual del año 5 (50 / 1,1⁵) lo hace
      // recuperarse justo antes de terminar.
      expect(
        recuperacionAnios(1000, [for (final a in flujo) a.acumuladoDescontado]),
        closeTo(4.92, 0.01),
      );
      expect(flujo.last.acumuladoDescontado, closeTo(-13.71 + 31.05, 0.01));
    });

    test('valor residual: lineal, solo el último año y solo si queda vida', () {
      Iterable<double> residuales(int vida, int anios) => flujoDeCaja(
        inversion: 1000,
        ahorroAnualInicial: 300,
        costoBaterias: 100,
        vidaBateriaAnios: vida,
        supuestos: Supuestos(anios: anios),
      ).map((a) => a.valorResidual);
      // Dura más que el horizonte (25 de 20 años): quedan 5 de 25.
      expect(residuales(25, 20).last, closeTo(20, 1e-9));
      expect(residuales(25, 20).take(19), everyElement(0));
      // Termina justo al final (10 + 10 = 20): no queda nada.
      expect(residuales(10, 20).last, 0);
      // Sin batería, nada.
      expect(
        flujoDeCaja(
          inversion: 1000,
          ahorroAnualInicial: 300,
          costoBaterias: 0,
          vidaBateriaAnios: 0,
          supuestos: const Supuestos(),
        ).last.valorResidual,
        0,
      );
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
      // Autoconsumo 193,05 a $1000; importa 106,95, que se permutan a $900;
      // los 21,75 restantes se venden a $300.
      expect(r.excedentePermutadoMesKwh, closeTo(106.95, 1e-9));
      expect(r.excedenteVendidoMesKwh, closeTo(21.75, 1e-9));
      expect(r.ahorroMensual, closeTo(193050 + 96255 + 6525, 0.01));
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

    group('Incentivos de la Ley 1715 de 2014', () {
      test('sin incentivos por defecto', () {
        final r = calcular(hogarRed);
        expect(r.costos.ivaExcluido, 0);
        expect(r.beneficioRenta, 0);
      });

      test('la exclusión de IVA quita el 19 % de toda la inversión', () {
        final r = calcular(
          const EntradasCalculo(
            tipo: TipoSistema.onGrid,
            modo: ModoConsumo.factura,
            consumoFacturaKwhMes: 300,
            tarifaKwh: 1000,
            hsp: 5,
            supuestos: Supuestos(exclusionIva: true),
          ),
        );
        expect(r.costos.total, closeTo(9213750 / 1.19, 0.01));
        expect(r.costos.ivaExcluido, closeTo(9213750 - 9213750 / 1.19, 0.01));
        expect(r.costos.paneles, closeTo(2887500 / 1.19, 0.01));
        final sinIva = calcular(hogarRed);
        expect(r.paybackAnios!, lessThan(sinIva.paybackAnios!));
      });

      test('deducción de renta: 50 % de la inversión por la tarifa, año 1', () {
        final r = calcular(
          const EntradasCalculo(
            tipo: TipoSistema.onGrid,
            modo: ModoConsumo.factura,
            consumoFacturaKwhMes: 300,
            tarifaKwh: 1000,
            hsp: 5,
            supuestos: Supuestos(tarifaRenta: 0.35),
          ),
        );
        final esperado = 9213750 * 0.5 * 0.35;
        expect(r.beneficioRenta, closeTo(esperado, 0.01));
        expect(r.flujo.first.beneficioTributario, closeTo(esperado, 0.01));
        expect(
          r.flujo.skip(1).map((a) => a.beneficioTributario),
          everyElement(0),
        );
        final sin = calcular(hogarRed);
        expect(
          r.flujo.first.neto - sin.flujo.first.neto,
          closeTo(esperado, 0.01),
        );
      });

      test('se guardan en el flujo y en los supuestos', () {
        const s = Supuestos(exclusionIva: true, tarifaRenta: 0.2);
        expect(s.aMapa()['exclusion_iva'], true);
        expect(s.aMapa()['tarifa_renta'], 0.2);
        final r = calcular(
          const EntradasCalculo(
            tipo: TipoSistema.onGrid,
            modo: ModoConsumo.factura,
            consumoFacturaKwhMes: 300,
            hsp: 5,
            supuestos: s,
          ),
        );
        final mapa = r.aMapa();
        expect((mapa['costos'] as Map)['iva_excluido'], greaterThan(0));
        expect(mapa['beneficio_renta'], greaterThan(0));
        expect(
          ((mapa['flujo'] as List).first as Map)['beneficio_tributario'],
          greaterThan(0),
        );
      });
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
      expect(
        uri.queryParameters['parameters'],
        'ALLSKY_SFC_SW_DWN,PRECTOTCORR,CLOUD_AMT,T2M',
      );
    });
    test('lee la lluvia y la nubosidad (y tolera que falten)', () {
      const cuerpo =
          '{"properties":{"parameter":{"ALLSKY_SFC_SW_DWN":{"ANN":5.03},'
          '"PRECTOTCORR":{"ANN":2.77},"CLOUD_AMT":{"ANN":71.23},'
          '"T2M":{"ANN":20.5}}},"geometry":{"coordinates":[-73.3,8.2,1450.17]}}';
      final clima = climaDesdeRespuestaNasa(cuerpo)!;
      expect(clima.lluviaMmDia, 2.77);
      expect(clima.nubosidadPct, 71.23);
      // Sin altitud del lugar, la de NASA; con ella, corregida por altitud
      // (Ocaña, a 1.202 m, en una celda de 1.450 m: ≈ 1,6 °C más).
      expect(clima.temperaturaC, 20.5);
      expect(
        climaDesdeRespuestaNasa(cuerpo, altitudLugar: 1202)!.temperaturaC,
        closeTo(20.5 + 0.0065 * (1450.17 - 1202), 1e-9),
      );
      expect(clima.lluviaMmAnio, closeTo(1011, 1));
      expect(
        climaDesdeRespuestaNasa(
          '{"properties":{"parameter":{"ALLSKY_SFC_SW_DWN":{"ANN":5.03}}}}',
        ),
        isNull,
      );
    });
  });

  group('Formato', () {
    test('lee números escritos a la colombiana', () {
      expect(Formato.leer('1.500.000'), 1500000);
      expect(Formato.leer('1.500'), 1500);
      expect(Formato.leer('4,5'), 4.5);
      expect(Formato.leer('4.5'), 4.5);
      // Empieza en "0.": decimal, no miles.
      expect(Formato.leer('0.036'), 0.036);
      expect(Formato.leer('0,036'), 0.036);
      expect(Formato.leer('0.0000078'), 0.0000078);
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
