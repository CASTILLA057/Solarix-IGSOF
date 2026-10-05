import 'dart:math' as math;

import '../../calculadora/domain/calculadora.dart';
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

/// Años de referencia (con la semilla 1) para medir el modelo sin azar: 10
/// años (lo mismo que se simula) promedian las variaciones de lluvia y polvo
/// de un año a otro, que en el modelo van de × 0,6 a × 1,6.
const _semillaReferencia = 1;
const _aniosReferencia = 10;

final _referencias =
    <
      (EscenarioIrradiancia, ZonaClimatica, double?, double?),
      ResultadoSimulacion
    >{};

/// Corrida de referencia con el entorno (escenario, zona, irradiancia y
/// temperatura) de [p], el perfil de consumo de NetLogo y la semilla fija.
ResultadoSimulacion _referencia(ParametrosSimulacion p) =>
    _referencias.putIfAbsent(
      (p.escenario, p.zona, p.irradianciaMaximaLugar, p.temperaturaMediaLugar),
      () => simular(
        ParametrosSimulacion(
          escenario: p.escenario,
          zona: p.zona,
          irradianciaMaximaLugar: p.irradianciaMaximaLugar,
          temperaturaMediaLugar: p.temperaturaMediaLugar,
          anios: _aniosReferencia,
        ),
        semilla: _semillaReferencia,
      ),
    );

/// Consumo medio diario (kWh) del perfil de NetLogo con factor 1 en ese
/// entorno: depende de la temperatura (sube 3 % por °C sobre 24).
double consumoDiarioModelo(ParametrosSimulacion entorno) =>
    _referencia(entorno).consumoKwh / (365 * _aniosReferencia);

/// Horas solares pico medias que produce el modelo en ese entorno.
double hspModelo(ParametrosSimulacion entorno) {
  final dias = _referencia(entorno).dias;
  final total = dias.fold<double>(0, (s, d) => s + d.irradianciaMedia * 24);
  return total / dias.length / 1000;
}

/// HSP de una configuración de NetLogo (escenario y zona).
double hspEscenario(
  EscenarioIrradiancia e, [
  ZonaClimatica z = ZonaClimatica.mixta,
]) => hspModelo(ParametrosSimulacion(escenario: e, zona: z));

/// Escenario cuya forma de día (y lluvia, nubes y polvo de la zona) se usa
/// para un lugar; su irradiancia máxima y su temperatura se reemplazan por
/// las del lugar.
const escenarioBase = EscenarioIrradiancia.alta;

/// Tope físico de la irradiancia máxima (W/m²): más que eso no llega al
/// suelo. Si un lugar lo necesita, su zona está mal asignada.
const irradianciaMaximaTope = 1100.0;

/// Irradiancia máxima con la que el modelo, en la zona del lugar, produce
/// sus HSP reales. La irradiancia del modelo es proporcional a la máxima y
/// el azar del clima no depende de ella, así que basta una proporción (no
/// hace falta buscar con varias corridas).
double irradianciaMaximaPara(double hsp, ZonaClimatica zona) =>
    escenarioBase.irradianciaMaxima * hsp / hspEscenario(escenarioBase, zona);

/// Factor que lleva el consumo del modelo (en ese entorno) al calculado.
double factorConsumoPara(double energiaDiaKwh, ParametrosSimulacion entorno) =>
    energiaDiaKwh / consumoDiarioModelo(entorno);

/// Zona climática del modelo según el clima del lugar (NASA POWER), por
/// orden: lluviosa (≥ 2.500 mm/año), polvorienta (seca, < 1.000 mm/año, y
/// despejada, nubosidad < 60 %), muy soleada (nubosidad < 60 %), muy
/// nublada (≥ 1.600 mm/año o nubosidad ≥ 80 %) y, si no, mixta. Sin datos
/// del clima (HSP a mano), mixta.
ZonaClimatica zonaParaClima(ClimaLugar? clima) {
  if (clima == null) return ZonaClimatica.mixta;
  final lluvia = clima.lluviaMmAnio;
  final nubes = clima.nubosidadPct;
  if (lluvia >= 2500) return ZonaClimatica.lluviosa;
  if (nubes < 60) {
    return lluvia < 1000 ? ZonaClimatica.polvorienta : ZonaClimatica.muySoleada;
  }
  if (lluvia >= 1600 || nubes >= 80) return ZonaClimatica.muyNublada;
  return ZonaClimatica.mixta;
}

