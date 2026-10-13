import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Componentes del mockup de Figma (Etapa 13) que se repiten en varias
// pantallas. Guía: docs/MEJORAS_UI_MOCKUP.md.

/// Ancho a partir del cual se usa el diseño web (barra superior y columnas).
const anchoWeb = 900.0;

/// Ancho máximo del contenido en el diseño web.
const anchoMaximoWeb = 1120.0;

/// `true` en pantallas anchas (web en escritorio, tablet horizontal).
bool esAncho(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= anchoWeb;

/// Dos columnas en web, una sola en celular.
Widget dosColumnas(BuildContext context, Widget a, Widget b) => esAncho(context)
    ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 24),
          Expanded(child: b),
        ],
      )
    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, b]);

/// Paleta de una burbuja o un aviso: fondo suave y color del ícono.
enum TonoBurbuja { solar, verde, azul }

(Color, Color) _coloresTono(BuildContext context, TonoBurbuja tono) {
  final esquema = Theme.of(context).colorScheme;
  return switch (tono) {
    TonoBurbuja.solar => (
      ColoresSolarix.of(context).solarSuave,
      esquema.primary,
    ),
    TonoBurbuja.verde => (esquema.secondaryContainer, esquema.secondary),
    TonoBurbuja.azul => (esquema.tertiaryContainer, esquema.tertiary),
  };
}

/// Círculo de color con un ícono: encabeza tarjetas e ítems de listas.
class BurbujaIcono extends StatelessWidget {
  const BurbujaIcono(
    this.icono, {
    super.key,
    this.tono = TonoBurbuja.solar,
    this.tamano = 40,
  });

  final IconData icono;
  final TonoBurbuja tono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final (fondo, frente) = _coloresTono(context, tono);
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
    required this.children,
    this.icono,
    this.tono = TonoBurbuja.solar,
    this.subtitulo,
    this.accion,
    this.alTocar,
    this.detalle,
    this.margen = const EdgeInsets.only(top: 12),
  });

  /// Texto pequeño debajo del título (p. ej. "Sistema híbrido · fecha").
  final String? detalle;

  final String titulo;

  /// Texto pequeño sobre el título ("Último cálculo").
  final String? subtitulo;

  /// Ícono de la burbuja; sin él, solo el título (como "Datos personales").
  final IconData? icono;
  final TonoBurbuja tono;
  final List<Widget> children;

  /// Widget a la derecha del título (p. ej. "Ver todo").
  final Widget? accion;

  /// Toda la tarjeta es tocable (p. ej., abre el detalle).
  final VoidCallback? alTocar;
  final EdgeInsetsGeometry margen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: margen,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: EdgeInsets.all(esAncho(context) ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (icono case final i?) ...[
                    BurbujaIcono(i, tono: tono),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitulo case final s?)
                          Text(
                            s,
                            style: tema.textTheme.labelMedium?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          titulo,
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (detalle case final d?)
                          Text(
                            d,
                            style: tema.textTheme.labelMedium?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
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
      ),
    );
  }
}

/// Fila "etiqueta ……… valor" de las tarjetas de resultados.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.total = false});

  final String etiqueta;
  final String valor;

  /// Fila de total: etiqueta en negrita y valor más grande.
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
            // Alineado a la derecha aunque sea corto ("2,00 kWh").
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: total ? 18 : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mosaico con una cifra grande y su etiqueta (1,1 kWp · inversión · años).
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
        // Crema dentro de la tarjeta blanca.
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En una línea: en pantallas angostas se achica (Etapa 12).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              maxLines: 1,
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Tampoco la etiqueta se parte ("recuperació" / "n").
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              etiqueta,
              maxLines: 1,
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banda de color con ícono y texto: consumo total (verde), notas (azul).
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.icono,
    required this.texto,
    this.detalle,
    this.tono = TonoBurbuja.azul,
  });

  final IconData icono;
  final String texto;
  final String? detalle;
  final TonoBurbuja tono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final (fondo, frente) = _coloresTono(context, tono);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, color: frente),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (detalle case final d?)
                  Text(
                    d,
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
  const EncabezadoPaso({
    super.key,
    required this.paso,
    required this.total,
    required this.pregunta,
    this.ayuda,
  });

  /// Desde 1.
  final int paso;
  final int total;
  final String pregunta;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO $paso DE $total',
          style: tema.textTheme.labelMedium?.copyWith(
            color: tema.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pregunta,
          style: tema.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (ayuda case final a?) ...[
          const SizedBox(height: 4),
          Text(
            a,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Título de la página en el diseño web (en celular lo lleva el AppBar).
class TituloPagina extends StatelessWidget {
  const TituloPagina(this.titulo, {super.key, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Como el AppBar: flecha de volver si la pantalla se puede cerrar.
    final puedeVolver = ModalRoute.of(context)?.canPop ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (puedeVolver) ...[const BackButton(), const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tema.textTheme.headlineSmall),
                if (subtitulo case final s?)
                  Text(
                    s,
                    style: tema.textTheme.bodyLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto de color con su texto, para leyendas de gráficas.
class ItemLeyenda extends StatelessWidget {
  const ItemLeyenda(this.color, this.texto, {super.key});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(texto, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}
