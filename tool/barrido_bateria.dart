// Barrido de configuraciones para responder "¿para qué simular la batería?"
// (Etapa 14, puntos 1 y 6). Para cada caso corre las dos políticas y la
// referencia sin degradación, con el mismo clima, y escribe
// docs/BARRIDO_BATERIA.md con dos tablas: la degradación (no depende del
// dinero) y el VPN (con el gasto actual de cada aislado).
//
// Uso:  dart run tool/barrido_bateria.dart
import 'dart:io';

import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/integracion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';
import 'package:solarix/features/degradacion/presentation/etiquetas.dart';

/// Semillas de cada caso: se promedian para que el azar del clima de una sola
/// corrida no se confunda con el efecto de la política.
const _semillas = [1, 2, 3];

/// Casa de referencia: 300 kWh/mes (≈ 10 kWh/día).
const _consumoMes = 300.0;

/// Gasto actual en energía de una casa aislada (COP/mes): lo que deja de
/// gastar en la planta diésel. 300 kWh/mes con una planta pequeña a carga
/// parcial (0,35–0,5 L/kWh) y ACPM a ≈ $ 11.320 por galón (octubre de 2026)
/// cuestan ≈ $ 315.000–450.000 solo en combustible (`docs/FUENTES.md`).
const _gastosAislado = [300000.0, 450000.0];

/// Promedio de las semillas; `null` si en alguna la batería casi no se
/// degrada y no hay vida por uso (no se rellena con un número inventado).
class _Promedio {
  final _valores = <double?>[];
  void sumar(double? v) => _valores.add(v);
  double? get valor => _valores.any((v) => v == null)
      ? null
      : _valores.fold<double>(0, (s, v) => s + v!) / _valores.length;
}

class _Caso {
  _Caso(this.sistema, this.zona, this.ciudad, this.bateriaKwh);
  final String sistema;
  final ZonaClimatica zona;
  final String ciudad;
  final double bateriaKwh;
  final sohConv = _Promedio(), sohConsc = _Promedio();
  final vidaUsoConv = _Promedio(), vidaUsoConsc = _Promedio();
  final vidaConv = _Promedio(), vidaConsc = _Promedio();
}

class _Dinero {
  _Dinero(this.caso, this.gasto);
  final _Caso caso;

  /// `null` en el híbrido: su ahorro sale de la factura, no de un gasto.
  final double? gasto;
  final vpnCalc = _Promedio(), vpnConv = _Promedio(), vpnConsc = _Promedio();
}

