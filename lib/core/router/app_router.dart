import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/bienvenida_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/perfil_screen.dart';
import '../../features/auth/presentation/recuperar_screen.dart';
import '../../features/auth/presentation/registro_screen.dart';
import '../../features/auth/presentation/verificar_correo_screen.dart';
import '../../features/dashboard/presentation/inicio_screen.dart';
import 'rutas.dart';

/// Router de la app: protege las rutas según haya o no sesión (ver
/// [redirigir]) y se reevalúa cada vez que cambia la sesión.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresco = _RefrescoSesion(auth.cambiosDeSesion);
  final router = GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: refresco,
    redirect: (context, state) => redirigir(
      autenticado: auth.usuarioActual != null,
      ubicacion: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const InicioScreen(),
        routes: [
          GoRoute(
            path: Rutas.perfil.substring(1),
            builder: (context, state) => const PerfilScreen(),
          ),
        ],
      ),
      // Pantallas de acceso como hijas de la bienvenida: "atrás" vuelve a ella.
      GoRoute(
        path: Rutas.bienvenida,
        builder: (context, state) => const BienvenidaScreen(),
        routes: [
          GoRoute(
            path: _subruta(Rutas.login),
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: _subruta(Rutas.registro),
            builder: (context, state) => const RegistroScreen(),
          ),
          GoRoute(
            path: _subruta(Rutas.verificar),
            builder: (context, state) => VerificarCorreoScreen(
              email: state.uri.queryParameters['email'] ?? '',
            ),
          ),
          GoRoute(
            path: _subruta(Rutas.recuperar),
            builder: (context, state) => const RecuperarScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresco.dispose();
  });
  return router;
});

/// Último segmento de una ruta, para declararla como hija (`/a/b` → `b`).
String _subruta(String ruta) => ruta.substring(ruta.lastIndexOf('/') + 1);

/// Avisa al router cada vez que cambia la sesión.
class _RefrescoSesion extends ChangeNotifier {
  _RefrescoSesion(Stream<Object?> cambios) {
    _suscripcion = cambios.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _suscripcion;

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
