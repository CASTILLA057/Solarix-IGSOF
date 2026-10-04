import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/theme/app_theme.dart';
import 'package:solarix/features/dashboard/presentation/widgets/graficas.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

Future<void> _dibujar(WidgetTester tester, Widget grafica) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: grafica),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // 10 años: el SoH baja de 100 a 78,6 %.
  final meses = List.generate(120, (i) => 100 - (i + 1) * 0.178);

  testWidgets('SoH: sin "101" ni el mínimo suelto en el eje Y', (tester) async {
    await _dibujar(
      tester,
      GraficaSoh(sohMensual: meses, politica: Politica.convencional),
    );
    expect(find.text('101'), findsNothing);
    expect(find.text('78'), findsNothing);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('energía mensual: cada año aparece una sola vez en el eje X', (
    tester,
  ) async {
    await _dibujar(
      tester,
      GraficaEnergiaMensual(
        generacion: List.filled(120, 600),
        consumo: List.filled(120, 550),
      ),
    );
    // El 0 también es la etiqueta inferior del eje Y.
    for (var anio = 1; anio <= 9; anio++) {
      expect(find.text('$anio'), findsOneWidget, reason: 'año $anio');
    }
  });

  testWidgets('energía comprada: etiquetas del eje Y en una sola línea', (
    tester,
  ) async {
    await _dibujar(
      tester,
      GraficaCompradaAcumulada(compradaMensual: List.filled(120, 200.43)),
    );
    expect(find.text('24.052'), findsNothing); // extremo sin redondear
    final etiquetas = tester
        .widgetList<Text>(find.textContaining('.000'))
        .toList();
    expect(etiquetas, isNotEmpty);
    for (final t in etiquetas) {
      expect(t.maxLines, 1);
      final caja = tester.getSize(find.byWidget(t));
      expect(caja.height, lessThan(24), reason: '${t.data} se partió');
    }
  });

  testWidgets('al tocar la gráfica el valor tiene máximo 3 decimales', (
    tester,
  ) async {
    await _dibujar(
      tester,
      GraficaSoh(sohMensual: meses, politica: Politica.convencional),
    );
    final datos = tester.widget<LineChart>(find.byType(LineChart)).data;
    final linea = datos.lineBarsData.last;
    final textos = datos.lineTouchData.touchTooltipData
        .getTooltipItems([LineBarSpot(linea, 0, const FlSpot(5, 99.1234567))])
        .map((t) => t!.text);
    expect(textos, ['99,123 %']);
  });

  testWidgets('la otra política tiene un punto por mes para mostrar su valor', (
    tester,
  ) async {
    await _dibujar(
      tester,
      GraficaSoh(
        sohMensual: List.generate(24, (i) => 100 - (i + 1) * 0.2),
        politica: Politica.convencional,
        alternativaAnual: const [100, 98, 96],
        politicaAlternativa: Politica.consciente,
      ),
    );
    final datos = tester.widget<LineChart>(find.byType(LineChart)).data;
    final principal = datos.lineBarsData.last.spots;
    final otra = datos.lineBarsData.first.spots;
    expect([for (final p in otra) p.x], [for (final p in principal) p.x]);
    // Mitad del primer año: entre 100 y 98.
    expect(otra[6].y, closeTo(99, 1e-9));
    expect(otra.last.y, 96);
  });

  testWidgets('cada política tiene su color fijo, sea la elegida o no', (
    tester,
  ) async {
    const colores = ColoresSolarix.claro;
    for (final (elegida, otra) in [
      (Politica.consciente, Politica.convencional),
      (Politica.convencional, Politica.consciente),
    ]) {
      await _dibujar(
        tester,
        GraficaSoh(
          sohMensual: List.generate(24, (i) => 100 - (i + 1) * 0.2),
          politica: elegida,
          alternativaAnual: const [100, 98, 96],
          politicaAlternativa: otra,
        ),
      );
      Color colorDe(Politica p) =>
          p == Politica.consciente ? colores.consciente : colores.convencional;
      final barras = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData;
      expect(barras.last.color, colorDe(elegida));
      expect(barras.first.color, colorDe(otra));
    }
  });
}
