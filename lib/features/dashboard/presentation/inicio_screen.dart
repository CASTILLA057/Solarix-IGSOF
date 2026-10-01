import 'package:flutter/material.dart';

import '../../../core/config/env.dart';

/// Pantalla inicial provisional. Se convierte en el dashboard en la Etapa 7.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  static const ruta = '/';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Solarix')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wb_sunny_rounded,
                size: 72,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Solarix', style: tema.textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Calculadora solar y simulador de degradación de baterías',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Chip(
                avatar: Icon(
                  Env.supabaseConfigurado
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                label: Text(
                  Env.supabaseConfigurado
                      ? 'Supabase conectado'
                      : 'Supabase sin configurar (falta env.json)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
