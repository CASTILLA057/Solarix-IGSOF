// Barrido de configuraciones para responder "¿para qué simular la batería?"
// (Etapa 14, punto 1). Para cada caso corre las dos políticas y la
// referencia sin degradación, con el mismo clima, y escribe
// docs/BARRIDO_BATERIA.md con la caída del SoH, la diferencia entre
// políticas, la vida usada en el flujo de caja y el VPN.
//
// Uso:  dart run tool/barrido_bateria.dart
import 'dart:io';

import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/integracion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

/// Semillas de cada caso: se promedian para que el azar del clima de una sola
/// corrida no se confunda con el efecto de la política.
const _semillas = [1, 2, 3];

/// Casa de referencia: 300 kWh/mes (≈ 10 kWh/día).
const _consumoMes = 300.0;

class _Fila {
  _Fila(this.sistema, this.ciudad, this.zona, this.bateriaKwh);
  final String sistema;
  final String ciudad;
  final ZonaClimatica zona;
  final double bateriaKwh;
  double sohConv = 0, sohConsc = 0, vidaUsoConv = 0, vidaUsoConsc = 0;
  double vidaConv = 0, vidaConsc = 0, vpnConv = 0, vpnConsc = 0, vpnCalc = 0;
  int unaLimitaCalendario = 0;
}

void main() {
  // Una ciudad por zona climática (la primera de la lista que cae en ella).
  final porZona = <ZonaClimatica, Ciudad>{};
  for (final c in ciudadesBase) {
    final z = zonaParaClima(climaDeCiudad(c.nombre));
    porZona.putIfAbsent(z, () => c);
  }
  final zonas = [
    ZonaClimatica.muySoleada,
    ZonaClimatica.mixta,
    ZonaClimatica.muyNublada,
  ];

  final casos = <(String, TipoSistema, double?)>[
    ('Híbrido', TipoSistema.hibrido, null),
    ('Aislado 0,5 d', TipoSistema.offGrid, 0.5),
    ('Aislado 1 d', TipoSistema.offGrid, 1),
    ('Aislado 2 d', TipoSistema.offGrid, 2),
    ('Aislado 3 d', TipoSistema.offGrid, 3),
  ];

  final filas = <_Fila>[];
  for (final z in zonas) {
    final ciudad = porZona[z];
    if (ciudad == null) continue;
    for (final (nombre, tipo, dias) in casos) {
      final e = EntradasCalculo(
        tipo: tipo,
        modo: ModoConsumo.factura,
        consumoFacturaKwhMes: _consumoMes,
        hsp: ciudad.hsp,
        clima: climaDeCiudad(ciudad.nombre),
        supuestos: dias == null
            ? const Supuestos()
            : Supuestos(diasAutonomia: dias),
      );
      final r = calcular(e);
      final origen = OrigenCalculo(entradas: e, resultado: r);
      final fila = _Fila(nombre, ciudad.nombre, z, r.bateriaKwh);
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
        final n = _semillas.length;
        fila.sohConv += c.convencional.sohFinal / n;
        fila.sohConsc += c.consciente.sohFinal / n;
        fila.vidaUsoConv += (i.convencional.vidaUsoAnios ?? 99) / n;
        fila.vidaUsoConsc += (i.consciente.vidaUsoAnios ?? 99) / n;
        fila.vidaConv += i.convencional.vidaAnios! / n;
        fila.vidaConsc += i.consciente.vidaAnios! / n;
        fila.vpnConv += i.convencional.vpn / n;
        fila.vpnConsc += i.consciente.vpn / n;
        fila.vpnCalc += i.calculadora.vpn / n;
        if (i.convencional.limitaCalendario) fila.unaLimitaCalendario++;
      }
      filas.add(fila);
    }
  }

  String m(double v) => (v / 1e6).toStringAsFixed(2).replaceAll('.', ',');
  String d(double v, [int n = 1]) => v.toStringAsFixed(n).replaceAll('.', ',');

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
    '- **SoH**: salud de la batería a los 10 años (%), con cada política.',
    '- **Δ SoH**: consciente − convencional, en puntos.',
    '- **Vida usada**: años que dura la batería en el flujo de caja '
        '(la menor entre la vida por uso y la vida calendario de 15 años).',
    '- **VPN**: valor presente neto a 20 años, en millones de pesos. '
        '`Calc.` es el de la calculadora, sin simulación.',
    '',
    '| Zona (ciudad) | Sistema | Batería (kWh) | SoH conv. | SoH consc. | '
        'Δ SoH | Vida uso conv. | Vida uso consc. | Vida usada conv. | '
        'Vida usada consc. | VPN calc. | VPN conv. | VPN consc. | '
        'Δ VPN (consc − conv) |',
    '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|',
  ];
  for (final f in filas) {
    l.add(
      '| ${f.zona.name} (${f.ciudad}) | ${f.sistema} | ${d(f.bateriaKwh)} | '
      '${d(f.sohConv)} | ${d(f.sohConsc)} | ${d(f.sohConsc - f.sohConv)} | '
      '${d(f.vidaUsoConv)} | ${d(f.vidaUsoConsc)} | ${d(f.vidaConv)} | '
      '${d(f.vidaConsc)} | ${m(f.vpnCalc)} | ${m(f.vpnConv)} | '
      '${m(f.vpnConsc)} | ${m(f.vpnConsc - f.vpnConv)} |',
    );
  }
  final conclusion = File('tool/barrido_conclusion.md').readAsStringSync();
  final texto = [...l, conclusion].join('\n');
  File('docs/BARRIDO_BATERIA.md').writeAsStringSync(texto);
  stdout.writeln(texto);
}
