// Valida el motor SimDeg-FV en Dart contra los resultados de NetLogo
// (docs/referencia/VALIDACION.md y GUIA_VARIACION.md) y escribe
// docs/VALIDACION_DART.md. Es el equivalente de herramientas/validar_modelo.py.
//
// Uso:  dart run tool/validar_motor.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:solarix/features/degradacion/domain/parametros.dart';
import 'package:solarix/features/degradacion/domain/simulador.dart';

import 'referencias_netlogo.dart';

void main() {
  final reloj = Stopwatch()..start();
  final una = Stopwatch()..start();
  simular(const ParametrosSimulacion(), registrarDias: false);
  una.stop();

  final l = <String>[
    '# Solarix — Validación del motor en Dart frente a NetLogo (Etapa 4)',
    '',
    'Generado por `dart run tool/validar_motor.dart` el '
        '${_fecha(DateTime.now())}. Motor: '
        '`lib/features/degradacion/domain/`. Referencias: '
        '`docs/referencia/VALIDACION.md` (10 corridas de NetLogo por caso) y '
        '`docs/referencia/GUIA_VARIACION.md` (5 corridas por caso).',
    '',
    'NetLogo usa una semilla aleatoria distinta en cada corrida y su propio '
        'generador, así que la comparación es **estadística**: promedios de '
        'varias semillas en cada lado. Criterios del plan: SoH promedio a ±0,3 '
        'puntos (año a año), energía comprada a ±3 % y limpiezas dentro del '
        'rango observado.',
    '',
    'Tiempo de una corrida de 10 años (87 600 horas): '
        '**${una.elapsedMilliseconds} ms**.',
    '',
  ];

  // ---------------------------------------------------------------- (a) y (c)
  l
    ..add('## 1. Casos de VALIDACION.md (10 semillas)')
    ..add('')
    ..add(
      '| Escenario | Política | SoH final Dart | SoH final NetLogo | Dif. | '
      'Comprada Dart (kWh) | NetLogo | Dif. | Ciclos Dart | NetLogo | '
      'Limpiezas Dart | NetLogo | ¿Cumple? |',
    )
    ..add('|---|---|---|---|---|---|---|---|---|---|---|---|---|');
  final promedios = <(EscenarioIrradiancia, Politica), _Promedio>{};
  for (final r in casosValidacion) {
    final m = _correr(
      ParametrosSimulacion(escenario: r.escenario, politica: r.politica),
      10,
    );
    promedios[(r.escenario, r.politica)] = m;
    final difSoh = m.sohFinal - r.sohFinal;
    final difCompra = m.comprada / r.comprada - 1;
    final cumple = difSoh.abs() <= 0.3 && difCompra.abs() <= 0.03;
    l.add(
      '| ${r.escenario.name} | ${r.politica.name} | ${_n(m.sohFinal)} | '
      '${_n(r.sohFinal)} | ${_s(difSoh)} | ${_n(m.comprada, 0)} | '
      '${_n(r.comprada, 0)} | ${_p(difCompra)} | ${_n(m.ciclos, 0)} | '
      '${_n(r.ciclos, 0)} | ${_n(m.limpiezas, 0)} | ${_n(r.limpiezas, 0)} | '
      '${cumple ? 'sí' : 'no'} |',
    );
  }

  l
    ..add('')
    ..add('### SoH año a año, política convencional')
    ..add('')
    ..add(
      '| Año | Media Dart | Media NetLogo | Dif. | Alta Dart | Alta NetLogo '
      '| Dif. |',
    )
    ..add('|---|---|---|---|---|---|---|');
  final media = promedios[(EscenarioIrradiancia.media, Politica.convencional)]!;
  final alta = promedios[(EscenarioIrradiancia.alta, Politica.convencional)]!;
  var maxDif = 0.0;
  for (var k = 0; k <= 10; k++) {
    final dm = media.sohAnual[k] - sohAnualMediaNetlogo[k];
    final da = alta.sohAnual[k] - sohAnualAltaNetlogo[k];
    maxDif = math.max(maxDif, math.max(dm.abs(), da.abs()));
    l.add(
      '| $k | ${_n(media.sohAnual[k])} | ${_n(sohAnualMediaNetlogo[k])} | '
      '${_s(dm)} | ${_n(alta.sohAnual[k])} | ${_n(sohAnualAltaNetlogo[k])} | '
      '${_s(da)} |',
    );
  }
  l
    ..add('')
    ..add(
      'Mayor diferencia año a año: **${_n(maxDif)} puntos** (criterio ±0,3).',
    )
    ..add('')
    ..add(
      '### Ajuste a la referencia de 1,5 %/año (igual que validar_modelo.py)',
    )
    ..add('')
    ..add('| Escenario | R² Dart | R² NetLogo | RMSE Dart | RMSE NetLogo |')
    ..add('|---|---|---|---|---|');
  for (final (nombre, m, r2, rmse) in [
    ('media', media, 0.9819, 0.0064),
    ('alta', alta, 0.9993, 0.0012),
  ]) {
    final a = _ajuste(m.sohAnual);
    l.add(
      '| $nombre | ${_n(a.r2 * 100)} % | ${_n(r2 * 100)} % | '
      '${_n(a.rmse, 4)} | ${_n(rmse, 4)} |',
    );
  }

  l
    ..add('')
    ..add('### Política consciente frente a convencional')
    ..add('')
    ..add(
      '| Escenario | Medida | Cambio Dart | Cambio NetLogo | Objetivo del Word |',
    )
    ..add('|---|---|---|---|---|');
  for (final esc in [EscenarioIrradiancia.media, EscenarioIrradiancia.alta]) {
    final cv = promedios[(esc, Politica.convencional)]!;
    final cs = promedios[(esc, Politica.consciente)]!;
    final ref = cambiosConscienteNetlogo[esc]!;
    l
      ..add(
        '| ${esc.name} | Energía comprada | '
        '${_p(cs.comprada / cv.comprada - 1)} | ${_p(ref.energia)} | +4,8 % |',
      )
      ..add(
        '| ${esc.name} | Flujo de carga (ciclos) | '
        '${_p(cs.ciclos / cv.ciclos - 1)} | ${_p(ref.flujo)} | −34,0 % |',
      )
      ..add(
        '| ${esc.name} | Caída del SoH | '
        '${_p((100 - cs.sohFinal) / (100 - cv.sohFinal) - 1)} | '
        '${_p(ref.caidaSoh)} | −8,7 % |',
      );
  }

  // ------------------------------------------------------- GUIA_VARIACION.md
  l
    ..add('')
    ..add(
      '## 2. Sensibilidad: casos de GUIA_VARIACION.md '
      '($_semillasGuia semillas; NetLogo: 5 corridas)',
    )
    ..add('')
    ..add(
      'Escenario alto, política convencional y zona mixta, cambiando una '
      'variable a la vez. Las limpiezas varían mucho entre corridas (de 32 a '
      '113 en 100 semillas del caso de referencia), así que el promedio se '
      'compara con el rango de NetLogo y se usan más semillas que en NetLogo: '
      'con solo 5 el promedio de limpiezas depende demasiado de qué años '
      'tuvieron tormentas de polvo.',
    )
    ..add('')
    ..add(
      'La energía comprada se muestra como promedio ± desviación estándar '
      'entre semillas. La diferencia con NetLogo cumple si no supera el '
      'mayor entre 3 % y dos errores estándar de la diferencia de medias '
      '(2·σ·√(1/$_semillasGuia + 1/5)): cuando se compra poca energía (batería '
      'grande) el valor depende de pocas rachas nubladas y varía mucho entre '
      'corridas, así que un 3 % fijo confundiría azar con error.',
    )
    ..add('')
    ..add(
      '| Caso | SoH Dart | SoH NetLogo | Dif. | Comprada Dart | NetLogo | '
      'Dif. | Limpiezas Dart | NetLogo | ¿Cumple? |',
    )
    ..add('|---|---|---|---|---|---|---|---|---|---|');
  var cumplen = 0;
  for (final c in casosGuia) {
    final m = _correr(c.parametros, _semillasGuia);
    final difSoh = m.sohFinal - c.soh;
    final difCompra = c.comprada == null ? null : m.comprada / c.comprada! - 1;
    final enRango =
        c.limpiezas == null ||
        (m.limpiezas >= c.limpiezas!.$1 && m.limpiezas <= c.limpiezas!.$2);
    final tolerancia = c.comprada == null
        ? 0.0
        : _toleranciaEnergia(c.comprada!, m.desvComprada, _semillasGuia, 5);
    final cumple =
        difSoh.abs() <= 0.3 &&
        (difCompra == null || difCompra.abs() <= tolerancia) &&
        enRango;
    if (cumple) cumplen++;
    l.add(
      '| ${c.nombre} | ${_n(m.sohFinal)} | ${_n(c.soh)} | ${_s(difSoh)} | '
      '${_n(m.comprada, 0)} ± ${_n(m.desvComprada, 0)} | '
      '${c.comprada == null ? '—' : _n(c.comprada!, 0)}'
      ' | ${difCompra == null ? '—' : '${_p(difCompra)} (±${_n(tolerancia * 100, 1)} %)'} | '
      '${_n(m.limpiezas, 0)} | '
      '${c.limpiezas == null ? '—' : '${c.limpiezas!.$1}–${c.limpiezas!.$2}'} | '
      '${cumple ? 'sí' : 'no'} |',
    );
  }
  l
    ..add('')
    ..add('Casos que cumplen: **$cumplen de ${casosGuia.length}**.')
    ..add('')
    ..add('Tiempo total de la validación: ${reloj.elapsed.inSeconds} s.')
    ..add('');

  File('docs/VALIDACION_DART.md').writeAsStringSync(l.join('\n'));
  stdout.writeln(l.join('\n'));
}

