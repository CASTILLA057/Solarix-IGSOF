import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/rutas.dart';

/// Antes de salir: `true` para continuar, `false` para quedarse.
typedef AntesDeSalir = Future<bool> Function();

/// Vuelve al inicio desde cualquier pantalla, después de [antesDeSalir].
Future<void> irAlInicio(
  BuildContext context, [
  AntesDeSalir? antesDeSalir,
]) async {
  if (antesDeSalir != null && !await antesDeSalir()) return;
  if (context.mounted) context.go(Rutas.inicio);
}

/// Ícono de casa para la barra superior de las pantallas internas.
class BotonInicio extends StatelessWidget {
  const BotonInicio({super.key, this.antesDeSalir});

  final AntesDeSalir? antesDeSalir;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Ir al inicio',
    icon: const Icon(Icons.home_outlined),
    onPressed: () => irAlInicio(context, antesDeSalir),
  );
}

/// Botón "Volver al inicio" para el final de las pantallas de resultados.
class BotonVolverAlInicio extends StatelessWidget {
  const BotonVolverAlInicio({super.key, this.antesDeSalir});

  final AntesDeSalir? antesDeSalir;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => irAlInicio(context, antesDeSalir),
    style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    icon: const Icon(Icons.home_outlined),
    label: const Text('Volver al inicio'),
  );
}

enum _Salida { guardar, salir }

/// Pregunta antes de dejar un resultado sin guardar. [que] es, p. ej.,
/// "este cálculo". Devuelve `true` si se puede salir: eligió salir sin
/// guardar, o eligió guardar y [guardar] lo logró.
Future<bool> confirmarSalidaSinGuardar(
  BuildContext context, {
  required String que,
  required Future<bool> Function() guardar,
}) async {
  final opcion = await showDialog<_Salida>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('No has guardado $que'),
      content: const Text(
        'Si vuelves al inicio sin guardar, este resultado se pierde.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _Salida.salir),
          child: const Text('Salir sin guardar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _Salida.guardar),
          child: const Text('Guardar y salir'),
        ),
      ],
    ),
  );
  return switch (opcion) {
    null => false,
    _Salida.salir => true,
    _Salida.guardar => await guardar(),
  };
}
