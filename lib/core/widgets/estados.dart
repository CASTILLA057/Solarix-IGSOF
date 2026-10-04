import 'package:flutter/material.dart';

import '../errors/error_app.dart';

/// Indicador de carga centrado, con un texto opcional.
class Cargando extends StatelessWidget {
  const Cargando({super.key, this.texto});

  final String? texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (texto != null) ...[
            const SizedBox(height: 12),
            Text(texto!, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

/// Pantalla o sección sin datos: ícono, mensaje y una acción opcional.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoAccion,
    this.alPresionar,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoAccion;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: tema.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (mensaje != null) ...[
              const SizedBox(height: 4),
              Text(
                mensaje!,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (textoAccion != null && alPresionar != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: alPresionar,
                child: Text(textoAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensaje que se muestra al usuario para cualquier error.
String mensajeDe(Object error) => error is ErrorApp
    ? error.mensaje
    : 'Ocurrió un error inesperado. Intenta de nuevo.';

/// Error con su mensaje y el botón "Reintentar".
class EstadoError extends StatelessWidget {
  const EstadoError({super.key, required this.error, this.alReintentar});

  final Object error;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: tema.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(mensajeDe(error), textAlign: TextAlign.center),
            if (alReintentar != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
