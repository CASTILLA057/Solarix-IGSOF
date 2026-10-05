import 'package:flutter/material.dart';

import '../domain/politica_datos.dart';

/// Política de tratamiento de datos (Ley 1581 de 2012). Se abre desde el
/// registro y desde el perfil, con o sin sesión.
class PoliticaDatosScreen extends StatelessWidget {
  const PoliticaDatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tratamiento de datos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Política de tratamiento de datos personales',
                style: tema.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Ley 1581 de 2012 · versión ${PoliticaDatos.version}',
                style: tema.textTheme.bodySmall,
              ),
              for (final (titulo, texto) in PoliticaDatos.secciones) ...[
                const SizedBox(height: 16),
                Text(titulo, style: tema.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(texto, style: tema.textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
