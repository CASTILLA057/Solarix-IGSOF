import 'package:flutter/material.dart';

/// Etiqueta de un [ButtonSegment] en una sola línea: en pantallas angostas
/// (320 px) el texto se achica en vez de partirse a mitad de palabra
/// ("Convencio" / "nal").
class EtiquetaSegmento extends StatelessWidget {
  const EtiquetaSegmento(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(texto, maxLines: 1, softWrap: false),
  );
}
