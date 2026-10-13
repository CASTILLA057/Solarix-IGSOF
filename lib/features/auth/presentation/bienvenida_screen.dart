import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sol_solarix.dart';
import '../../../core/widgets/solarix_ui.dart';
import '../application/auth_providers.dart';

/// Primera pantalla sin sesión: presenta Solarix y lleva a iniciar sesión, a
/// crear una cuenta o a probar sin cuenta. En web, dos columnas (mockup,
/// Etapa 13). El contenido aparece con un fundido suave.
class BienvenidaScreen extends ConsumerWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (esAncho(context)) return _vistaWeb(context, ref);
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
                    const _SolEnCirculo(),
                    const SizedBox(height: 24),
                    ..._titulo(context),
                    const SizedBox(height: 24),
                    for (final (icono, texto, _, _) in _caracteristicas)
                      _Caracteristica(icono: icono, texto: texto),
                    const SizedBox(height: 32),
                    ..._accesos(context, ref),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ícono, texto del celular, título y detalle de la web (mockup).
  static const _caracteristicas = [
    (
      Icons.calculate_outlined,
      'Paneles, batería, costos y retorno de inversión',
      'Dimensionamiento y costos',
      'Paneles, batería, inversor y retorno de inversión.',
    ),
    (
      Icons.battery_charging_full_outlined,
      'Salud de la batería a 10 años',
      'Salud de la batería a 10 años',
      'Compara el uso consciente con el convencional.',
    ),
    (
      Icons.cloud_done_outlined,
      'Tus cálculos guardados en la nube',
      'Todo guardado en la nube',
      'Vuelve a tus cálculos desde la web o el celular.',
    ),
  ];

  List<Widget> _titulo(BuildContext context, {bool web = false}) {
    final tema = Theme.of(context);
    return [
      Text(
        'Bienvenido a Solarix',
        style: web
            ? tema.textTheme.headlineSmall
            : tema.textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        web
            ? 'Inicia sesión para guardar tus cálculos y simulaciones.'
            : 'Calcula el sistema solar que necesita tu casa y simula cómo '
                  'se desgasta su batería con los años.',
        style: web ? tema.textTheme.bodyMedium : tema.textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    ];
  }

  /// Los tres accesos y el enlace a la política de datos. Sin "al continuar
  /// aceptas": la autorización expresa (Ley 1581) se da con la casilla del
  /// registro, y probar sin cuenta no recoge datos personales.
  List<Widget> _accesos(BuildContext context, WidgetRef ref) => [
    FilledButton(
      onPressed: () => context.go(Rutas.login),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: const Text('Iniciar sesión'),
    ),
    const SizedBox(height: 12),
    OutlinedButton(
      onPressed: () => context.go(Rutas.registro),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: const Text('Crear cuenta'),
    ),
    const SizedBox(height: 4),
    // La cuenta solo hace falta para guardar (Etapa 12).
    TextButton(
      onPressed: () {
        ref.read(modoInvitadoProvider.notifier).entrar();
        context.go(Rutas.inicio);
      },
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: const Text('Probar sin cuenta'),
    ),
    const SizedBox(height: 8),
    Center(
      child: TextButton(
        onPressed: () => context.push(Rutas.politicaDatos),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        child: const Text('Política de tratamiento de datos (Ley 1581)'),
      ),
    ),
  ];

  Widget _vistaWeb(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final colores = ColoresSolarix.of(context);
    return Scaffold(
      body: Row(
        children: [
          // Izquierda: presentación sobre ámbar suave.
          Expanded(
            child: Container(
              color: colores.solarSuave,
              padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 48),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SolSolarix(tamano: 36),
                            const SizedBox(width: 10),
                            Text(
                              'Solarix',
                              style: tema.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Energía solar a la medida de tu casa',
                          style: tema.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Calcula cuántos paneles necesitas, cuánto cuestan '
                          'y en cuánto tiempo recuperas la inversión. Luego '
                          'simula cómo se desgasta tu batería con los años.',
                          style: tema.textTheme.bodyLarge?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (final (icono, _, titulo, detalle)
                            in _caracteristicas)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      tema.colorScheme.surfaceContainerLowest,
                                  child: Icon(
                                    icono,
                                    color: tema.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titulo,
                                        style: tema.textTheme.titleMedium,
                                      ),
                                      Text(
                                        detalle,
                                        style: TextStyle(
                                          color:
                                              tema.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Derecha: tarjeta de acceso (las dos mitades iguales, mockup).
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 440,
                  child: _AparicionSuave(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SolEnCirculo(tamano: 96),
                            const SizedBox(height: 20),
                            ..._titulo(context, web: true),
                            const SizedBox(height: 28),
                            ..._accesos(context, ref),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El sol de Solarix sobre un círculo de ámbar suave.
class _SolEnCirculo extends StatelessWidget {
  const _SolEnCirculo({this.tamano = 136});

  final double tamano;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColoresSolarix.of(context).solarSuave,
        shape: BoxShape.circle,
      ),
      child: SolSolarix(tamano: tamano * 0.53),
    ),
  );
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