void main() {
  // Una ciudad por zona climática (la primera de la lista que cae en ella).
  final porZona = <ZonaClimatica, Ciudad>{};
  for (final c in ciudadesBase) {
    final z = zonaParaClima(climaDeCiudad(c.nombre));
    porZona.putIfAbsent(z, () => c);
  }
  const zonas = [
    ZonaClimatica.muySoleada,
    ZonaClimatica.mixta,
    ZonaClimatica.muyNublada,
  ];

  // El aislado de medio día se quitó: tiene la misma batería que el híbrido
  // y la simulación no distingue el tipo de sistema (el modelo siempre tiene
  // red), así que repetía la misma corrida.
  const configuraciones = <(String, TipoSistema, double?)>[
    ('Híbrido', TipoSistema.hibrido, null),
    ('Aislado, 1 día', TipoSistema.offGrid, 1),
    ('Aislado, 2 días', TipoSistema.offGrid, 2),
    ('Aislado, 3 días', TipoSistema.offGrid, 3),
  ];

  final casos = <_Caso>[];
  final dinero = <_Dinero>[];
  for (final z in zonas) {
    final ciudad = porZona[z];
    if (ciudad == null) continue;
    for (final (nombre, tipo, dias) in configuraciones) {
      final gastos = tipo == TipoSistema.offGrid
          ? _gastosAislado
          : const <double?>[null];
      _Caso? caso;
      for (final gasto in gastos) {
        final e = EntradasCalculo(
          tipo: tipo,
          modo: ModoConsumo.factura,
          consumoFacturaKwhMes: _consumoMes,
          gastoActualMensual: gasto ?? 0,
          hsp: ciudad.hsp,
          clima: climaDeCiudad(ciudad.nombre),
          supuestos: dias == null
              ? const Supuestos()
              : Supuestos(diasAutonomia: dias),
        );
        final r = calcular(e);
        final origen = OrigenCalculo(entradas: e, resultado: r);
        // La degradación no depende del gasto: se registra una sola vez.
        final registrarDegradacion = caso == null;
        caso ??= _Caso(nombre, z, ciudad.nombre, r.bateriaKwh);
        final d = _Dinero(caso, gasto);
        for (final s in _semillas) {
          final c = simularComparacion((
            parametros: parametrosDesdeCalculo(origen).copiarCon(anios: 10),
            semilla: s,
          ));
          final i = calcularImpacto(
            origen: origen,
            convencional: c.convencional,
            consciente: c.consciente,
            referencia: c.referencia,
            elegida: Politica.convencional,
          );
          if (registrarDegradacion) {
            caso.sohConv.sumar(c.convencional.sohFinal);
            caso.sohConsc.sumar(c.consciente.sohFinal);
            caso.vidaUsoConv.sumar(i.convencional.vidaUsoAnios);
            caso.vidaUsoConsc.sumar(i.consciente.vidaUsoAnios);
            caso.vidaConv.sumar(i.convencional.vidaAnios);
            caso.vidaConsc.sumar(i.consciente.vidaAnios);
          }
          d.vpnCalc.sumar(i.calculadora.vpn);
          d.vpnConv.sumar(i.convencional.vpn);
          d.vpnConsc.sumar(i.consciente.vpn);
        }
        if (registrarDegradacion) casos.add(caso);
        dinero.add(d);
      }
    }
  }

  String n(double? v, [int dec = 1]) {
    if (v == null) return 'no llega';
    final s = v.toStringAsFixed(dec);
    // Un valor que redondea a cero no lleva signo ("-0,00").
    final cero = double.parse(s) == 0;
    return (cero ? s.replaceFirst('-', '') : s).replaceAll('.', ',');
  }

  String m(double? v) => v == null ? '—' : n(v / 1e6, 2);
  String dif(double? a, double? b) => a == null || b == null ? '—' : m(a - b);
  String lugar(_Caso c) => '${c.zona.etiqueta} (${c.ciudad})';
  String miles(double v) => '\$ ${(v / 1000).toStringAsFixed(0)}.000';

  final vidaTipica = QuimicaBateria.litio.vidaUtilAnios;
  final vidaCalendario = QuimicaBateria.litio.vidaCalendarioAnios;
  final l = <String>[
    '# Solarix — ¿Para qué simular la batería? Barrido de configuraciones '
        '(Etapa 14)',
    '',
    'Generado por `dart run tool/barrido_bateria.dart` el '
        '${DateTime.now().toIso8601String().substring(0, 10)}. Casa de '
        '${_consumoMes.toStringAsFixed(0)} kWh/mes, litio, 10 años '
        'simulados, promedio de las semillas ${_semillas.join(', ')}. '
        'Una ciudad por zona climática.',
    '',
    '## 1. Degradación',
    '',
    '- **SoH**: salud de la batería a los 10 años (%), con cada política.',
    '- **Δ SoH**: consciente − convencional, en puntos.',
    '- **Vida por uso**: años hasta el 80 % según la simulación ("no llega" '
        'si casi no se degrada).',
    '- **Vida usada**: la que entra al flujo de caja, la menor entre la vida '
        'por uso y la vida calendario ($vidaCalendario años).',
    '',
    '| Zona (ciudad) | Sistema | Batería (kWh) | SoH conv. | SoH consc. | '
        'Δ SoH | Vida por uso conv. | Vida por uso consc. | '
        'Vida usada conv. | Vida usada consc. |',
    '|---|---|---|---|---|---|---|---|---|---|',
    for (final c in casos)
      '| ${lugar(c)} | ${c.sistema} | ${n(c.bateriaKwh)} | '
          '${n(c.sohConv.valor)} | ${n(c.sohConsc.valor)} | '
          '${c.sohConv.valor == null || c.sohConsc.valor == null ? '—' : n(c.sohConsc.valor! - c.sohConv.valor!)} | '
          '${n(c.vidaUsoConv.valor)} | ${n(c.vidaUsoConsc.valor)} | '
          '${n(c.vidaConv.valor)} | ${n(c.vidaConsc.valor)} |',
    '',
    '## 2. Valor presente neto (VPN, 20 años, millones de pesos)',
    '',
    '- **Calculadora**: sin simulación, con la vida típica del litio '
        '($vidaTipica años, la que usa una cotización).',
    '- **Convencional / consciente**: con la vida usada y el aporte de la '
        'batería según la simulación.',
    '- **Simulación − calculadora**: cuánto cambia el VPN por simular '
        '(política convencional).',
    '- **Gasto actual**: lo que el aislado deja de gastar en la planta '
        'diésel. El híbrido ahorra en la factura (\$ 890/kWh, estrato 4).',
    '',
    '| Zona (ciudad) | Sistema | Gasto actual | Calculadora | Convencional '
        '| Consciente | Simulación − calculadora | Consciente − convencional |',
    '|---|---|---|---|---|---|---|---|',
    for (final d in dinero)
      '| ${lugar(d.caso)} | ${d.caso.sistema} | '
          '${d.gasto == null ? 'factura' : miles(d.gasto!)} | '
          '${m(d.vpnCalc.valor)} | ${m(d.vpnConv.valor)} | '
          '${m(d.vpnConsc.valor)} | '
          '${dif(d.vpnConv.valor, d.vpnCalc.valor)} | '
          '${dif(d.vpnConsc.valor, d.vpnConv.valor)} |',
    '',
  ];
  final conclusion = File('tool/barrido_conclusion.md').readAsStringSync();
  final texto = [...l, conclusion].join('\n');
  File('docs/BARRIDO_BATERIA.md').writeAsStringSync(texto);
  stdout.writeln(texto);
}
