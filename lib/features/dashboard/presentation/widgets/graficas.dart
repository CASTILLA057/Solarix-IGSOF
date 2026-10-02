import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/formato.dart';

/// Eje X en meses con marcas cada año.
FlTitlesData _titulos(BuildContext context, {required String unidadY}) {
  final estilo = Theme.of(context).textTheme.bodySmall;
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      axisNameWidget: Text('Años', style: estilo),
      sideTitles: SideTitles(
        showTitles: true,
        interval: 12,
        reservedSize: 24,
        getTitlesWidget: (valor, meta) => SideTitleWidget(
          meta: meta,
          child: Text('${valor ~/ 12}', style: estilo),
        ),
      ),
    ),
    leftTitles: AxisTitles(
      axisNameWidget: Text(unidadY, style: estilo),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (valor, meta) => SideTitleWidget(
          meta: meta,
          child: Text(Formato.numero(valor), style: estilo),
        ),
      ),
    ),
  );
}

LineChartBarData _linea(List<FlSpot> puntos, Color color, {List<int>? trazo}) =>
    LineChartBarData(
      spots: puntos,
      color: color,
      barWidth: 2.5,
      dashArray: trazo,
      dotData: const FlDotData(show: false),
    );

Widget _leyenda(BuildContext context, List<(Color, String)> elementos) => Wrap(
  spacing: 16,
  runSpacing: 4,
  children: [
    for (final (color, texto) in elementos)
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 4, color: color),
          const SizedBox(width: 6),
          Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
  ],
);

/// SoH a lo largo del tiempo con la banda de referencia 80–100 % y la línea
/// de fin de vida (80 %). `sohMensual[i]` es el SoH al final del mes i;
/// `alternativaAnual[k]` es el SoH de la otra política al final del año k.
class GraficaSoh extends StatelessWidget {
  const GraficaSoh({
    super.key,
    required this.sohMensual,
    required this.etiqueta,
    this.alternativaAnual,
    this.etiquetaAlternativa,
  });

  final List<double> sohMensual;
  final String etiqueta;
  final List<double>? alternativaAnual;
  final String? etiquetaAlternativa;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final principal = [
      const FlSpot(0, 100),
      for (final (i, s) in sohMensual.indexed) FlSpot(i + 1.0, s),
    ];
    final alternativa = [
      for (final (k, s) in (alternativaAnual ?? const <double>[]).indexed)
        FlSpot(k * 12.0, s),
    ];
    final minimo = [
      ...principal.map((p) => p.y),
      ...alternativa.map((p) => p.y),
    ].reduce(math.min);
    final maxX = math.max(
      principal.last.x,
      alternativa.isEmpty ? 0.0 : alternativa.last.x,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(12, maxX),
              minY: (math.min(78, minimo - 1)).floorToDouble(),
              maxY: 100.5,
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: 80,
                    y2: 100,
                    color: esquema.primaryContainer.withValues(alpha: 0.35),
                  ),
                ],
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 80,
                    color: esquema.error,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                ],
              ),
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _titulos(context, unidadY: 'SoH (%)'),
              lineBarsData: [
                if (alternativa.isNotEmpty)
                  _linea(alternativa, esquema.tertiary, trazo: [6, 4]),
                _linea(principal, esquema.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _leyenda(context, [
          (esquema.primary, etiqueta),
          if (alternativa.isNotEmpty)
            (esquema.tertiary, etiquetaAlternativa ?? 'Otra política'),
          (esquema.error, 'Fin de vida (80 %)'),
        ]),
      ],
    );
  }
}

/// Generación y consumo de cada mes (kWh).
class GraficaEnergiaMensual extends StatelessWidget {
  const GraficaEnergiaMensual({
    super.key,
    required this.generacion,
    required this.consumo,
  });

  final List<double> generacion;
  final List<double> consumo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    List<FlSpot> puntos(List<double> v) => [
      for (final (i, x) in v.indexed) FlSpot(i.toDouble(), x),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _titulos(context, unidadY: 'kWh/mes'),
              lineBarsData: [
                _linea(puntos(generacion), esquema.primary),
                _linea(puntos(consumo), esquema.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _leyenda(context, [
          (esquema.primary, 'Generación solar'),
          (esquema.secondary, 'Consumo de la casa'),
        ]),
      ],
    );
  }
}

/// Energía comprada a la red, acumulada mes a mes (kWh).
class GraficaCompradaAcumulada extends StatelessWidget {
  const GraficaCompradaAcumulada({super.key, required this.compradaMensual});

  final List<double> compradaMensual;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    var acumulado = 0.0;
    final puntos = [
      const FlSpot(0, 0),
      for (final (i, x) in compradaMensual.indexed)
        FlSpot(i + 1.0, acumulado += x),
    ];
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: _titulos(context, unidadY: 'kWh acumulados'),
          lineBarsData: [_linea(puntos, esquema.error)],
        ),
      ),
    );
  }
}
