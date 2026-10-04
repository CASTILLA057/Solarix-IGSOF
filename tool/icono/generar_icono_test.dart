import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Genera el ícono y el splash de Solarix (Etapa 11) en `assets/icono/`:
///
///     flutter test tool/icono/generar_icono_test.dart
///
/// Después: `dart run flutter_launcher_icons` y
/// `dart run flutter_native_splash:create`.
///
/// El sol usa la paleta de la Etapa 9: ámbar #F59E0B (núcleo y rayos) con
/// un centro más claro #FBBF24, sobre crema #FFFBEB.

const _ambar = Color(0xFFF59E0B);
const _ambarClaro = Color(0xFFFBBF24);
const _ambarOscuro = Color(0xFFD97706);
const _crema = Color(0xFFFFFBEB);

/// Dibuja el sol centrado en [centro], con radio exterior (punta de los
/// rayos) [radio].
void pintarSol(Canvas canvas, Offset centro, double radio) {
  final nucleo = radio * 0.50;
  // 12 rayos redondeados del mismo largo.
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

Future<void> _guardar(
  String ruta,
  int lado,
  void Function(Canvas canvas, Size tamano) pintar,
) async {
  final grabadora = ui.PictureRecorder();
  pintar(Canvas(grabadora), Size.square(lado.toDouble()));
  final imagen = await grabadora.endRecording().toImage(lado, lado);
  final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
  File(ruta)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('genera el ícono y el splash', (tester) async {
    await tester.runAsync(() async {
      // Ícono completo (Android antiguo, web): sol sobre crema.
      await _guardar('assets/icono/icono.png', 1024, (c, t) {
        c.drawRect(Offset.zero & t, Paint()..color = _crema);
        pintarSol(c, t.center(Offset.zero), t.width * 0.40);
      });
      // Ícono adaptable (Android 8+): solo el sol, dentro de la zona segura
      // (el 66 % central, que ningún recorte de launcher tapa).
      await _guardar('assets/icono/icono_frente.png', 1024, (c, t) {
        pintarSol(c, t.center(Offset.zero), t.width * 0.30);
      });
      // Splash (incluido Android 12+, que recorta un círculo de 768 de
      // diámetro en una imagen de 1152).
      await _guardar('assets/icono/sol.png', 1152, (c, t) {
        pintarSol(c, t.center(Offset.zero), t.width * 0.30);
      });
    });
    for (final f in ['icono.png', 'icono_frente.png', 'sol.png']) {
      expect(File('assets/icono/$f').existsSync(), isTrue, reason: f);
    }
  });
}
