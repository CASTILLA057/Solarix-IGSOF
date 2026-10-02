/// Submodelos de SimDeg-FV como funciones puras, una por procedimiento de
/// NetLogo. NetLogo trabaja en grados: `sin` y `cos` reciben grados.
library;

import 'dart:math' as math;

import 'parametros.dart';

double senoGrados(double grados) => math.sin(grados * math.pi / 180);
double cosenoGrados(double grados) => math.cos(grados * math.pi / 180);

// ---------------------------------------------------------------------------
// Clima diario (procedimiento `nuevo-dia`)
// ---------------------------------------------------------------------------

enum ClimaDia { soleado, nublado, lluvia }

/// Probabilidades [soleado, nublado, lluvia] de la cadena de Markov según el
/// clima de ayer, con la probabilidad de lluvia escalada por la zona y el
/// año (máximo 0,9) y las otras dos reescaladas para sumar 1.
List<double> probabilidadesClima(ClimaDia ayer, double factorLluviaTotal) {
  final base = switch (ayer) {
    ClimaDia.soleado => const [0.70, 0.25, 0.05],
    ClimaDia.nublado => const [0.30, 0.45, 0.25],
    ClimaDia.lluvia => const [0.15, 0.35, 0.50],
  };
  final pLluvia = math.min(0.9, base[2] * factorLluviaTotal);
  final resto = (1 - pLluvia) / (1 - base[2]);
  return [base[0] * resto, base[1] * resto, pLluvia];
}

/// Elige el clima de hoy con un número uniforme `r` en [0, 1).
ClimaDia siguienteClima(ClimaDia ayer, double factorLluviaTotal, double r) {
  final p = probabilidadesClima(ayer, factorLluviaTotal);
  if (r < p[0]) return ClimaDia.soleado;
  if (r < p[0] + p[1]) return ClimaDia.nublado;
  return ClimaDia.lluvia;
}

/// Nubosidad media del tipo de día, ajustada por la zona (máximo 0,95) y
/// con mínimo 0,6 durante una tormenta de polvo.
double nubosidadMedia(ClimaDia clima, double factorNubes, bool tormenta) {
  var n = switch (clima) {
    ClimaDia.soleado => 0.15,
    ClimaDia.nublado => 0.6,
    ClimaDia.lluvia => 0.9,
  };
  n = math.min(0.95, n * factorNubes);
  return tormenta ? math.max(n, 0.6) : n;
}

// ---------------------------------------------------------------------------
// Entorno hora a hora (procedimiento `actualizar-entorno`)
// ---------------------------------------------------------------------------

/// Mes (0–11) a partir del día del año (1–365).
int mesDelDia(int diaAnio) => math.min(11, ((diaAnio - 1) / 30.42).floor());

/// Irradiancia (W/m²): campana solar de 6:00 a 18:00 × variación estacional
/// (±5 %) × efecto de las nubes (hasta la mitad).
double irradiancia({
  required double maxima,
  required int hora,
  required int mes,
  required double nubosidad,
}) {
  final fSolar = math.max(0.0, senoGrados(180 * (hora - 6) / 12));
  final fMes = 1 + 0.05 * cosenoGrados(360 * mes / 12);
  return maxima * fSolar * fMes * (1 - 0.5 * nubosidad);
}

/// Temperatura (°C) sin ruido: media + variación del día + ciclo diario con
/// máximo a las 15:00; 2 °C menos si llueve.
double temperaturaBase({
  required double media,
  required double desfaseDia,
  required int hora,
  required bool llueve,
}) =>
    media +
    desfaseDia +
    5 * senoGrados(360 * (hora - 9) / 24) -
    (llueve ? 2 : 0);

/// Consumo de fondo de la casa (kW): 0,3 kW + pico de la mañana (7:00) +
/// pico de la noche (20:00).
double consumoBase(int hora) =>
    0.3 +
    1.2 * math.exp(-math.pow((hora - 7) / 1.5, 2)) +
    2.0 * math.exp(-math.pow((hora - 20) / 2, 2));

/// Consumo de la hora (kW): +3 % por °C sobre 24, variación del día y ruido
/// de la hora; mínimo 0,1 kW. `factorConsumo` escala el perfil (Etapa 6).
double consumoHora({
  required int hora,
  required double temperatura,
  required double factorDia,
  required double ruido,
  double factorConsumo = 1,
}) => math.max(
  0.1,
  consumoBase(hora) *
      factorConsumo *
      (1 + 0.03 * math.max(0, temperatura - 24)) *
      factorDia *
      ruido,
);

// ---------------------------------------------------------------------------
// Arreglo fotovoltaico y polvo (procedimiento `actualizar-panel`)
// ---------------------------------------------------------------------------

/// Fracción de potencia que deja pasar el polvo (mínimo 0,4).
double factorPolvo(double polvoG) =>
    math.max(0.4, 1 - Constantes.kPolvo * polvoG);

/// Pérdida de potencia por polvo en %.
double perdidaPorPolvo(double polvoG) => (1 - factorPolvo(polvoG)) * 100;

