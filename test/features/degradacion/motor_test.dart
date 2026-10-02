import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';
import 'package:solarix/features/degradacion/domain/simulador.dart';
import 'package:solarix/features/degradacion/domain/submodelos.dart';

import '../../../tool/referencias_netlogo.dart';

void main() {
  group('Clima (nuevo-dia)', () {
    test('probabilidades de la cadena de Markov', () {
      expect(probabilidadesClima(ClimaDia.soleado, 1), [0.70, 0.25, 0.05]);
      // Lluvia ×2 → 1,0 → tope 0,9; las otras se reescalan por 0,1/0,5.
      final p = probabilidadesClima(ClimaDia.lluvia, 2);
      expect(p[0], closeTo(0.03, 1e-12));
      expect(p[1], closeTo(0.07, 1e-12));
      expect(p[2], 0.9);
      expect(p.reduce((a, b) => a + b), closeTo(1, 1e-12));
    });
    test('elige el clima con un número uniforme', () {
      expect(siguienteClima(ClimaDia.soleado, 1, 0.69), ClimaDia.soleado);
      expect(siguienteClima(ClimaDia.soleado, 1, 0.70), ClimaDia.nublado);
      expect(siguienteClima(ClimaDia.soleado, 1, 0.96), ClimaDia.lluvia);
    });
    test('nubosidad media por tipo de día, zona y tormenta', () {
      expect(nubosidadMedia(ClimaDia.soleado, 1, false), 0.15);
      expect(nubosidadMedia(ClimaDia.lluvia, 1.2, false), 0.95); // tope
      expect(nubosidadMedia(ClimaDia.soleado, 1, true), 0.6); // tormenta
    });
  });

  group('Entorno (actualizar-entorno)', () {
    test('mes del día del año', () {
      expect(mesDelDia(1), 0);
      expect(mesDelDia(31), 0);
      expect(mesDelDia(32), 1);
      expect(mesDelDia(365), 11);
    });
    test('irradiancia: campana de 6 a 18 h, en grados', () {
      // Mediodía, enero (cos 0 = 1 → ×1,05), cielo despejado: 800 · 1,05.
      expect(
        irradiancia(maxima: 800, hora: 12, mes: 0, nubosidad: 0),
        closeTo(840, 1e-9),
      );
      expect(irradiancia(maxima: 800, hora: 6, mes: 0, nubosidad: 0), 0);
      expect(irradiancia(maxima: 800, hora: 3, mes: 0, nubosidad: 0), 0);
      // Nubosidad total: la mitad.
      expect(
        irradiancia(maxima: 800, hora: 12, mes: 0, nubosidad: 1),
        closeTo(420, 1e-9),
      );
    });
    test('temperatura con máximo a las 15:00 y 2 °C menos si llueve', () {
      expect(
        temperaturaBase(media: 27, desfaseDia: 0, hora: 15, llueve: false),
        closeTo(32, 1e-9),
      );
      expect(
        temperaturaBase(media: 27, desfaseDia: 1, hora: 15, llueve: true),
        closeTo(31, 1e-9),
      );
    });
    test('consumo: picos a las 7:00 y a las 20:00', () {
      expect(consumoBase(20), closeTo(2.3, 1e-6));
      expect(consumoBase(7), closeTo(1.5, 1e-6));
      // +3 % por °C sobre 24: a 34 °C, ×1,3.
      expect(
        consumoHora(hora: 20, temperatura: 34, factorDia: 1, ruido: 1),
        closeTo(2.3 * 1.3, 1e-6),
      );
      expect(
        consumoHora(hora: 3, temperatura: 20, factorDia: 1, ruido: 0),
        0.1,
      );
      expect(
        consumoHora(
          hora: 20,
          temperatura: 20,
          factorDia: 1,
          ruido: 1,
          factorConsumo: 0.5,
        ),
        closeTo(1.15, 1e-6),
      );
    });
  });

  group('Panel y polvo (actualizar-panel)', () {
    test('factor de polvo con mínimo 0,4', () {
      expect(factorPolvo(0), 1);
      expect(factorPolvo(100), closeTo(0.7, 1e-12));
      expect(factorPolvo(500), 0.4);
      expect(perdidaPorPolvo(50), closeTo(15, 1e-9));
    });
    test('el clima cambia la llegada de polvo', () {
      expect(
        factorClimaPolvo(
          tormenta: true,
          llueve: false,
          clima: ClimaDia.soleado,
        ),
        15,
      );
      expect(
        factorClimaPolvo(tormenta: false, llueve: true, clima: ClimaDia.lluvia),
        0.2,
      );
      expect(
        factorClimaPolvo(
          tormenta: false,
          llueve: false,
          clima: ClimaDia.soleado,
        ),
        1.3,
      );
      expect(
        factorClimaPolvo(
          tormenta: false,
          llueve: false,
          clima: ClimaDia.nublado,
        ),
        1,
      );
    });
    test('potencia con temperatura de celda y polvo', () {
      // 1000 W/m² y 0 °C → celda a 25 °C → sin pérdida térmica.
      expect(
        potenciaPanel(
          potenciaPicoKw: 5,
          irradiancia: 1000,
          temperaturaAmbiente: 0,
          polvoG: 0,
        ),
        closeTo(5, 1e-9),
      );
      expect(
        potenciaPanel(
          potenciaPicoKw: 5,
          irradiancia: 1000,
          temperaturaAmbiente: 0,
          polvoG: 100,
        ),
        closeTo(3.5, 1e-9),
      );
    });
  });

  group('Reparto de energía (despachar-energia)', () {
    const p = ParametrosSimulacion();
    test('el excedente carga la batería', () {
      final d = despachar(
        generacion: 4,
        consumo: 1,
        soc: 50,
        sohPorcentaje: 100,
        p: p,
      );
      expect(d.carga, closeTo(3, 1e-12));
      expect(d.descarga, 0);
      expect(d.red, 0);
    });
    test('el déficit descarga hasta el SOC mínimo y la red cubre el resto', () {
      // SOC 30 → disponible (30−20) % de 10 kWh · 0,95 = 0,95 kWh.
      final d = despachar(
        generacion: 0,
        consumo: 3,
        soc: 30,
        sohPorcentaje: 100,
        p: p,
      );
      expect(d.descarga, closeTo(0.95, 1e-12));
      expect(d.red, closeTo(2.05, 1e-12));
    });
    test('la política consciente limita la corriente y el tope a 95 %', () {
      final consciente = p.copiarCon(politica: Politica.consciente);
      final d = despachar(
        generacion: 4,
        consumo: 1,
        soc: 50,
        sohPorcentaje: 100,
        p: consciente,
      );
      expect(d.carga, closeTo(1.6, 1e-12)); // 0,16 C · 10 kWh
      final llena = despachar(
        generacion: 4,
        consumo: 1,
        soc: 95,
        sohPorcentaje: 100,
        p: consciente,
      );
      expect(llena.carga, 0);
    });
    test('la capacidad efectiva baja con el SoH', () {
      // SoH 80 %: 8 kWh efectivos → límite 0,5 C = 4 kW.
      final d = despachar(
        generacion: 6,
        consumo: 0,
        soc: 20,
        sohPorcentaje: 80,
        p: p,
      );
      expect(d.carga, closeTo(4, 1e-12));
    });
    test('nuevo SOC con eficiencia del 95 %', () {
      expect(
        nuevoSoc(soc: 50, carga: 1, descarga: 0, capacidadEfectiva: 10),
        closeTo(59.5, 1e-12),
      );
      expect(
        nuevoSoc(soc: 99, carga: 5, descarga: 0, capacidadEfectiva: 10),
        100,
      );
    });
  });

  group('Degradación (Ec. 1 a 5)', () {
    test('acumula x, c-rms y sigma-soc', () {
      final e = EstresBateria()
        ..agregar(potenciaKw: 5, soc: 60, capacidadNominalKwh: 10)
        ..agregar(potenciaKw: 0, soc: 60, capacidadNominalKwh: 10);
      expect(e.x, closeTo(0.5, 1e-12));
      expect(e.cRms, closeTo(0.353553, 1e-6)); // √((0,25 + 0) / 2)
      expect(e.sigmaSoc, closeTo(0, 1e-9));
      expect(e.ciclosEquivalentes, closeTo(0.25, 1e-12));
    });
    test('sin uso no hay degradación', () {
      expect(
        sohDesdeSeveridad(
          severidad(EstresBateria(), const ParametrosSimulacion()),
        ),
        100,
      );
    });
  });

  group('Simulador', () {
    test('la misma semilla da la misma corrida', () {
      const p = ParametrosSimulacion(anios: 1);
      final a = simular(p, semilla: 7);
      final b = simular(p, semilla: 7);
      final c = simular(p, semilla: 8);
      expect(a.sohFinal, b.sohFinal);
      expect(a.energiaCompradaKwh, b.energiaCompradaKwh);
      expect(c.energiaCompradaKwh, isNot(a.energiaCompradaKwh));
    });

    test('10 años: SoH anual, serie diaria y SoH que nunca sube', () {
      final r = simular(const ParametrosSimulacion());
      expect(r.horasSimuladas, 87600);
      expect(r.sohAnual, hasLength(11));
      expect(r.sohAnual.first, 100);
      for (var k = 1; k < r.sohAnual.length; k++) {
        expect(r.sohAnual[k], lessThanOrEqualTo(r.sohAnual[k - 1]));
      }
      expect(r.dias, hasLength(3650));
      expect(r.dias.last.soh, r.sohFinal);
      expect(r.finDeVida, isFalse);
    });

    test('se detiene al llegar al fin de vida (SoH < 80 %)', () {
      final r = simular(
        const ParametrosSimulacion(exponenteDegradacion: 1.3),
        registrarDias: false,
      );
      expect(r.finDeVida, isTrue);
      expect(r.sohFinal, lessThan(80));
      expect(r.horasSimuladas, lessThan(87600));
      expect(r.sohAnual.length, lessThan(11));
    });

    test('con sol bajo la batería casi no se usa', () {
      final r = simular(
        const ParametrosSimulacion(escenario: EscenarioIrradiancia.baja),
        registrarDias: false,
      );
      expect(r.sohFinal, greaterThan(99.9));
    });

    test('el factor de consumo escala la demanda de la casa', () {
      const p = ParametrosSimulacion(anios: 1);
      final normal = simular(p, registrarDias: false);
      final mitad = simular(
        p.copiarCon(factorConsumo: 0.5),
        registrarDias: false,
      );
      expect(normal.consumoKwh / 365, closeTo(20, 1.5)); // ≈ 20 kWh/día
      expect(mitad.consumoKwh / normal.consumoKwh, closeTo(0.5, 0.01));
    });

    test('una corrida de 10 años es rápida', () {
      final reloj = Stopwatch()..start();
      simular(const ParametrosSimulacion(), registrarDias: false);
      // Margen amplio para el CI; en un PC tarda menos de 0,1 s.
      expect(reloj.elapsed, lessThan(const Duration(seconds: 3)));
    });
  });

  group('Validación estadística contra NetLogo (VALIDACION.md)', () {
    for (final caso in casosValidacion) {
      test('${caso.escenario.name} / ${caso.politica.name}, 10 semillas', () {
        final corridas = [
          for (var s = 1; s <= 10; s++)
            simular(
              ParametrosSimulacion(
                escenario: caso.escenario,
                politica: caso.politica,
              ),
              semilla: s,
              registrarDias: false,
            ),
        ];
        double media(double Function(ResultadoSimulacion) f) =>
            corridas.map(f).reduce((a, b) => a + b) / corridas.length;

        expect(media((r) => r.sohFinal), closeTo(caso.sohFinal, 0.3));
        expect(
          media((r) => r.energiaCompradaKwh) / caso.comprada,
          closeTo(1, 0.03),
        );
        expect(
          media((r) => r.ciclosEquivalentes) / caso.ciclos,
          closeTo(1, 0.03),
        );
        if (caso.politica == Politica.convencional) {
          final referencia = caso.escenario == EscenarioIrradiancia.media
              ? sohAnualMediaNetlogo
              : sohAnualAltaNetlogo;
          for (var k = 0; k <= 10; k++) {
            expect(
              media((r) => r.sohAnual[k]),
              closeTo(referencia[k], 0.3),
              reason: 'año $k',
            );
          }
        }
      });
    }
  });
}
