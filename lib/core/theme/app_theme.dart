import 'package:flutter/material.dart';

import 'transicion_suave.dart';

/// Colores con significado de Solarix (Etapa 9). Se leen con
/// `ColoresSolarix.of(context)` y cambian con el modo claro/oscuro.
@immutable
class ColoresSolarix extends ThemeExtension<ColoresSolarix> {
  const ColoresSolarix({
    required this.solar,
    required this.textoSobreSolar,
    required this.generacion,
    required this.consumo,
    required this.consciente,
    required this.convencional,
    required this.finDeVida,
  });

  /// Ámbar vivo: botones principales e ícono del sol.
  final Color solar;

  /// Texto sobre [solar] (carbón).
  final Color textoSobreSolar;

  /// Líneas de las gráficas.
  final Color generacion;
  final Color consumo;
  final Color consciente;
  final Color convencional;
  final Color finDeVida;

  static const claro = ColoresSolarix(
    solar: Color(0xFFF59E0B),
    textoSobreSolar: Color(0xFF1C1917),
    // Sobre tarjetas blancas el #F59E0B queda en 2,1:1; #D97706 se
    // distingue mejor (3,8:1) y sigue siendo ámbar.
    generacion: Color(0xFFD97706),
    consumo: Color(0xFF0284C7),
    consciente: Color(0xFF059669),
    convencional: Color(0xFFD97706),
    finDeVida: Color(0xFFDC2626),
  );

  static const oscuro = ColoresSolarix(
    solar: Color(0xFFFBBF24),
    textoSobreSolar: Color(0xFF1C1917),
    generacion: Color(0xFFFBBF24),
    consumo: Color(0xFF38BDF8),
    consciente: Color(0xFF34D399),
    convencional: Color(0xFFFBBF24),
    finDeVida: Color(0xFFF87171),
  );

  static ColoresSolarix of(BuildContext context) =>
      Theme.of(context).extension<ColoresSolarix>() ??
      (Theme.of(context).brightness == Brightness.dark ? oscuro : claro);

  @override
  ColoresSolarix copyWith({
    Color? solar,
    Color? textoSobreSolar,
    Color? generacion,
    Color? consumo,
    Color? consciente,
    Color? convencional,
    Color? finDeVida,
  }) => ColoresSolarix(
    solar: solar ?? this.solar,
    textoSobreSolar: textoSobreSolar ?? this.textoSobreSolar,
    generacion: generacion ?? this.generacion,
    consumo: consumo ?? this.consumo,
    consciente: consciente ?? this.consciente,
    convencional: convencional ?? this.convencional,
    finDeVida: finDeVida ?? this.finDeVida,
  );

  @override
  ColoresSolarix lerp(ColoresSolarix? other, double t) {
    if (other == null) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresSolarix(
      solar: m(solar, other.solar),
      textoSobreSolar: m(textoSobreSolar, other.textoSobreSolar),
      generacion: m(generacion, other.generacion),
      consumo: m(consumo, other.consumo),
      consciente: m(consciente, other.consciente),
      convencional: m(convencional, other.convencional),
      finDeVida: m(finDeVida, other.finDeVida),
    );
  }
}

/// Paleta solar de Solarix (Etapa 9): ámbar para la energía solar, verde
/// para lo sustentable (política consciente), azul para el consumo, fondo
/// crema y texto carbón. Los colores se fijan a mano: con solo la semilla,
/// Material 3 oscurecía el ámbar hasta un ocre (#784E11).
abstract final class AppTheme {
  /// Ámbar solar, color semilla del esquema.
  static const semilla = Color(0xFFF59E0B);

  static const carbon = Color(0xFF1C1917);

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get oscuro => _construir(Brightness.dark);

  static final _redondeo = BorderRadius.circular(12);

  /// Esquema de colores; público para las pruebas de contraste.
  static ColorScheme esquema(Brightness brillo) {
    final base = ColorScheme.fromSeed(seedColor: semilla, brightness: brillo);
    if (brillo == Brightness.light) {
      return base.copyWith(
        // Primario como texto (enlaces, pestañas, etiquetas): ámbar oscuro
        // legible sobre el crema (4,8:1). Los botones usan el ámbar vivo.
        primary: const Color(0xFFB45309),
        onPrimary: Colors.white,
        secondary: const Color(0xFF047857),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFD1FAE5),
        onSecondaryContainer: const Color(0xFF064E3B),
        tertiary: const Color(0xFF0369A1),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFE0F2FE),
        onTertiaryContainer: const Color(0xFF0C4A6E),
        error: const Color(0xFFDC2626),
        onError: Colors.white,
        surface: const Color(0xFFFFFBEB),
        onSurface: carbon,
        onSurfaceVariant: const Color(0xFF57534E),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white,
        outlineVariant: const Color(0xFFE7E0D2),
      );
    }
    return base.copyWith(
      primary: const Color(0xFFFBBF24),
      onPrimary: carbon,
      secondary: const Color(0xFF34D399),
      onSecondary: const Color(0xFF064E3B),
      secondaryContainer: const Color(0xFF065F46),
      onSecondaryContainer: const Color(0xFFD1FAE5),
      tertiary: const Color(0xFF38BDF8),
      onTertiary: const Color(0xFF082F49),
      tertiaryContainer: const Color(0xFF075985),
      onTertiaryContainer: const Color(0xFFE0F2FE),
      error: const Color(0xFFF87171),
      onError: carbon,
      surface: carbon,
      onSurface: const Color(0xFFFAF5EF),
      onSurfaceVariant: const Color(0xFFD6D3D1),
      surfaceContainerLowest: const Color(0xFF151210),
      surfaceContainerLow: const Color(0xFF292524),
      outlineVariant: const Color(0xFF44403C),
    );
  }

  static ThemeData _construir(Brightness brillo) {
    final esquema = AppTheme.esquema(brillo);
    final claro = brillo == Brightness.light;
    final colores = claro ? ColoresSolarix.claro : ColoresSolarix.oscuro;
    const tamanoBoton = Size(64, 48);
    final formaBoton = RoundedRectangleBorder(borderRadius: _redondeo);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      extensions: [colores],
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
      // Botón principal: ámbar vivo con texto carbón (≈ 8:1).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colores.solar,
          foregroundColor: colores.textoSobreSolar,
          minimumSize: tamanoBoton,
          shape: formaBoton,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // Botón secundario: texto carbón (claro en modo oscuro), borde ámbar de
      // 1,5 px y fondo ámbar al 8 %.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: esquema.onSurface,
          backgroundColor: colores.solar.withValues(alpha: 0.08),
          side: BorderSide(color: colores.solar, width: 1.5),
          minimumSize: tamanoBoton,
          shape: formaBoton,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        // Sombra suave en claro; en oscuro casi no se ve y separa el borde.
        elevation: claro ? 2 : 0,
        shadowColor: Colors.black.withValues(alpha: claro ? 0.25 : 0),
        surfaceTintColor: Colors.transparent,
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
