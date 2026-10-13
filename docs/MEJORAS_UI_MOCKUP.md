# Solarix — Mejoras de interfaz según el mockup de Figma

Guía para llevar a la app Flutter el diseño del mockup **"Solarix — Mockups UI/UX"**
(Ingeniería de Software, Clase 13). Es la **Etapa 13 — Rediseño de la interfaz según el mockup** de `ETAPAS_SOLARIX_APP.md`.

- Diseño (editable): https://www.figma.com/design/xymPVyc9aeLT5bENvZlAYK
- Prototipo celular: https://www.figma.com/proto/xymPVyc9aeLT5bENvZlAYK/Solarix?node-id=4-7&starting-point-node-id=4%3A7&scaling=scale-down-width
- Prototipo web: https://www.figma.com/proto/xymPVyc9aeLT5bENvZlAYK/Solarix?node-id=6-7&starting-point-node-id=6%3A7&scaling=scale-down-width

> El mockup **no cambia la lógica** (cálculos, Supabase, rutas, validaciones). Todo lo de
> esta guía es capa de presentación: tema, widgets reutilizables y el armado de cada pantalla.

---

## Índice

1. [Resumen de cambios](#1-resumen-de-cambios)
2. [Tokens: colores y tema](#2-tokens-colores-y-tema)
3. [Widgets reutilizables nuevos](#3-widgets-reutilizables-nuevos)
4. [Diseño adaptativo: celular vs. web](#4-diseño-adaptativo-celular-vs-web)
5. [Pantalla por pantalla](#5-pantalla-por-pantalla)
6. [Pruebas que hay que actualizar](#6-pruebas-que-hay-que-actualizar)
7. [Orden sugerido y checklist](#7-orden-sugerido-y-checklist)

---

## 1. Resumen de cambios

| Área | Hoy en la app | En el mockup |
|---|---|---|
| Colores | Paleta ámbar/crema/carbón (Etapa 9) | **Igual**, más 2 tokens: `solarSuave` y `bordeFuerte` |
| Sol | `Icons.wb_sunny_rounded` de Material | **El sol de `assets/icono/sol.png`** (disco con degradado y 12 rayos), igual que el ícono y el splash |
| Botón secundario | Fondo ámbar al 8 % | Fondo **ámbar suave** sólido (`#FEF3C7`) + borde ámbar 1,5 px |
| Encabezado de tarjetas | Ícono suelto + título | **Burbuja de color** (círculo 36–40 px) + título |
| Web (≥ 900 px) | La misma vista del celular centrada | **Barra de navegación superior** + contenido en columnas (máx. 1120 px) |
| Bienvenida web | Columna centrada | **Dos columnas**: presentación (fondo ámbar suave) + tarjeta de acceso |
| Inicio | Botones + 2 tarjetas | Saludo con nombre, **cifras en mosaicos**, gráfica con leyenda, **historial reciente** (web) |
| Calculadora | `Stepper` vertical de Material | **Indicador de pasos horizontal** (celular) / **tarjeta de pasos lateral** (web), título en forma de pregunta |
| Equipos | Lista simple | Tarjeta con divisores (celular) / **tabla** (web) + **banda verde** con el consumo total |
| Resultados | Columna de tarjetas | Destacado ámbar con borde, **grilla 2×2** en web, acciones arriba, nota azul Ley 1715 |
| Perfil | Formulario en columna | **Avatar con iniciales**, mosaicos de actividad, tarjetas "Datos personales" y "Apariencia", 2 columnas en web |
| Guardar | `SnackBar('Cálculo guardado.')` | Aviso con acción **VER** que lleva al historial |

---

## 2. Tokens: colores y tema

Archivo: `lib/core/theme/app_theme.dart`

### 2.1 Dos colores nuevos en `ColoresSolarix`

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `solarSuave` | `#FEF3C7` | `#422006` | Fondo de botón secundario, selección activa, burbujas ámbar, destacado de resultados |
| `bordeFuerte` | `#D6CFC2` | `#57534E` | Borde de campos de texto y del selector segmentado |

```dart
// En la clase ColoresSolarix: agregar los campos…
  /// Ámbar muy claro: selección activa, botón secundario, destacados.
  final Color solarSuave;

  /// Borde de campos y selectores (más marcado que outlineVariant).
  final Color bordeFuerte;

// …al constructor:
    required this.solarSuave,
    required this.bordeFuerte,

// …a las dos instancias:
  static const claro = ColoresSolarix(
    // (los que ya existen)
    solarSuave: Color(0xFFFEF3C7),
    bordeFuerte: Color(0xFFD6CFC2),
  );

  static const oscuro = ColoresSolarix(
    // (los que ya existen)
    solarSuave: Color(0xFF422006),
    bordeFuerte: Color(0xFF57534E),
  );
```

Y en `copyWith` y `lerp` (igual que los demás):

```dart
// copyWith
    Color? solarSuave,
    Color? bordeFuerte,
// …
    solarSuave: solarSuave ?? this.solarSuave,
    bordeFuerte: bordeFuerte ?? this.bordeFuerte,

// lerp
      solarSuave: m(solarSuave, other.solarSuave),
      bordeFuerte: m(bordeFuerte, other.bordeFuerte),
```

### 2.2 Ajustes en `_construir`

```dart
      // Botón secundario: fondo ámbar suave sólido (antes 8 % de alpha).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: esquema.onSurface,
          backgroundColor: colores.solarSuave,
          side: BorderSide(color: colores.solar, width: 1.5),
          minimumSize: tamanoBoton,
          shape: formaBoton,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Campos: borde más marcado y redondeo 12.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: _redondeo),
        enabledBorder: OutlineInputBorder(
          borderRadius: _redondeo,
          borderSide: BorderSide(color: colores.bordeFuerte),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _redondeo,
          borderSide: BorderSide(color: colores.solar, width: 2),
        ),
      ),

      // Selector segmentado: seleccionado en ámbar suave con check.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colores.solarSuave,
          selectedForegroundColor: esquema.onSurface,
          side: BorderSide(color: colores.bordeFuerte),
          minimumSize: const Size(0, 40),
        ),
      ),

      // Barra superior: título semibold 18 como en el mockup.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: esquema.onSurface,
        ),
      ),

      // Aviso flotante oscuro (carbón) con acción en ámbar.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: claro ? AppTheme.carbon : const Color(0xFFFAF5EF),
        actionTextColor: colores.solar,
        shape: RoundedRectangleBorder(borderRadius: _redondeo),
      ),
```

### 2.3 Tipografía

El mockup usa **Roboto**, la fuente por defecto de Material en Android y web, así que **no hay que
agregar fuentes**. La escala del mockup se corresponde con el `TextTheme` de Material 3:

| Estilo del mockup | Medidas | `TextTheme` |
|---|---|---|
| Display | Bold 36/44 | `headlineLarge` con `fontWeight: w700` (solo bienvenida web) |
| Título | SemiBold 24/32 | `headlineSmall` + `w600` |
| Título tarjeta | SemiBold 18/24 | `titleMedium` con `fontSize: 18, w600` |
| Subtítulo | Medium 16/24 | `titleMedium` |
| Cuerpo grande | Regular 16/24 | `bodyLarge` |
| Cuerpo | Regular 14/20 | `bodyMedium` |
| Etiqueta | Medium 12/16 | `labelMedium` |
| Botón | SemiBold 14/20 | ya está en el tema de los botones |

Opcional: fijarlos en el tema para no repetir `copyWith` en cada pantalla:

```dart
      textTheme: ThemeData(brightness: brillo).textTheme.copyWith(
        headlineSmall: const TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
      ),
```

> Con esto, `titleLarge` pasa a ser el "Título tarjeta" del mockup. Revisa con
> `test/core/paleta_contraste_test.dart` que el contraste siga pasando.

### 2.4 El sol de Solarix (el mismo de `assets/icono/sol.png`)

El mockup usa **el sol de tus assets**: disco relleno con degradado (`#FBBF24` → `#F39C0B`) y
**12 rayos** gruesos con puntas redondeadas. Hoy la app dibuja `Icons.wb_sunny_rounded` de
Material, que es otro sol. Para que la app, el ícono del launcher y el splash usen el mismo, se
reemplaza por la imagen.

**1) Declarar la imagen en `pubspec.yaml`** (hoy solo la usan `flutter_launcher_icons` y
`flutter_native_splash`, que no la meten en la app). Dentro de la sección `flutter:`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icono/sol.png
```

**2) Widget reutilizable** (en `lib/core/widgets/solarix_ui.dart`):

```dart
/// El sol de Solarix: el mismo dibujo del ícono de la app y del splash.
class SolSolarix extends StatelessWidget {
  const SolSolarix({super.key, this.tamano = 40});

  final double tamano;

  /// El PNG mide 1152 px y el sol (con rayos) ocupa solo el 60 % central;
  /// el resto es margen transparente pensado para el splash.
  static const _proporcionSol = 0.6;

  @override
  Widget build(BuildContext context) {
    final lienzo = tamano / _proporcionSol;
    return SizedBox.square(
      dimension: tamano,
      // Se dibuja la imagen más grande y se centra, para que los rayos
      // lleguen al borde de `tamano`, igual que un ícono de Material.
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
```

> Como el margen transparente se sale del `SizedBox`, no tapa nada: solo ocupa `tamano`
> en el layout.

**3) Reemplazar los 4 usos actuales** (los encontré con `grep -rn wb_sunny lib`):

| Archivo | Línea aprox. | Cambio |
|---|---|---|
| `auth/presentation/bienvenida_screen.dart` | 38 | `Icon(Icons.wb_sunny_rounded, size: 72, color: solar)` → `const SolSolarix(tamano: 72)` (y el círculo de fondo de 136 px con `colores.solarSuave`) |
| `auth/presentation/widgets/auth_widgets.dart` | 34 | `Icon(Icons.wb_sunny_rounded, …)` → `SolSolarix(tamano: …)` con el mismo tamaño |
| `dashboard/presentation/inicio_screen.dart` | 67 | `Icon(Icons.wb_sunny_rounded, size: 40, …)` → `const SolSolarix(tamano: 40)` |
| `calculadora/presentation/calculadora_screen.dart` | 702 | `Icon(Icons.wb_sunny_outlined)` del `ListTile` de horas solares pico: **puede quedarse** (es un ícono de línea pequeño junto a otros íconos de línea). Si prefieres coherencia total, usa `const SolSolarix(tamano: 24)` |

Y en el código de esta guía, la `BarraWeb` (sección 4.1) y la Bienvenida web (sección 5.1)
ya usan `SolSolarix`.

> Como `SolSolarix` es una imagen, **no cambia de color** con el tema. El ámbar del sol se ve
> bien en claro y en oscuro, así que no hace falta una versión aparte.

---

## 3. Widgets reutilizables nuevos

Archivo nuevo: `lib/core/widgets/solarix_ui.dart`. Son los componentes del mockup que se repiten
en varias pantallas.

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ancho a partir del cual se usa el diseño web (barra superior y columnas).
const anchoWeb = 900.0;

/// `true` en pantallas anchas (web en escritorio, tablet horizontal).
bool esAncho(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= anchoWeb;

/// Paleta de una burbuja: fondo suave + color del ícono.
enum TonoBurbuja { solar, verde, azul }

/// Círculo de color con un ícono: encabeza tarjetas e ítems de listas.
class BurbujaIcono extends StatelessWidget {
  const BurbujaIcono(this.icono, {super.key, this.tono = TonoBurbuja.solar, this.tamano = 40});

  final IconData icono;
  final TonoBurbuja tono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colores = ColoresSolarix.of(context);
    final (fondo, frente) = switch (tono) {
      TonoBurbuja.solar => (colores.solarSuave, esquema.primary),
      TonoBurbuja.verde => (esquema.secondaryContainer, esquema.secondary),
      TonoBurbuja.azul => (esquema.tertiaryContainer, esquema.tertiary),
    };
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Icon(icono, size: tamano / 2, color: frente),
    );
  }
}

/// Tarjeta con encabezado "burbuja + título" (Tu consumo, Costos, etc.).
class TarjetaSeccion extends StatelessWidget {
  const TarjetaSeccion({
    super.key,
    required this.titulo,
    required this.icono,
    required this.children,
    this.tono = TonoBurbuja.solar,
    this.subtitulo,
    this.accion,
    this.margen = const EdgeInsets.only(top: 12),
  });

  final String titulo;
  final String? subtitulo;
  final IconData icono;
  final TonoBurbuja tono;
  final List<Widget> children;

  /// Widget a la derecha del título (p. ej. "Ver todo el historial").
  final Widget? accion;
  final EdgeInsetsGeometry margen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: margen,
      child: Padding(
        padding: EdgeInsets.all(esAncho(context) ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BurbujaIcono(icono, tono: tono),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitulo != null)
                        Text(subtitulo!, style: tema.textTheme.labelMedium?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant)),
                      Text(titulo, style: tema.textTheme.titleMedium?.copyWith(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ?accion,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Fila "etiqueta ……… valor" de las tarjetas de resultados.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.total = false});

  final String etiqueta;
  final String valor;

  /// Fila de total: etiqueta en negrita y valor grande.
  final bool total;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: total
                  ? const TextStyle(fontWeight: FontWeight.w600)
                  : TextStyle(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: total ? 18 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mosaico con una cifra grande y su etiqueta (1,1 kWp · $ 14,8 M · 11,8 años).
class MosaicoCifra extends StatelessWidget {
  const MosaicoCifra(this.valor, this.etiqueta, {super.key});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface, // crema dentro de la tarjeta blanca
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valor, maxLines: 1, style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600)),
          ),
          Text(etiqueta, textAlign: TextAlign.center, style: tema.textTheme.labelMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Banda de color con ícono y texto: consumo total (verde), notas (azul).
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.icono, required this.texto, this.detalle, this.tono = TonoBurbuja.azul});

  final IconData icono;
  final String texto;
  final String? detalle;
  final TonoBurbuja tono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final (fondo, frente) = switch (tono) {
      TonoBurbuja.verde => (esquema.secondaryContainer, esquema.secondary),
      TonoBurbuja.azul => (esquema.tertiaryContainer, esquema.tertiary),
      TonoBurbuja.solar => (ColoresSolarix.of(context).solarSuave, esquema.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icono, color: frente),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (detalle != null)
                  Text(detalle!, style: tema.textTheme.labelMedium?.copyWith(
                      color: esquema.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado de un paso: "PASO 2 DE 4" + pregunta + ayuda.
class EncabezadoPaso extends StatelessWidget {
  const EncabezadoPaso({super.key, required this.paso, required this.total, required this.pregunta, this.ayuda});

  final int paso; // desde 1
  final int total;
  final String pregunta;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PASO $paso DE $total', style: tema.textTheme.labelMedium?.copyWith(
            color: tema.colorScheme.primary, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(pregunta, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        if (ayuda != null) ...[
          const SizedBox(height: 4),
          Text(ayuda!, style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}
```

> `?accion` (elemento nulo opcional en colecciones) requiere Dart ≥ 3.8; tu `pubspec` pide
> `^3.13.4`, así que sirve. Si prefieres, usa `if (accion != null) accion!`.

---

## 4. Diseño adaptativo: celular vs. web

Regla: **< 900 px = diseño de celular** (como hoy, con `AppBar`), **≥ 900 px = diseño web** (barra
de navegación superior + columnas). Así el mismo código sirve para el APK y para la web, y la web en
un celular sigue viéndose como la app.

### 4.1 Barra de navegación web

Archivo nuevo: `lib/core/widgets/barra_web.dart`. Va como `appBar` del `Scaffold` cuando `esAncho`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../router/rutas.dart';
import '../theme/app_theme.dart';
import 'navegacion.dart';

/// Barra superior del diseño web: logo, enlaces y usuario.
class BarraWeb extends ConsumerWidget implements PreferredSizeWidget {
  const BarraWeb({super.key, this.antesDeSalir});

  /// Para pantallas con resultados sin guardar (igual que BotonInicio).
  final AntesDeSalir? antesDeSalir;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final ubicacion = GoRouterState.of(context).matchedLocation;
    final haySesion = ref.watch(haySesionProvider);
    final nombre = haySesion ? ref.watch(perfilProvider).value?.nombre : null;

    Future<void> ir(String ruta) async {
      if (antesDeSalir != null && !await antesDeSalir!()) return;
      if (context.mounted) context.go(ruta);
    }

    Widget enlace(String texto, IconData icono, String ruta, {bool exacta = false}) {
      final activo = exacta ? ubicacion == ruta : ubicacion.startsWith(ruta);
      final color = activo ? tema.colorScheme.primary : tema.colorScheme.onSurfaceVariant;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextButton.icon(
          onPressed: () => ir(ruta),
          style: TextButton.styleFrom(
            foregroundColor: color,
            backgroundColor: activo ? ColoresSolarix.of(context).solarSuave : null,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: Icon(icono, size: 18),
          label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Material(
      color: tema.colorScheme.surfaceContainerLowest,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tema.colorScheme.outlineVariant)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Row(
              children: [
                InkWell(
                  onTap: () => ir(Rutas.inicio),
                  child: Row(children: [
                    const SolSolarix(tamano: 30),
                    const SizedBox(width: 10),
                    Text('Solarix', style: tema.textTheme.titleLarge),
                  ]),
                ),
                const Spacer(),
                enlace('Inicio', Icons.home_outlined, Rutas.inicio, exacta: true),
                enlace('Calculadora', Icons.calculate_outlined, Rutas.calculadora),
                enlace('Simulación', Icons.battery_charging_full_outlined, Rutas.simulacion),
                if (haySesion) enlace('Historial', Icons.history, Rutas.historial),
                const Spacer(),
                if (!haySesion)
                  FilledButton(onPressed: () => ir(Rutas.login), child: const Text('Iniciar sesión'))
                else
                  _ChipUsuario(
                    nombre: nombre ?? '',
                    activo: ubicacion == Rutas.perfil,
                    onTap: () => ir(Rutas.perfil),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipUsuario extends StatelessWidget {
  const _ChipUsuario({required this.nombre, required this.activo, required this.onTap});

  final String nombre;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = ColoresSolarix.of(context);
    final primerNombre = nombre.trim().split(' ').first;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: activo ? colores.solarSuave : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          AvatarIniciales(nombre: nombre, tamano: 36),
          const SizedBox(width: 10),
          Text(primerNombre.isEmpty ? 'Mi perfil' : primerNombre,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// Círculo ámbar con las iniciales ("SC"). Se usa en la barra y en el perfil.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.nombre, this.tamano = 88});

  final String nombre;
  final double tamano;

  String get _iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return (partes.first[0] + (partes.length > 1 ? partes[1][0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colores = ColoresSolarix.of(context);
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colores.solarSuave,
        shape: BoxShape.circle,
        border: Border.all(color: colores.solar, width: tamano > 50 ? 2 : 1.5),
      ),
      child: Text(_iniciales, style: TextStyle(
        fontSize: tamano * 0.3,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      )),
    );
  }
}
```

### 4.2 Patrón para cada pantalla

```dart
@override
Widget build(BuildContext context) {
  final ancho = esAncho(context);
  return Scaffold(
    appBar: ancho
        ? BarraWeb(antesDeSalir: _puedeSalir) // en las que no tienen nada sin guardar: const BarraWeb()
        : AppBar(title: const Text('Resultados'), actions: [BotonInicio(antesDeSalir: _puedeSalir)]),
    body: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho ? 1120 : 640),
        child: ListView(
          padding: ancho
              ? const EdgeInsets.fromLTRB(24, 40, 24, 56)
              : const EdgeInsets.all(16),
          children: ancho ? _contenidoWeb() : _contenidoCelular(),
        ),
      ),
    ),
  );
}
```

Para poner dos tarjetas lado a lado en web:

```dart
/// Dos columnas en web, una sola en celular.
Widget dosColumnas(BuildContext context, Widget a, Widget b) => esAncho(context)
    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a), const SizedBox(width: 24), Expanded(child: b)])
    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, b]);
```

(Puede vivir en `solarix_ui.dart`.)

---

## 5. Pantalla por pantalla

### 5.1 Bienvenida — `auth/presentation/bienvenida_screen.dart`

**Celular:** queda casi igual. Cambios:
- El círculo del sol pasa a **136 px** con `colores.solarSuave` de fondo (en vez de `solar` al 15 %).
- Debajo de "Probar sin cuenta", un enlace pequeño *"Política de tratamiento de datos"* (`labelMedium`)
  que lleve a `Rutas.politicaDatos`. **No** "Al continuar aceptas…": la Ley 1581 pide autorización
  previa y expresa, que ya da la casilla del registro; "Probar sin cuenta" no recoge datos personales.

**Web (≥ 900 px):** dos columnas a pantalla completa.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  if (!esAncho(context)) return _vistaCelular(context, ref); // la actual
  final tema = Theme.of(context);
  final colores = ColoresSolarix.of(context);
  return Scaffold(
    body: Row(
      children: [
        // Izquierda: presentación sobre ámbar suave.
        Expanded(
          child: Container(
            color: colores.solarSuave,
            padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const SolSolarix(tamano: 36),
                  const SizedBox(width: 10),
                  Text('Solarix', style: tema.textTheme.headlineSmall),
                ]),
                const SizedBox(height: 24),
                Text('Energía solar a la medida de tu casa',
                    style: tema.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Text('Calcula cuántos paneles necesitas, cuánto cuestan y en cuánto tiempo '
                    'recuperas la inversión. Luego simula cómo se desgasta tu batería con los años.',
                    style: tema.textTheme.bodyLarge?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                for (final (icono, titulo, detalle) in const [
                  (Icons.calculate_outlined, 'Dimensionamiento y costos', 'Paneles, batería, inversor y retorno de inversión.'),
                  (Icons.battery_charging_full_outlined, 'Salud de la batería a 10 años', 'Compara el uso consciente con el convencional.'),
                  (Icons.cloud_done_outlined, 'Todo guardado en la nube', 'Vuelve a tus cálculos desde la web o el celular.'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      CircleAvatar(radius: 24, backgroundColor: tema.colorScheme.surfaceContainerLowest,
                          child: Icon(icono, color: tema.colorScheme.primary)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(titulo, style: tema.textTheme.titleMedium),
                        Text(detalle, style: TextStyle(color: tema.colorScheme.onSurfaceVariant)),
                      ])),
                    ]),
                  ),
              ],
            ),
          ),
        ),
        // Derecha: tarjeta de acceso.
        SizedBox(
          width: 620,
          child: Center(
            child: SizedBox(
              width: 440,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: _accesos(context, ref), // sol + título + 3 botones + texto Ley 1581
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

Extrae a `_accesos(context, ref)` el bloque actual de los tres botones para reutilizarlo en las dos
vistas.

### 5.2 Inicio — `dashboard/presentation/inicio_screen.dart`

**Cambios comunes (celular y web):**

1. **Saludo con nombre** en vez del texto fijo:
   ```dart
   final nombre = haySesion ? ref.watch(perfilProvider).value?.nombre : null;
   final primerNombre = nombre?.trim().split(' ').first;
   // …
   Text(primerNombre == null || primerNombre.isEmpty ? 'Hola' : 'Hola, $primerNombre',
       style: tema.textTheme.titleLarge),
   Text('Calculadora solar y simulador de degradación de baterías',
       style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
   ```
2. En celular, los dos botones van **uno debajo del otro y a lo ancho** (`Column` + `CrossAxisAlignment.stretch`)
   en vez de `Wrap`.
3. **Tarjeta "Último cálculo"** con `TarjetaSeccion` + 3 `MosaicoCifra`:
   ```dart
   TarjetaSeccion(
     icono: Icons.calculate_outlined,
     subtitulo: 'Último cálculo',
     titulo: '${calculo.titulo} · ${calculo.tipo.etiqueta}',
     children: [
       Row(children: [
         Expanded(child: MosaicoCifra('${Formato.numero(calculo.potenciaKw, 1)} kWp',
             '${calculo.numeroPaneles} paneles')),
         const SizedBox(width: 8),
         Expanded(child: MosaicoCifra(Formato.cop(calculo.costoTotal), 'inversión')),
         const SizedBox(width: 8),
         Expanded(child: MosaicoCifra(Formato.anios(calculo.paybackAnios, 20), 'recuperación')),
       ]),
       const SizedBox(height: 8),
       Text(fechaCorta(calculo.creadoEn), style: tema.textTheme.labelMedium),
     ],
   )
   ```
   > Para "$ 14,8 M" en vez de "$ 14.800.000" usa `Formato.copCorto`, que ya existe en
   > `core/formato.dart` (Etapa 8).
4. **Tarjeta "Última simulación"** con `TarjetaSeccion(tono: TonoBurbuja.verde, icono: Icons.battery_charging_full_outlined, subtitulo: 'Última simulación · ${fecha}', titulo: 'SoH 86,4 % (política consciente)')`
   y debajo la `GraficaSoh` que ya tienes + una **leyenda** (punto de color + texto):
   ```dart
   Wrap(spacing: 16, runSpacing: 6, children: [
     _ItemLeyenda(colores.consciente, 'Consciente'),
     _ItemLeyenda(colores.convencional, 'Convencional'),
     _ItemLeyenda(colores.finDeVida, 'Fin de vida (80 %)'),
   ])

   class _ItemLeyenda extends StatelessWidget {
     const _ItemLeyenda(this.color, this.texto);
     final Color color;
     final String texto;
     @override
     Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
       Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
       const SizedBox(width: 6),
       Text(texto, style: Theme.of(context).textTheme.labelMedium),
     ]);
   }
   ```
   (Si `GraficaSoh` ya dibuja su leyenda, no la dupliques.)
5. "Ver todo el historial" como `TextButton.icon` con `Icons.history`.

**Web:**
- Fila superior: saludo a la izquierda y los dos botones a la derecha (secundario "Simular…" y
  principal "Calcular…").
- Las dos tarjetas lado a lado con `dosColumnas(context, tarjetaCalculo, tarjetaSimulacion)`. En la
  de cálculo agrega `FilaDato`s: Consumo, Batería, Ahorro el primer mes, VPN. Los tres primeros ya están
  en `CalculoGuardado` (`energiaDiaKwh`, `bateriaKwh`, `ahorroMensual`); el **VPN no**: hay que leerlo de
  `resultados['vpn']` en `CalculoGuardado.desdeFila`.
- Debajo, la **tarjeta "Historial reciente"**: los 3 elementos más nuevos mezclando cálculos y
  simulaciones:
  ```dart
  final recientes = [
    for (final c in calculos.value ?? const <CalculoGuardado>[]) (c.creadoEn, c),
    for (final s in simulaciones.value ?? const <SimulacionGuardada>[]) (s.creadoEn, s),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  // recientes.take(3) → ListTile(leading: BurbujaIcono(...), title, subtitle, trailing: valor + chevron)
  ```

### 5.3 Calculadora — `calculadora/presentation/calculadora_screen.dart`

Es el cambio más grande: **se reemplaza el `Stepper`** por un indicador propio. La lógica
(`_paso`, `_formularios`, `_continuar`, validaciones) **se queda igual**.

**a) Títulos de cada paso**

```dart
static const _pasos = [
  ('Tipo', 'Tipo de sistema', '¿Qué sistema quieres?', 'Elige cómo se conecta tu casa.'),
  ('Consumo', 'Consumo', '¿Cuánta energía usas?', 'Agrega los equipos de tu casa y cuántas horas los usas al día.'),
  ('Ubicación', 'Ubicación', '¿Dónde está la casa?', 'Con el lugar calculamos las horas de sol.'),
  ('Equipos', 'Equipos y costos', 'Equipos y costos', 'Ajusta el panel, la batería y los precios.'),
];
```

**b) Indicador horizontal (celular)**

```dart
/// Círculos numerados con check en los pasos hechos.
class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({super.key, required this.actual, required this.etiquetas, this.alTocar});

  final int actual; // desde 0
  final List<String> etiquetas;
  final ValueChanged<int>? alTocar; // solo pasos anteriores

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = ColoresSolarix.of(context);
    return Row(
      children: [
        for (var i = 0; i < etiquetas.length; i++)
          Expanded(
            child: InkWell(
              onTap: i < actual && alTocar != null ? () => alTocar!(i) : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < actual
                            ? tema.colorScheme.secondary
                            : i == actual
                                ? colores.solar
                                : tema.colorScheme.surfaceContainerLowest,
                        border: i > actual ? Border.all(color: colores.bordeFuerte, width: 1.5) : null,
                      ),
                      child: i < actual
                          ? Icon(Icons.check, size: 16, color: tema.colorScheme.onSecondary)
                          : Text('${i + 1}', style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: i == actual ? colores.textoSobreSolar : tema.colorScheme.onSurfaceVariant)),
                    ),
                    const SizedBox(height: 6),
                    Text(etiquetas[i], style: tema.textTheme.labelMedium?.copyWith(
                        color: i <= actual ? tema.colorScheme.onSurface : tema.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

**c) Nuevo `build`**

```dart
Widget _contenidoPaso() => switch (_paso) {
  0 => _pasoSistema(),
  1 => _pasoConsumo(),
  2 => _pasoUbicacion(),
  _ => _pasoEquipos(),
};

Widget _panelPaso() {
  final (_, _, pregunta, ayuda) = _pasos[_paso];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EncabezadoPaso(paso: _paso + 1, total: 4, pregunta: pregunta, ayuda: ayuda),
      const SizedBox(height: 16),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Form(key: _formularios[_paso], child: KeyedSubtree(
            key: ValueKey(_paso), child: _contenidoPaso())),
      ),
      if (_error != null) ...[const SizedBox(height: 12), MensajeError(_error!)],
      const SizedBox(height: 16),
      Row(
        children: [
          if (_paso > 0)
            TextButton.icon(
              onPressed: () => setState(() { _error = null; _paso--; }),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Atrás'),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: _continuar,
              child: Text(_paso == 3 ? 'Calcular' : 'Siguiente'),
            ),
          ),
        ],
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  final ancho = esAncho(context);
  return Scaffold(
    appBar: ancho
        ? const BarraWeb()
        : AppBar(title: const Text('Calculadora solar'), actions: const [BotonInicio()]),
    body: ancho ? _vistaWeb() : ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        IndicadorPasos(
          actual: _paso,
          etiquetas: [for (final p in _pasos) p.$1],
          alTocar: (i) => setState(() { _error = null; _paso = i; }),
        ),
        const SizedBox(height: 16),
        _panelPaso(),
      ],
    ),
  );
}
```

> `_continuar` **no hay que tocarlo**: ya valida con `_validarPaso(_paso)`, hace `_paso++` y
> en el último paso llama a `_calcular()`. Antes lo llamaba `onStepContinue` del `Stepper`;
> ahora lo llama el botón "Siguiente"/"Calcular".

**d) Vista web:** tarjeta de pasos a la izquierda (300 px) y el paso en una tarjeta grande a la derecha.

```dart
Widget _vistaWeb() {
  final tema = Theme.of(context);
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 56),
        children: [
          Text('Calculadora solar', style: tema.textTheme.headlineSmall),
          Text('Dimensiona tu sistema en 4 pasos. Puedes volver a cualquier paso ya hecho.',
              style: tema.textTheme.bodyLarge?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      for (var i = 0; i < _pasos.length; i++) _PasoLateral(
                        numero: i + 1,
                        titulo: _pasos[i].$2,
                        detalle: _resumenPaso(i), // p. ej. 'Híbrido', '2,53 kWh/día'
                        estado: i < _paso ? EstadoPaso.hecho : i == _paso ? EstadoPaso.activo : EstadoPaso.pendiente,
                        onTap: i < _paso ? () => setState(() => _paso = i) : null,
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(padding: const EdgeInsets.all(28), child: _panelPaso()),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

`_PasoLateral` es un `ListTile` con el mismo círculo del `IndicadorPasos` como `leading` y fondo
`solarSuave` cuando está activo. `_resumenPaso(i)` devuelve un texto corto de lo ya elegido.

**e) Paso "Consumo" — `widgets/equipos_editor.dart`**

- **Celular:** los equipos dentro de **una sola `Card`** separados por `Divider(height: 1)`. Cada fila:
  nombre (`titleMedium`), detalle `"4 × 9 W · 5 h/día"` (`labelMedium` gris), a la derecha el
  consumo en negrita (`"180 Wh"`) y el botón de quitar.
- Botón **"Agregar equipo"** como `OutlinedButton.icon(icon: Icon(Icons.add))` a lo ancho.
- El texto de "Consumo total" pasa a una banda verde:
  ```dart
  Aviso(
    tono: TonoBurbuja.verde,
    icono: Icons.bolt_outlined,
    texto: 'Consumo total: ${Formato.numero(totalWh / 1000, 2)} kWh/día',
    detalle: '≈ ${Formato.numero(totalWh * 30 / 1000, 1)} kWh al mes',
  )
  ```
- **Web:** una tabla con columnas *Equipo · Cantidad · Potencia · Uso al día · Consumo · (quitar)*.
  Con `Table` + `TableRow` o con filas `Row` de anchos fijos (90/110/110/110 px y la primera
  `Expanded`). Encabezado en `labelMedium` gris sobre fondo `colorScheme.surface`. A la derecha del
  botón "Agregar equipo", el `Aviso` verde en la misma fila.
- En web, "Estrato" y "Tarifa" van **lado a lado** con `dosColumnas`.

### 5.4 Resultados — `calculadora/presentation/resultados_screen.dart`

1. **`_Destacado`**: cambia el color de la `Card` a `colores.solarSuave` con borde ámbar:
   ```dart
   return Card(
     color: ColoresSolarix.of(context).solarSuave,
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(16),
       side: BorderSide(color: ColoresSolarix.of(context).solar),
     ),
     // …
   ```
   Las etiquetas debajo de cada cifra en `colorScheme.primary`. En **web** agrega una 4.ª cifra
   ("ahorro el primer mes") y separadores verticales ámbar entre cifras (`VerticalDivider` dentro
   de un `IntrinsicHeight`).
2. **`_Seccion`** pasa a ser `TarjetaSeccion` + `FilaDato`. Tonos sugeridos:
   - Tu consumo → `Icons.bolt_outlined`, **azul**
   - Sistema recomendado → `Icons.solar_power_outlined`, **solar**
   - Costos estimados → `Icons.payments_outlined`, **verde**; la fila "Total" con `FilaDato(..., total: true)`
     y un `Divider` antes
   - Ahorro y retorno → `Icons.trending_up`, **verde**
   - ¿Y sin batería? → `Icons.compare_arrows`, **azul**
3. La nota de IVA (Ley 1715) sale de la tarjeta de costos y pasa a un `Aviso(tono: TonoBurbuja.azul, icono: Icons.info_outline, texto: ...)`.
4. **Web:** encabezado con "Volver a la calculadora" (`TextButton.icon` con flecha), título
   *"Resultados · {nombre del cálculo}"*, subtítulo *"{tipo} · {ubicación}"*, y **a la derecha los
   botones** "Simular la salud de esta batería" (secundario) y "Guardar cálculo" (principal). Debajo,
   las tarjetas en **grilla 2×2** con `dosColumnas`.
5. **Aviso al guardar** (en `_guardar`):
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
     content: const Text('Cálculo guardado. Lo verás en tu historial.'),
     action: SnackBarAction(label: 'VER', onPressed: () => context.go(Rutas.historial)),
   ));
   ```

### 5.5 Perfil — `auth/presentation/perfil_screen.dart`

**Encabezado** (arriba del formulario):

```dart
Column(children: [
  AvatarIniciales(nombre: widget.perfil.nombre),
  const SizedBox(height: 8),
  Text(widget.perfil.nombre, style: tema.textTheme.titleLarge),
  Text(widget.email, style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
])
```

**Mosaicos de actividad** (usa los providers del historial que ya existen):

```dart
final nCalculos = ref.watch(calculosGuardadosProvider).value?.length;
final nSimulaciones = ref.watch(simulacionesGuardadasProvider).value?.length;
// …
Row(children: [
  Expanded(child: _Actividad(Icons.calculate_outlined, nCalculos, 'cálculos guardados')),
  const SizedBox(width: 12),
  Expanded(child: _Actividad(Icons.battery_charging_full_outlined, nSimulaciones, 'simulaciones')),
])
// _Actividad: Card con ícono ámbar, número grande ('—' si es null) y etiqueta.
```

**Tarjetas:**
- **"Datos personales"**: Nombre + Ciudad + texto de ayuda + "Guardar cambios" (en web, Nombre y
  Ciudad lado a lado y el correo como campo de solo lectura arriba).
- **"Apariencia"**: el `SegmentedButton` actual dentro de una `Card` con título.

**Acciones de cuenta:** "Cerrar sesión" (`OutlinedButton.icon`, `Icons.logout`), `Divider`,
"Política de tratamiento de datos" y "Eliminar mi cuenta" (rojo), como hoy.

**Web:** dos columnas: izquierda una `Card` de 340 px con avatar, nombre, correo, mosaicos y las
acciones de cuenta; derecha (`Expanded`) las tarjetas "Datos personales" y "Apariencia".

### 5.6 Pantallas que no están en el mockup

Simulación, Resultados de simulación, Historial, Detalle, Login, Registro y Recuperar no se
diseñaron, pero para que todo se vea coherente aplica lo mismo:

- `BarraWeb` como `appBar` cuando `esAncho`.
- Tarjetas con `TarjetaSeccion` (simulación → tono **verde**; energía/consumo → **azul**).
- Pasos o formularios largos → `EncabezadoPaso`.
- Historial: cada elemento con `BurbujaIcono` (cálculo = solar, simulación = verde) + chevron.
- Login/Registro en web: la misma tarjeta de 440 px centrada sobre el fondo crema.

---

## 6. Pruebas que hay que actualizar

Estos tests buscan textos o widgets que cambian:

| Archivo | Qué busca | Qué hacer |
|---|---|---|
| `test/features/pulido_interfaz_test.dart` (≈ línea 111) | `find.text('Último cálculo: Casa')` | Ahora "Último cálculo" y el nombre son dos textos: usa `find.text('Último cálculo')` y `find.textContaining('Casa')` |
| `test/features/dashboard/historial_test.dart` (≈ línea 100) | `find.text('Último cálculo: Casa')` | Igual que el anterior |
| `test/helpers/flujo_completo.dart` (≈ línea 172) | Espera `'Último cálculo: $nombreCalculo'` | Igual; lo usan la prueba de principio a fin y las de integración |
| `test/features/pulido_interfaz_test.dart` | Cifras y opciones en una línea a 320 px (Etapa 12) | Debe seguir pasando con los mosaicos y el indicador de pasos nuevos |
| `test/features/calculadora/flujo_calculadora_test.dart` | Toca `boton('Siguiente')` y `'Calcular'` | Esos textos se mantienen, así que debería seguir pasando. Si algún paso queda fuera de pantalla, agrega `ensureVisible` antes de tocar (el contenido ahora va en un `ListView`) |
| `test/features/navegacion_test.dart` | `'Calcular mi sistema solar'`, `'Volver al inicio'`, `'Resultados'` | En celular siguen igual. Si pruebas en web (≥ 900 px), "Resultados" ahora es "Resultados · …" |
| `test/core/paleta_contraste_test.dart` | Contrastes del esquema | Agrega casos para `solarSuave` con `onSurface` y `primary` (≥ 4,5:1) |
| `integration_test/flujo_completo_test.dart` | Flujo completo | Ajusta según el cambio del `Stepper` |

Corre todo con:

```bash
flutter analyze
flutter test
```

Y prueba a mano en los dos tamaños:

```bash
flutter run -d chrome --dart-define-from-file=env.json     # angosta y ancha la ventana para ver el cambio a 900 px
flutter run -d <id-celular> --dart-define-from-file=env.json
```

---

## 7. Orden sugerido y checklist

Cada paso deja la app funcionando, así que puedes hacer un commit por paso.

- [ ] **1. Tema:** agregar `solarSuave` y `bordeFuerte`, botón secundario, campos, segmentado, snackbar (sección 2).
- [ ] **1b. Sol:** declarar `assets/icono/sol.png` en `pubspec.yaml`, crear `SolSolarix` y reemplazar los `Icons.wb_sunny_rounded` (sección 2.4).
- [ ] **2. Widgets base:** crear `solarix_ui.dart` (sección 3) y `barra_web.dart` (sección 4.1).
- [ ] **3. Resultados:** `_Seccion` → `TarjetaSeccion`, destacado ámbar, aviso con "VER", grilla web.
- [ ] **4. Inicio:** saludo, mosaicos, leyenda, historial reciente en web.
- [ ] **5. Perfil:** avatar, actividad, tarjetas, dos columnas en web.
- [ ] **6. Calculadora:** quitar `Stepper`, `IndicadorPasos`, `EncabezadoPaso`, vista web con pasos laterales.
- [ ] **7. Equipos:** lista en tarjeta, banda verde de consumo, tabla en web.
- [ ] **8. Bienvenida web:** dos columnas.
- [ ] **9. Resto de pantallas:** `BarraWeb` + `TarjetaSeccion` (sección 5.6).
- [ ] **10. Pruebas:** actualizar tests (sección 6), `flutter analyze` y `flutter test` en verde.
- [ ] **11. Revisión visual:** comparar cada pantalla con el mockup en Figma, en celular y en web,
      en modo claro y oscuro.
- [ ] **12. Bitácora:** anotar la Etapa 13 en `docs/BITACORA.md` y en `docs/ETAPAS_SOLARIX_APP.md`.

### Medidas de referencia del mockup

| Elemento | Valor |
|---|---|
| Ancho del celular | 360 px (contenido con 16 px de margen) |
| Ancho máximo web | 1120 px; barra superior de 72 px |
| Cambio a diseño web | 900 px |
| Alto de botones | 48 px, radio 12 |
| Tarjetas | radio 16, borde `outlineVariant`, sombra suave, padding 16 (celular) / 20–28 (web) |
| Campos | alto 52 px, radio 12, borde `bordeFuerte` |
| Burbujas de ícono | 36–40 px, ícono de 20 px |
| Separación entre tarjetas | 12–16 px (celular), 24 px (web) |
