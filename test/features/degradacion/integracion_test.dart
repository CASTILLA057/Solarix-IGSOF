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
    test('elige el escenario del modelo más cercano a las HSP', () {
      // El escenario "alto" del modelo da ≈ 5 HSP, el "medio" ≈ 3,5 y el
      // "bajo" casi nada (50 W/m² de máximo).
      expect(hspModelo(EscenarioIrradiancia.alta), closeTo(5, 0.8));
      expect(hspModelo(EscenarioIrradiancia.baja), lessThan(1));
      expect(escenarioParaHsp(5.5), EscenarioIrradiancia.alta);
      expect(escenarioParaHsp(3.5), EscenarioIrradiancia.media);
      expect(escenarioParaHsp(0.3), EscenarioIrradiancia.baja);
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
      // ≈ 1,5 %/año → 20 / 1,5 ≈ 13 años.
      expect(
        aniosHastaFinDeVida(normal),
        closeTo(20 / normal.perdidaAnual, 1e-9),
      );
      expect(vidaBateriaParaFlujo(normal), inInclusiveRange(12, 15));

      final rapida = simular(
        const ParametrosSimulacion(exponenteDegradacion: 1.3),
        registrarDias: false,
      );
      expect(aniosHastaFinDeVida(rapida), rapida.aniosSimulados);

      final sinUso = simular(
        const ParametrosSimulacion(escenario: EscenarioIrradiancia.baja),
        registrarDias: false,
      );
      expect(vidaBateriaParaFlujo(sinUso), isNull);
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
    await tocar(boton('Simular'));

    expect(find.text('Con el sistema que dimensionaste'), findsOneWidget);
    expect(find.text('Con simulación'), findsOneWidget);
    await tocar(boton('Guardar simulación'));
    expect(simulaciones.calculosVinculados, ['calc-1']);
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

  @override
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
  }) async => calculosVinculados.add(calculoId);
}