const _semillasGuia = 20;

/// Tolerancia relativa para la energía comprada: el mayor entre 3 % y dos
/// errores estándar de la diferencia de medias (Dart con `nDart` semillas,
/// NetLogo con `nNetlogo` corridas, misma dispersión).
double _toleranciaEnergia(
  double referencia,
  double desviacion,
  int nDart,
  int nNetlogo,
) => math.max(
  0.03,
  2 * desviacion * math.sqrt(1 / nDart + 1 / nNetlogo) / referencia,
);

class _Promedio {
  _Promedio(List<ResultadoSimulacion> rs)
    : sohFinal = _media(rs.map((r) => r.sohFinal)),
      desvComprada = _desviacion(rs.map((r) => r.energiaCompradaKwh)),
      comprada = _media(rs.map((r) => r.energiaCompradaKwh)),
      ciclos = _media(rs.map((r) => r.ciclosEquivalentes)),
      limpiezas = _media(rs.map((r) => r.limpiezas.toDouble())),
      sohAnual = [
        for (var k = 0; k < rs.first.sohAnual.length; k++)
          _media(
            rs.where((r) => r.sohAnual.length > k).map((r) => r.sohAnual[k]),
          ),
      ];

  final double sohFinal;
  final double comprada;
  final double desvComprada;
  final double ciclos;
  final double limpiezas;
  final List<double> sohAnual;
}

