import 'package:flutter/material.dart';

/// Paleta solar de Solarix. Se ajusta en la Etapa 8 (pulido).
abstract final class AppTheme {
  /// Ámbar solar, color semilla del esquema.
  static const semilla = Color(0xFFF59E0B);

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get oscuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(
      seedColor: semilla,
      brightness: brillo,
    );
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    );
  }
}
