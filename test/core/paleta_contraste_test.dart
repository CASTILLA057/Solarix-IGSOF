import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/theme/app_theme.dart';

/// Relación de contraste WCAG entre dos colores (1 a 21).
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, oscuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  for (final (nombre, tema) in [
    ('claro', AppTheme.claro),
    ('oscuro', AppTheme.oscuro),
  ]) {
    final e = tema.colorScheme;
    final c = tema.extension<ColoresSolarix>()!;
    final tarjeta = e.surfaceContainerLow;

    test('modo $nombre: texto legible (≥ 4,5:1, WCAG AA)', () {
      final pares = <String, (Color, Color)>{
        'texto sobre el fondo': (e.onSurface, e.surface),
        'texto secundario sobre el fondo': (e.onSurfaceVariant, e.surface),
        'texto sobre las tarjetas': (e.onSurface, tarjeta),
        'enlaces y pestañas (primario)': (e.primary, e.surface),
        'texto sobre el primario': (e.onPrimary, e.primary),
        'botón principal (ámbar vivo)': (c.textoSobreSolar, c.solar),
        'botón secundario (fondo ámbar 8 %)': (
          e.onSurface,
          Color.alphaBlend(c.solar.withValues(alpha: 0.08), e.surface),
        ),
        'texto sobre el verde': (e.onSecondary, e.secondary),
        'texto sobre el contenedor verde': (
          e.onSecondaryContainer,
          e.secondaryContainer,
        ),
        'texto sobre el azul': (e.onTertiary, e.tertiary),
        'texto sobre el contenedor azul': (
          e.onTertiaryContainer,
          e.tertiaryContainer,
        ),
        'texto sobre el rojo': (e.onError, e.error),
        'mensajes de error sobre el fondo': (e.error, e.surface),
      };
      for (final MapEntry(key: que, value: (texto, fondo)) in pares.entries) {
        expect(
          contraste(texto, fondo),
          greaterThanOrEqualTo(4.5),
          reason: '$que: ${contraste(texto, fondo).toStringAsFixed(2)}:1',
        );
      }
    });

    test('modo $nombre: líneas de las gráficas visibles (≥ 3:1)', () {
      final lineas = {
        'generación': c.generacion,
        'consumo': c.consumo,
        'consciente': c.consciente,
        'convencional': c.convencional,
        'fin de vida': c.finDeVida,
      };
      for (final MapEntry(key: que, value: color) in lineas.entries) {
        expect(
          contraste(color, tarjeta),
          greaterThanOrEqualTo(3),
          reason: '$que: ${contraste(color, tarjeta).toStringAsFixed(2)}:1',
        );
      }
    });
  }

  test('las dos políticas y generación/consumo se distinguen entre sí', () {
    for (final c in [ColoresSolarix.claro, ColoresSolarix.oscuro]) {
      expect(c.consciente, isNot(c.convencional));
      expect(c.generacion, isNot(c.consumo));
    }
  });

  test('colores acordados en el plan', () {
    expect(ColoresSolarix.claro.solar, const Color(0xFFF59E0B));
    expect(ColoresSolarix.claro.textoSobreSolar, const Color(0xFF1C1917));
    expect(ColoresSolarix.claro.consciente, const Color(0xFF059669));
    expect(ColoresSolarix.claro.consumo, const Color(0xFF0284C7));
    expect(ColoresSolarix.claro.finDeVida, const Color(0xFFDC2626));
    expect(AppTheme.claro.colorScheme.surface, const Color(0xFFFFFBEB));
    expect(AppTheme.claro.colorScheme.onSurface, const Color(0xFF1C1917));
  });
}
