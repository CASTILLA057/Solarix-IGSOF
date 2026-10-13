import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../router/rutas.dart';
import '../theme/app_theme.dart';
import 'navegacion.dart';
import 'sol_solarix.dart';
import 'solarix_ui.dart';

/// Barra superior del diseño web (Etapa 13, mockup): logo, enlaces a las
/// secciones y usuario. Reemplaza al `AppBar` cuando [esAncho].
class BarraWeb extends ConsumerWidget implements PreferredSizeWidget {
  const BarraWeb({super.key, this.antesDeSalir});

  /// Para pantallas con resultados sin guardar (igual que `BotonInicio`).
  final AntesDeSalir? antesDeSalir;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final colores = ColoresSolarix.of(context);
    final ubicacion = GoRouterState.of(context).matchedLocation;
    final haySesion = ref.watch(haySesionProvider);
    final nombre = haySesion ? ref.watch(perfilProvider).value?.nombre : null;

    Future<void> ir(String ruta) async {
      if (antesDeSalir != null && !await antesDeSalir!()) return;
      if (context.mounted) context.go(ruta);
    }

    Widget enlace(String texto, IconData icono, String ruta) {
      final activo = ruta == Rutas.inicio
          ? ubicacion == ruta
          : ubicacion.startsWith(ruta);
      return Tooltip(
        // El mismo tooltip del ícono de casa del celular (no hace falta
        // estando en el inicio).
        message: ruta == Rutas.inicio && !activo ? 'Ir al inicio' : texto,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: TextButton.icon(
            onPressed: () => ir(ruta),
            style: TextButton.styleFrom(
              foregroundColor: activo
                  ? tema.colorScheme.primary
                  : tema.colorScheme.onSurfaceVariant,
              backgroundColor: activo ? colores.solarSuave : null,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(icono, size: 18),
            label: Text(
              texto,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Material(
      color: tema.colorScheme.surfaceContainerLowest,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: tema.colorScheme.outlineVariant),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoMaximoWeb),
            child: Row(
              children: [
                InkWell(
                  onTap: () => ir(Rutas.inicio),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        const SolSolarix(tamano: 30),
                        const SizedBox(width: 10),
                        Text(
                          'Solarix',
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Los enlaces se achican si la ventana es justa (900 a
                // ~1.200 px) en vez de desbordar.
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          enlace('Inicio', Icons.home_outlined, Rutas.inicio),
                          enlace(
                            'Calculadora',
                            Icons.calculate_outlined,
                            Rutas.calculadora,
                          ),
                          enlace(
                            'Simulación',
                            Icons.battery_charging_full_outlined,
                            Rutas.simulacion,
                          ),
                          if (haySesion)
                            enlace('Historial', Icons.history, Rutas.historial),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (!haySesion)
                  FilledButton(
                    onPressed: () => ir(Rutas.login),
                    child: const Text('Iniciar sesión'),
                  )
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
  const _ChipUsuario({
    required this.nombre,
    required this.activo,
    required this.onTap,
  });

  final String nombre;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = ColoresSolarix.of(context);
    final primerNombre = nombre.trim().split(' ').first;
    return Tooltip(
      message: 'Mi perfil',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: activo ? colores.solarSuave : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              AvatarIniciales(nombre: nombre, tamano: 36),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  primerNombre.isEmpty ? 'Mi perfil' : primerNombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo ámbar con las iniciales ("SC"). Se usa en la barra web y en el
/// perfil.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.nombre, this.tamano = 88});

  final String nombre;
  final double tamano;

  /// Iniciales del nombre y el primer apellido; "?" sin nombre.
  static String iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    return (partes.first[0] + (partes.length > 1 ? partes[1][0] : ''))
        .toUpperCase();
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
      child: Text(
        iniciales(nombre),
        style: TextStyle(
          fontSize: tamano * 0.3,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
