import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';

/// Primera pantalla sin sesión: presenta Solarix y lleva a iniciar sesión o
/// a crear una cuenta. El contenido aparece con un fundido suave.
class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _AparicionSuave(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: esquema.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wb_sunny_rounded,
                          size: 72,
                          color: esquema.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bienvenido a Solarix',
                      style: tema.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Calcula el sistema solar que necesita tu casa y '
                      'simula cómo se desgasta su batería con los años.',
                      style: tema.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const _Caracteristica(
                      icono: Icons.calculate_outlined,
                      texto: 'Paneles, batería, costos y retorno de inversión',
                    ),
                    const _Caracteristica(
                      icono: Icons.battery_charging_full_outlined,
                      texto: 'Salud de la batería a 10 años',
                    ),
                    const _Caracteristica(
                      icono: Icons.cloud_done_outlined,
                      texto: 'Tus cálculos guardados en la nube',
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => context.go(Rutas.login),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go(Rutas.registro),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Caracteristica extends StatelessWidget {
  const _Caracteristica({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

/// Fundido con un leve ascenso al mostrar la bienvenida por primera vez.
class _AparicionSuave extends StatelessWidget {
  const _AparicionSuave({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - valor)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