/// Entorno de la simulación para un lugar (Etapa 12): zona según su clima,
/// irradiancia máxima que da sus HSP en esa zona y su temperatura media (sin
/// datos del clima, la del escenario base). Solo cambian las entradas de
/// NetLogo, no sus ecuaciones.
ParametrosSimulacion entornoDelLugar({required double hsp, ClimaLugar? clima}) {
  final zona = zonaParaClima(clima);
  return ParametrosSimulacion(
    escenario: escenarioBase,
    zona: zona,
    irradianciaMaximaLugar: irradianciaMaximaPara(hsp, zona),
    temperaturaMediaLugar: clima?.temperaturaC,
  );
}

/// Parámetros de la simulación a partir del sistema dimensionado: el
/// entorno del lugar del cálculo, la batería y los paneles dimensionados y
/// el consumo ajustado al de la casa.
ParametrosSimulacion parametrosDesdeCalculo(OrigenCalculo o) {
  final entorno = entornoDelLugar(hsp: o.entradas.hsp, clima: o.entradas.clima);
  return entorno.copiarCon(
    capacidadBateriaKwh: o.resultado.bateriaKwh,
    potenciaPanelKw: o.resultado.potenciaInstaladaKw,
    factorConsumo: factorConsumoPara(o.resultado.energiaDiaKwh, entorno),
  );
}

/// Años de uso hasta el fin de vida (SoH < 80 %) según la simulación.
///
/// Si la simulación llega al 80 %, son los años simulados. Si no, se
/// extiende con la forma del propio modelo: `SoH = 100·e^(−Z)` con `Z` que
/// crece como `a·tᵇ` (el estrés acumulado elevado al exponente de la
/// degradación); `a` y `b` se ajustan a los años simulados. Una recta sobre
/// el SoH (lo que se hacía antes) no respeta esa curva. `null` si la batería
/// prácticamente no se degrada.
double? aniosHastaFinDeVida(ResultadoSimulacion r) {
  if (r.finDeVida) return r.aniosSimulados;
  if (r.perdidaAnual < 0.01) return null;
  final zObjetivo = -math.log(Constantes.sohUmbral / 100);
  final puntos = [
    for (var t = 1; t < r.sohAnual.length; t++)
      if (r.sohAnual[t] < 100) (t.toDouble(), -math.log(r.sohAnual[t] / 100)),
  ];
  if (puntos.isEmpty) {
    // Menos de un año simulado: con el exponente del modelo.
    final z = -math.log(r.sohFinal / 100);
    if (z <= 0) return null;
    return r.aniosSimulados *
        math.pow(zObjetivo / z, 1 / r.parametros.exponenteDegradacion);
  }
  final (b, lnA) = puntos.length == 1
      ? (
          r.parametros.exponenteDegradacion,
          math.log(puntos.single.$2) -
              r.parametros.exponenteDegradacion * math.log(puntos.single.$1),
        )
      : _rectaLogLog(puntos);
  // El exponente ajustado se acota a un rango físico razonable.
  final exponente = b.clamp(0.3, 2.0);
  final a = math.exp(lnA);
  return math.pow(zObjetivo / a, 1 / exponente).toDouble();
}

