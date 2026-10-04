import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/formato.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../degradacion/domain/parametros.dart';
import '../../../degradacion/presentation/etiquetas.dart';

/// fl_chart también rotula los extremos del eje (p. ej. 100,5 → "101" o el
/// último mes → un año repetido); solo se rotulan los múltiplos del
/// intervalo.
bool _esMarca(double valor, double intervalo) {
  final pasos = valor / intervalo;
  return (pasos - pasos.round()).abs() < 1e-6;
}

/// Ancho reservado para las etiquetas del eje Y según el valor más largo,
/// para que "24.052" no se parta en dos líneas.
double _anchoEjeY(double maximo) =>
    math.max(36, Formato.numero(maximo).length * 8.0 + 12);

/// Eje X en meses con marcas cada año.
FlTitlesData _titulos(
  BuildContext context, {
  required String unidadY,
  double anchoY = 44,
  double? intervaloY,
}) {
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
        getTitlesWidget: (valor, meta) => _esMarca(valor, 12)
            ? SideTitleWidget(
                meta: meta,
                child: Text('${valor ~/ 12}', style: estilo),
              )
            : const SizedBox.shrink(),
      ),
    ),
    leftTitles: AxisTitles(
      axisNameWidget: Text(unidadY, style: estilo),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: anchoY,
        interval: intervaloY,
        getTitlesWidget: (valor, meta) => _esMarca(valor, meta.appliedInterval)
            ? SideTitleWidget(
                meta: meta,
                child: Text(
                  Formato.numero(valor),
                  style: estilo,
                  maxLines: 1,
                  softWrap: false,
                ),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}

/// Valores al tocar o pasar el mouse: máximo 3 decimales (`Formato.corto`)
/// y la unidad, en texto legible con una marca del color de la línea.
LineTouchData _toque(BuildContext context, String unidad) {
  final esquema = Theme.of(context).colorScheme;
  return LineTouchData(
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => esquema.surfaceContainerHighest,
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: (puntos) => [
        for (final p in puntos)
          LineTooltipItem(
            '${Formato.corto(p.y)} $unidad',
            TextStyle(color: esquema.onSurface, fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                text: ' ●',
                style: TextStyle(color: p.bar.color ?? esquema.onSurface),
              ),
            ],
          ),
      ],
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
/// La otra política también se dibuja mes a mes, para que al tocar la
/// gráfica muestre su valor en cualquier punto: con [alternativaMensual]
/// (resultados recién simulados) o interpolando entre años (historial, que
/// solo guarda el SoH anual de la otra política).
/// Cada política tiene su color fijo: consciente verde, convencional ámbar.
class GraficaSoh extends StatelessWidget {
  const GraficaSoh({
    super.key,
    required this.sohMensual,
    required this.politica,
    this.alternativaAnual,
    this.alternativaMensual,
    this.politicaAlternativa,
  });

  final List<double> sohMensual;
  final Politica politica;
  final List<double>? alternativaAnual;
  final List<double>? alternativaMensual;
  final Politica? politicaAlternativa;

  List<FlSpot> _alternativaPorMes() {
    final mensual = alternativaMensual;
    if (mensual != null && mensual.isNotEmpty) {
      return [
        const FlSpot(0, 100),
        for (final (i, s) in mensual.indexed) FlSpot(i + 1.0, s),
      ];
    }
    final anual = alternativaAnual ?? const <double>[];
    if (anual.isEmpty) return const [];
    return [
      FlSpot(0, anual.first),
      for (var k = 1; k < anual.length; k++)
        for (var m = 1; m <= 12; m++)
          FlSpot(
            (k - 1) * 12.0 + m,
            anual[k - 1] + (anual[k] - anual[k - 1]) * m / 12,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colores = ColoresSolarix.of(context);
    Color colorDe(Politica p) => switch (p) {
      Politica.consciente => colores.consciente,
      Politica.convencional => colores.convencional,
    };
    final otra =
        politicaAlternativa ?? Politica.values.firstWhere((p) => p != politica);
    final principal = [
      const FlSpot(0, 100),
      for (final (i, s) in sohMensual.indexed) FlSpot(i + 1.0, s),
    ];
    final alternativa = _alternativaPorMes();
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
                    color: colores.finDeVida,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                ],
              ),
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineTouchData: _toque(context, '%'),
              titlesData: _titulos(
                context,
                unidadY: 'SoH (%)',
                intervaloY: 100 - minimo > 30 ? 10 : 5,
              ),
              lineBarsData: [
                if (alternativa.isNotEmpty)
                  _linea(alternativa, colorDe(otra), trazo: [6, 4]),
                _linea(principal, colorDe(politica)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _leyenda(context, [
          (colorDe(politica), politica.etiqueta),
          if (alternativa.isNotEmpty) (colorDe(otra), otra.etiqueta),
          (colores.finDeVida, 'Fin de vida (80 %)'),
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
    final colores = ColoresSolarix.of(context);
    // Ámbar (sol) frente a azul (casa), fáciles de distinguir.
    final colorGeneracion = colores.generacion;
    final colorConsumo = colores.consumo;
    final maximo = [...generacion, ...consumo].fold<double>(0, math.max);
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
              lineTouchData: _toque(context, 'kWh'),
              titlesData: _titulos(
                context,
                unidadY: 'kWh/mes',
                anchoY: _anchoEjeY(maximo),
              ),
              lineBarsData: [
                _linea(puntos(generacion), colorGeneracion),
                _linea(puntos(consumo), colorConsumo),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _leyenda(context, [
          (colorGeneracion, 'Generación solar'),
          (colorConsumo, 'Consumo de la casa'),
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
          lineTouchData: _toque(context, 'kWh'),
          titlesData: _titulos(
            context,
            unidadY: 'kWh acumulados',
            anchoY: _anchoEjeY(acumulado),
          ),
          lineBarsData: [_linea(puntos, esquema.error)],
        ),
      ),
    );
  }
}
