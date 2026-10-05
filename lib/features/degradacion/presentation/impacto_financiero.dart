import 'package:flutter/material.dart';

import '../../../core/formato.dart';
import '../domain/integracion.dart';
import '../domain/parametros.dart';
import 'etiquetas.dart';

/// Cómo cambia la inversión del cálculo con la batería simulada (Etapa 12):
/// la calculadora (vida típica, la batería rinde igual siempre) frente a
/// cada política (vida y energía que aporta la batería según la simulación).
class TablaImpacto extends StatelessWidget {
  const TablaImpacto({super.key, required this.impacto});

  final ImpactoFinanciero impacto;

  @override
  Widget build(BuildContext context) {
    final i = impacto;
    final estilo = Theme.of(context).textTheme;
    final h = i.horizonteAnios;
    String vida(double? anios) =>
        anios == null ? 'Sin desgaste' : '${Formato.numero(anios, 1)} años';
    String soloSimulada(CifrasFinancieras c, double? valor) =>
        identical(c, i.calculadora) ? '—' : vida(valor);
    String recupera(double? anios) =>
        anios == null ? 'No en $h años' : '${Formato.numero(anios, 1)} años';
    final columnas = [i.calculadora, i.convencional, i.consciente];
    final filas = <(String, String Function(CifrasFinancieras))>[
      ('Vida por uso (simulada)', (c) => soloSimulada(c, c.vidaUsoAnios)),
      ('Vida calendario', (c) => soloSimulada(c, c.vidaCalendarioAnios)),
      (
        'Vida que se usa',
        (c) => identical(c, i.calculadora)
            ? '${Formato.numero(c.vidaAnios ?? 0, 1)} años (típica)'
            : '${vida(c.vidaAnios)}${c.limitaCalendario ? ' *' : ''}',
      ),
      ('Ahorro en $h años', (c) => Formato.copCorto(c.ahorroTotal)),
      ('Costo total (neto)', (c) => Formato.copCorto(c.costoTotal)),
      ('Recupera la inversión', (c) => recupera(c.paybackAnios)),
      ('VPN', (c) => Formato.copCorto(c.vpn)),
    ];
    final mejor = i.consciente.vpn > i.convencional.vpn
        ? Politica.consciente
        : Politica.convencional;
    final otra = mejor == Politica.consciente
        ? Politica.convencional
        : Politica.consciente;
    final diferencia = (i.de(mejor).vpn - i.de(otra).vpn).abs();
    String encabezado(String texto, {bool elegida = false}) =>
        elegida ? '$texto\n(elegida)' : texto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'La calculadora supone que la batería dura ${i.vidaTipicaAnios} '
          'años y rinde igual todo ese tiempo. Con la simulación, se '
          'reemplaza al llegar al 80 % de salud y el ahorro baja a medida que '
          'guarda menos energía: lo que ya no guarda se vende a la red a '
          'menor precio (o, sin red, se pierde).',
          style: estilo.bodyMedium,
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {0: FlexColumnWidth(1.3)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                for (final (texto, elegida) in [
                  ('Calculadora', false),
                  (
                    Politica.convencional.etiqueta,
                    i.elegida == Politica.convencional,
                  ),
                  (
                    Politica.consciente.etiqueta,
                    i.elegida == Politica.consciente,
                  ),
                ])
                  EncabezadoTabla(
                    encabezado(texto, elegida: elegida),
                    estilo: estilo.labelMedium,
                  ),
              ],
            ),
            for (final (etiqueta, valor) in filas)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(etiqueta, style: estilo.bodySmall),
                  ),
                  for (final c in columnas)
                    Text(
                      valor(c),
                      textAlign: TextAlign.end,
                      style: estilo.bodySmall,
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_notaVidas(i), style: estilo.bodySmall),
        const SizedBox(height: 12),
        Text(
          diferencia < 1000
              ? 'Las dos políticas dan prácticamente el mismo resultado '
                    'económico.'
              : 'En plata conviene la política ${mejor.etiqueta.toLowerCase()}: '
                    'su VPN es ${Formato.cop(diferencia)} mayor que el de la '
                    '${otra.etiqueta.toLowerCase()}.',
          style: estilo.titleSmall,
        ),
      ],
    );
  }
}

/// Qué limita la vida de la batería en cada política, y qué es el costo
/// neto.
String _notaVidas(ImpactoFinanciero i) {
  final calendario = [
    for (final p in Politica.values)
      if (i.de(p).limitaCalendario) p.etiqueta.toLowerCase(),
  ];
  final limita = switch (calendario.length) {
    0 =>
      'En las dos políticas la batería llega al 80 % de salud antes de su '
          'vida calendario: limita el uso.',
    2 =>
      '* Limita la vida calendario: la batería envejece aunque se use '
          'poco, y el modelo de degradación solo cuenta el uso.',
    _ =>
      '* En la política ${calendario.single} limita la vida calendario: la '
          'batería envejece aunque se use poco, y el modelo de degradación '
          'solo cuenta el uso.',
  };
  return '$limita El costo total es inversión, mantenimiento y baterías, '
      'menos lo que vale la batería que sigue útil al final '
      '(${i.horizonteAnios} años).';
}

/// Encabezado de columna que, si no cabe, reduce la letra en vez de partir
/// la palabra ("Convencio / nal" en un celular angosto).
class EncabezadoTabla extends StatelessWidget {
  const EncabezadoTabla(this.texto, {super.key, this.estilo});

  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    // Separación mínima entre columnas vecinas.
    padding: const EdgeInsets.only(left: 6),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        texto,
        textAlign: TextAlign.end,
        softWrap: false,
        style: estilo,
      ),
    ),
  );
}
