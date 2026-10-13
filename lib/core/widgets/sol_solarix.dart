import 'dart:math' as math;

import 'package:flutter/material.dart';

const _ambar = Color(0xFFF59E0B);
const _ambarClaro = Color(0xFFFBBF24);
const _ambarOscuro = Color(0xFFD97706);

/// Dibuja el sol de Solarix centrado en [centro], con radio exterior (punta
/// de los rayos) [radio]: núcleo con degradado y 12 rayos redondeados. Es el
/// mismo dibujo del ícono de la app y del splash (Etapa 11), que se generan
/// con `tool/icono/generar_icono_test.dart`.
void pintarSol(Canvas canvas, Offset centro, double radio) {
  final nucleo = radio * 0.50;
  final rayo = Paint()
    ..color = _ambar
    ..strokeCap = StrokeCap.round
    ..strokeWidth = radio * 0.13;
  for (var i = 0; i < 12; i++) {
    final angulo = i * math.pi / 6 - math.pi / 2;
    final dir = Offset(math.cos(angulo), math.sin(angulo));
    canvas.drawLine(
      centro + dir * (nucleo + radio * 0.17),
      centro + dir * (radio - rayo.strokeWidth / 2),
      rayo,
    );
  }
  // Núcleo con un degradado suave (más claro arriba a la izquierda).
  canvas.drawCircle(
    centro,
    nucleo,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 1.1,
        colors: [_ambarClaro, _ambar, _ambarOscuro],
        stops: [0, 0.65, 1],
      ).createShader(Rect.fromCircle(center: centro, radius: nucleo)),
  );
}

/// El sol de Solarix (Etapa 13, mockup) en un cuadrado de [tamano]: la
/// imagen de los assets (`assets/icono/sol.png`), la misma del splash. El
/// sol ocupa el 60 % central del PNG (radio de 0,30 del ancho, ver
/// `tool/icono/generar_icono_test.dart`); se dibuja más grande y centrado
/// para que los rayos lleguen al borde de [tamano], como un ícono de
/// Material. El margen transparente sobra fuera del cuadrado y no tapa nada.
class SolSolarix extends StatelessWidget {
  const SolSolarix({super.key, this.tamano = 40});

  final double tamano;

  /// Parte del ancho del PNG que ocupa el sol con sus rayos.
  static const _proporcionSol = 0.6;

  @override
  Widget build(BuildContext context) {
    final lienzo = tamano / _proporcionSol;
    return SizedBox.square(
      dimension: tamano,
      child: OverflowBox(
        maxWidth: lienzo,
        maxHeight: lienzo,
        child: Image.asset(
          'assets/icono/sol.png',
          width: lienzo,
          height: lienzo,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Solarix',
        ),
      ),
    );
  }
}
