import 'dart:math' as math;

import '../../calculadora/domain/modelos.dart';
import 'parametros.dart';
import 'simulador.dart';

/// Conexión entre la calculadora (Etapa 3) y la simulación (Etapas 4–5).

/// Cálculo del que parte la simulación.
class OrigenCalculo {
  const OrigenCalculo({
    required this.entradas,
    required this.resultado,
    this.calculoId,
  });

  final EntradasCalculo entradas;
  final ResultadoCalculo resultado;

  /// `id` en `calculos_consumo` si el cálculo ya se guardó.
  final String? calculoId;
}

/// Año de referencia (con la semilla 1) para medir el modelo sin azar.
const _semillaReferencia = 1;

final _consumoModelo = <EscenarioIrradiancia, double>{};
final _hspModelo = <EscenarioIrradiancia, double>{};

ResultadoSimulacion _anioReferencia(EscenarioIrradiancia e) => simular(
  ParametrosSimulacion(escenario: e, anios: 1),
  semilla: _semillaReferencia,
);

/// Consumo medio diario (kWh) del perfil de NetLogo con factor 1. Depende del
/// escenario porque el consumo sube 3 % por °C sobre 24.
double consumoDiarioModelo(EscenarioIrradiancia e) =>
    _consumoModelo.putIfAbsent(e, () => _anioReferencia(e).consumoKwh / 365);

/// Horas solares pico medias que produce el entorno del modelo.
double hspModelo(EscenarioIrradiancia e) => _hspModelo.putIfAbsent(e, () {
  final dias = _anioReferencia(e).dias;
  final total = dias.fold<double>(0, (s, d) => s + d.irradianciaMedia * 24);
  return total / dias.length / 1000;
});

/// Escenario del modelo cuyas HSP están más cerca de las del lugar.
EscenarioIrradiancia escenarioParaHsp(double hsp) =>
    EscenarioIrradiancia.values.reduce(
      (a, b) =>
          (hspModelo(a) - hsp).abs() <= (hspModelo(b) - hsp).abs() ? a : b,
    );

/// Factor que lleva el consumo del modelo al consumo calculado.
double factorConsumoPara(double energiaDiaKwh, EscenarioIrradiancia e) =>
    energiaDiaKwh / consumoDiarioModelo(e);

/// Parámetros de la simulación a partir del sistema dimensionado.
ParametrosSimulacion parametrosDesdeCalculo(OrigenCalculo o) {
  final escenario = escenarioParaHsp(o.entradas.hsp);
  return ParametrosSimulacion(
    capacidadBateriaKwh: o.resultado.bateriaKwh,
    potenciaPanelKw: o.resultado.potenciaInstaladaKw,
    escenario: escenario,
    factorConsumo: factorConsumoPara(o.resultado.energiaDiaKwh, escenario),
  );
}

/// Años hasta el fin de vida (SoH < 80 %). Si no se alcanza en la
/// simulación, se extrapola con la pérdida anual media; `null` si la batería
/// prácticamente no se degrada.
double? aniosHastaFinDeVida(ResultadoSimulacion r) {
  if (r.finDeVida) return r.aniosSimulados;
  final perdida = r.perdidaAnual;
  if (perdida < 0.01) return null;
  return (100 - Constantes.sohUmbral) / perdida;
}

/// Vida de la batería en años enteros para el flujo de caja.
int? vidaBateriaParaFlujo(ResultadoSimulacion r) {
  final anios = aniosHastaFinDeVida(r);
  if (anios == null) return null;
  return math.max(1, anios.round());
}