/// Mínimos cuadrados de `ln Z = ln a + b·ln t`; devuelve `(b, ln a)`.
(double, double) _rectaLogLog(List<(double, double)> puntos) {
  final xs = [for (final (t, _) in puntos) math.log(t)];
  final ys = [for (final (_, z) in puntos) math.log(z)];
  final n = xs.length;
  final mx = xs.reduce((p, q) => p + q) / n;
  final my = ys.reduce((p, q) => p + q) / n;
  var num = 0.0, den = 0.0;
  for (var i = 0; i < n; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  final b = den == 0 ? 1.0 : num / den;
  return (b, my - b * mx);
}

/// Vida de la batería para el flujo de caja: la menor entre la vida por uso
/// (simulación) y la vida calendario, porque el modelo no incluye el
/// envejecimiento calendario (Etapa 12).
typedef VidaBateria = ({
  double? porUso,
  double calendario,
  double efectiva,
  bool limitaCalendario,
});

VidaBateria vidaBateria(ResultadoSimulacion r, {required double calendario}) {
  final porUso = aniosHastaFinDeVida(r);
  final limitaCalendario = porUso == null || calendario < porUso;
  return (
    porUso: porUso,
    calendario: calendario,
    efectiva: limitaCalendario ? calendario : porUso,
    limitaCalendario: limitaCalendario,
  );
}

/// Vida de la batería en años enteros para el flujo de caja (con el tope
/// calendario).
int vidaBateriaParaFlujo(ResultadoSimulacion r, {required double calendario}) =>
    math.max(1, vidaBateria(r, calendario: calendario).efectiva.round());

/// Energía que la batería de [r] entrega a la casa en cada año completo,
/// como fracción de la que entrega la [referencia] (batería convencional que
/// no se degrada) con el mismo clima: así se aísla el efecto de la
/// degradación (y de la política) del de un año más o menos soleado.
List<double> aporteAnual(
  ResultadoSimulacion r,
  ResultadoSimulacion referencia,
) {
  final n = math.min(
    r.autoabastecidoAnual.length,
    referencia.autoabastecidoAnual.length,
  );
  return [
    for (var i = 0; i < n; i++)
      referencia.autoabastecidoAnual[i] <= 0
          ? 1.0
          : (r.autoabastecidoAnual[i] / referencia.autoabastecidoAnual[i])
                .clamp(0.0, 1.0),
  ];
}

/// Aporte para cualquier edad de la batería (1 = primer año): el simulado o,
/// más allá de los años simulados, la tendencia lineal (mínimos cuadrados)
/// de los años simulados. Sin datos, 1 (como una batería nueva).
double Function(int edad) aportePorEdad(List<double> aporte) {
  if (aporte.isEmpty) return (_) => 1;
  final n = aporte.length;
  var pendiente = 0.0;
  if (n >= 2) {
    final mediaX = (n + 1) / 2;
    final mediaY = aporte.reduce((a, b) => a + b) / n;
    var num = 0.0, den = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = i + 1 - mediaX;
      num += dx * (aporte[i] - mediaY);
      den += dx * dx;
    }
    // La degradación nunca devuelve energía: la tendencia no sube.
    pendiente = math.min(0, num / den);
  }
  return (edad) {
    if (edad <= n) return aporte[math.max(1, edad) - 1];
    return (aporte.last + pendiente * (edad - n)).clamp(0.0, 1.0);
  };
}

/// Cifras de la inversión con una vida y un aporte de batería dados.
class CifrasFinancieras {
  const CifrasFinancieras({
    required this.vidaAnios,
    this.vidaUsoAnios,
    this.vidaCalendarioAnios,
    this.valorResidual = 0,
    required this.paybackAnios,
    required this.vpn,
    required this.costoTotal,
    required this.ahorroTotal,
  });

  factory CifrasFinancieras.desdeResultado(
    ResultadoCalculo r, {
    required double? vidaAnios,
    VidaBateria? vida,
  }) => CifrasFinancieras(
    vidaAnios: vidaAnios,
    vidaUsoAnios: vida?.porUso,
    vidaCalendarioAnios: vida?.calendario,
    valorResidual: r.valorResidual,
    paybackAnios: r.paybackAnios,
    vpn: r.vpn,
    costoTotal: r.gastosTotales - r.valorResidual - r.beneficioRenta,
    ahorroTotal: r.ahorroTotal,
  );

  factory CifrasFinancieras.desdeMapa(Map<String, dynamic> m) =>
      CifrasFinancieras(
        vidaAnios: (m['vida_anios'] as num?)?.toDouble(),
        vidaUsoAnios: (m['vida_uso_anios'] as num?)?.toDouble(),
        vidaCalendarioAnios: (m['vida_calendario_anios'] as num?)?.toDouble(),
        valorResidual: (m['valor_residual'] as num?)?.toDouble() ?? 0,
        paybackAnios: (m['payback_anios'] as num?)?.toDouble(),
        vpn: (m['vpn'] as num?)?.toDouble() ?? 0,
        costoTotal: (m['costo_total'] as num?)?.toDouble() ?? 0,
        ahorroTotal: (m['ahorro_total'] as num?)?.toDouble() ?? 0,
      );

  /// Vida que se usa en el flujo de caja (años).
  final double? vidaAnios;

  /// Solo con simulación: vida por uso (años hasta el 80 %; `null` si casi
  /// no se degrada) y vida calendario. [vidaAnios] es la menor.
  final double? vidaUsoAnios;
  final double? vidaCalendarioAnios;

  bool get limitaCalendario =>
      vidaCalendarioAnios != null &&
      (vidaUsoAnios == null || vidaCalendarioAnios! < vidaUsoAnios!);

  /// Valor de la batería que sigue útil al final del horizonte.
  final double valorResidual;

  /// `null` si no se recupera dentro del horizonte.
  final double? paybackAnios;
  final double vpn;