_Promedio _correr(ParametrosSimulacion p, int semillas) => _Promedio([
  for (var s = 1; s <= semillas; s++)
    simular(p, semilla: s, registrarDias: false),
]);

double _media(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;

/// Desviación estándar muestral.
double _desviacion(Iterable<double> v) {
  final m = _media(v);
  final suma = v.fold<double>(0, (s, x) => s + (x - m) * (x - m));
  return math.sqrt(suma / (v.length - 1));
}

/// R² y RMSE (fracción) frente a la proyección lineal de 1,5 %/año.
({double r2, double rmse}) _ajuste(List<double> soh) {
  final real = [for (var k = 0; k < soh.length; k++) (100 - 1.5 * k) / 100];
  final pred = [for (final s in soh) s / 100];
  final m = _media(real);
  var ssRes = 0.0, ssTot = 0.0;
  for (var i = 0; i < real.length; i++) {
    ssRes += math.pow(real[i] - pred[i], 2);
    ssTot += math.pow(real[i] - m, 2);
  }
  return (r2: 1 - ssRes / ssTot, rmse: math.sqrt(ssRes / real.length));
}

String _n(double v, [int d = 2]) => v.toStringAsFixed(d).replaceAll('.', ',');
String _s(double v, [int d = 2]) => '${v >= 0 ? '+' : '−'}${_n(v.abs(), d)}';
String _p(double f) => '${_s(f * 100, 1)} %';
String _fecha(DateTime f) =>
    '${f.year}-${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')}';
