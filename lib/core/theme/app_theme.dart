import 'package:flutter/material.dart';

import 'transicion_suave.dart';

/// Paleta solar de Solarix: ámbar como color principal, azul cielo como
/// terciario (la otra política en las gráficas) y superficies cálidas.
/// Claro y oscuro salen del mismo esquema.
abstract final class AppTheme {
  /// Ámbar solar, color semilla del esquema.
  static const semilla = Color(0xFFF59E0B);

  /// Azul cielo, contraste del ámbar.
  static const cielo = Color(0xFF0EA5E9);

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get oscuro => _construir(Brightness.dark);

  static final _redondeo = BorderRadius.circular(12);

  static ThemeData _construir(Brightness brillo) {
    final base = ColorScheme.fromSeed(seedColor: semilla, brightness: brillo);
    final deCielo = ColorScheme.fromSeed(seedColor: cielo, brightness: brillo);
    final esquema = base.copyWith(
      tertiary: deCielo.primary,
      onTertiary: deCielo.onPrimary,
      tertiaryContainer: deCielo.primaryContainer,
      onTertiaryContainer: deCielo.onPrimaryContainer,
    );
    const tamanoBoton = Size(64, 48);
    final formaBoton = RoundedRectangleBorder(borderRadius: _redondeo);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      scaffoldBackgroundColor: esquema.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: _redondeo),
        filled: true,
        fillColor: esquema.surfaceContainerLowest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tamanoBoton,
          shape: formaBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tamanoBoton,
          shape: formaBoton,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: esquema.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: esquema.outlineVariant),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final plataforma in TargetPlatform.values)
            plataforma: const TransicionSuave(),
        },
      ),
    );
  }
}
