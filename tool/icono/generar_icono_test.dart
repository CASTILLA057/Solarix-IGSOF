import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/widgets/sol_solarix.dart';

/// Genera el ícono y el splash de Solarix (Etapa 11) en `assets/icono/`:
///
///     flutter test tool/icono/generar_icono_test.dart
///
/// Después: `dart run flutter_launcher_icons` y
/// `dart run flutter_native_splash:create`.
///
/// El sol (`pintarSol`, en `lib/core/widgets/sol_solarix.dart`) es el mismo
/// que dibuja la app (Etapa 13); usa la paleta de la Etapa 9 sobre crema
/// #FFFBEB.

const _crema = Color(0xFFFFFBEB);

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
