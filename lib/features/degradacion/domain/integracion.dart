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
    costoTotal: r.gastosTotales - r.valorResidual,
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
  /// el valor residual.
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
    );
  }

  final int horizonteAnios;
  final int vidaTipicaAnios;
  final Politica elegida;
  final CifrasFinancieras calculadora;
  final CifrasFinancieras convencional;
  final CifrasFinancieras consciente;

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
  );
}