/// Multiplicador de llegada de polvo según el clima de la hora.
double factorClimaPolvo({
  required bool tormenta,
  required bool llueve,
  required ClimaDia clima,
}) {
  if (tormenta) return 15;
  if (llueve) return 0.2;
  return clima == ClimaDia.soleado ? 1.3 : 1;
}

/// Potencia del arreglo (kW) con pérdidas por temperatura de celda y polvo.
double potenciaPanel({
  required double potenciaPicoKw,
  required double irradiancia,
  required double temperaturaAmbiente,
  required double polvoG,
}) {
  final tCelda = temperaturaAmbiente + 0.025 * irradiancia;
  return math.max(
    0.0,
    potenciaPicoKw *
        (irradiancia / 1000) *
        (1 - Constantes.coefTemp * (tCelda - 25)) *
        factorPolvo(polvoG),
  );
}

// ---------------------------------------------------------------------------
// Reparto de energía (procedimiento `despachar-energia`)
// ---------------------------------------------------------------------------

/// Resultado del despacho de una hora (kW, equivalentes a kWh en 1 h).
typedef Despacho = ({double carga, double descarga, double red});

/// Balance P2 + batería + P4 = consumo (Ec. 9): solar directo a la casa, el
/// excedente carga la batería hasta el SOC máximo y el déficit la descarga
/// hasta el SOC mínimo, sin pasar el límite de potencia; la red cubre el
/// resto. Lo que no cabe en la batería se pierde (no se vende).
Despacho despachar({
  required double generacion,
  required double consumo,
  required double soc,
  required double sohPorcentaje,
  required ParametrosSimulacion p,
}) {
  final capacidadEfectiva = p.capacidadBateriaKwh * sohPorcentaje / 100;
  final consciente = p.politica == Politica.consciente;
  final socMax = consciente
      ? math.min(p.cargaMaxima, Constantes.socMaxConsciente)
      : p.cargaMaxima;
  final limite =
      capacidadEfectiva *
      (consciente
          ? math.min(p.tasaCMaxima, Constantes.cMaxConsciente)
          : p.tasaCMaxima);
  const eta = Constantes.eficiencia;
  final directo = math.min(generacion, consumo);
  final excedente = generacion - directo;
  final deficit = consumo - directo;
  final carga = excedente > 0
      ? math.max(
          0.0,
          [
            excedente,
            limite,
            (socMax - soc) / 100 * capacidadEfectiva / eta,
          ].reduce(math.min),
        )
      : 0.0;
  final descarga = deficit > 0
      ? math.max(
          0.0,
          [
            deficit,
            limite,
            (soc - p.cargaMinima) / 100 * capacidadEfectiva * eta,
          ].reduce(math.min),
        )
      : 0.0;
  return (carga: carga, descarga: descarga, red: deficit - descarga);
}

/// Nuevo SOC (%) tras cargar y descargar durante una hora.
double nuevoSoc({
  required double soc,
  required double carga,
  required double descarga,
  required double capacidadEfectiva,
}) =>
    (soc +
            (carga * Constantes.eficiencia - descarga / Constantes.eficiencia) /
                capacidadEfectiva *
                100)
        .clamp(0, 100)
        .toDouble();

// ---------------------------------------------------------------------------
// Degradación (procedimiento `actualizar-bateria`, Ec. 1 a 5)
// ---------------------------------------------------------------------------

/// Acumula los factores de estrés de la batería hora a hora.
class EstresBateria {
  /// Ec. 1: energía acumulada normalizada (ciclos equivalentes × 2).
  double x = 0;
  int _muestras = 0;
  double _sumaP2 = 0;
  double _sumaSoc = 0;
  double _sumaSoc2 = 0;

  /// Agrega una hora con potencia `potenciaKw` (carga + descarga) y el SOC
  /// resultante (%).
  void agregar({
    required double potenciaKw,
    required double soc,
    required double capacidadNominalKwh,
  }) {
    final relativa = potenciaKw / capacidadNominalKwh;
    x += relativa;
    _muestras++;
    _sumaP2 += relativa * relativa;
    final s = soc / 100;
    _sumaSoc += s;
    _sumaSoc2 += s * s;
  }

  /// Ec. 2: estrés por corriente eficaz.
  double get cRms => _muestras == 0 ? 0 : math.sqrt(_sumaP2 / _muestras);

  /// Ec. 3: variabilidad del SOC (desviación estándar, fracción).
  double get sigmaSoc {
    if (_muestras == 0) return 0;
    final media = _sumaSoc / _muestras;
    return math.sqrt(math.max(0, _sumaSoc2 / _muestras - media * media));
  }

  double get ciclosEquivalentes => x / 2;
}

/// Ec. 5: severidad `Z = α · x^β · (1 + γ · c-rms) · (1 + δ · σ-soc)`.
double severidad(EstresBateria e, ParametrosSimulacion p) =>
    p.escalaDegradacion *
    math.pow(e.x, p.exponenteDegradacion) *
    (1 + p.pesoCorriente * e.cRms) *
    (1 + p.pesoVariacionCarga * e.sigmaSoc);

/// Ec. 4: `SoH = 100 · e^(−Z)` en %.
double sohDesdeSeveridad(double z) => 100 * math.exp(-z);