  /// Inversión, mantenimiento y reemplazos de batería en el horizonte, menos
  /// el valor residual y la deducción de renta (Ley 1715).
  final double costoTotal;

  /// Ahorro sumado en el horizonte (sin descontar).
  final double ahorroTotal;

  Map<String, dynamic> aMapa() => {
    'vida_anios': vidaAnios,
    'vida_uso_anios': vidaUsoAnios,
    'vida_calendario_anios': vidaCalendarioAnios,
    'valor_residual': valorResidual,
    'payback_anios': paybackAnios,
    'vpn': vpn,
    'costo_total': costoTotal,
    'ahorro_total': ahorroTotal,
  };
}

/// Efecto de la degradación simulada en la inversión del cálculo de origen:
/// lo que dice la calculadora (vida típica, sin degradación) frente a cada
/// política simulada (vida y aporte de la batería según la simulación).
class ImpactoFinanciero {
  const ImpactoFinanciero({
    required this.horizonteAnios,
    required this.vidaTipicaAnios,
    required this.elegida,
    required this.calculadora,
    required this.convencional,
    required this.consciente,
    this.sinRed = false,
  });

  factory ImpactoFinanciero.desdeMapa(Map<String, dynamic> m) {
    CifrasFinancieras cifras(String clave) => CifrasFinancieras.desdeMapa(
      (m[clave] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    return ImpactoFinanciero(
      horizonteAnios: (m['horizonte_anios'] as num?)?.toInt() ?? 20,
      vidaTipicaAnios: (m['vida_tipica_anios'] as num?)?.toInt() ?? 10,
      elegida: Politica.values.firstWhere(
        (p) => p.name == m['elegida'],
        orElse: () => Politica.convencional,
      ),
      calculadora: cifras('calculadora'),
      convencional: cifras('convencional'),
      consciente: cifras('consciente'),
      sinRed: m['sin_red'] == true,
    );
  }

  final int horizonteAnios;
  final int vidaTipicaAnios;
  final Politica elegida;
  final CifrasFinancieras calculadora;
  final CifrasFinancieras convencional;
  final CifrasFinancieras consciente;

  /// El cálculo de origen es un sistema aislado (Etapa 12): lo que el
  /// modelo cuenta como energía comprada a la red es energía que faltó.
  final bool sinRed;

  CifrasFinancieras de(Politica p) => switch (p) {
    Politica.convencional => convencional,
    Politica.consciente => consciente,
  };

  Map<String, dynamic> aMapa() => {
    'horizonte_anios': horizonteAnios,
    'vida_tipica_anios': vidaTipicaAnios,
    'elegida': elegida.name,
    'calculadora': calculadora.aMapa(),
    'convencional': convencional.aMapa(),
    'consciente': consciente.aMapa(),
    if (sinRed) 'sin_red': true,
  };
}

/// Recalcula el flujo de caja del [origen] con cada política simulada:
/// reemplazo de la batería al llegar al 80 % y ahorro año a año según la
/// energía que la batería realmente aporta ([aporteAnual]).
ImpactoFinanciero calcularImpacto({
  required OrigenCalculo origen,
  required ResultadoSimulacion convencional,
  required ResultadoSimulacion consciente,
  required ResultadoSimulacion? referencia,
  required Politica elegida,
}) {
  final e = origen.entradas;
  final horizonte = e.supuestos.anios;
  CifrasFinancieras conSimulacion(ResultadoSimulacion r) {
    final vida = vidaBateria(r, calendario: e.vidaCalendarioBateria);
    final resultado = calcular(
      e,
      vidaBateriaAnios: vidaBateriaParaFlujo(
        r,
        calendario: e.vidaCalendarioBateria,
      ),
      aporteBateria: referencia == null
          ? null
          : aportePorEdad(aporteAnual(r, referencia)),
    );
    return CifrasFinancieras.desdeResultado(
      resultado,
      vidaAnios: vida.efectiva,
      vida: vida,
    );
  }

  return ImpactoFinanciero(
    horizonteAnios: horizonte,
    vidaTipicaAnios: e.quimica.vidaUtilAnios,
    elegida: elegida,
    calculadora: CifrasFinancieras.desdeResultado(
      origen.resultado,
      vidaAnios: e.quimica.vidaUtilAnios.toDouble(),
    ),
    convencional: conSimulacion(convencional),
    consciente: conSimulacion(consciente),
    sinRed: !e.tipo.usaRed,
  );
}
