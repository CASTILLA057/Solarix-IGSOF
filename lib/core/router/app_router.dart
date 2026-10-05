import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/bienvenida_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/perfil_screen.dart';
import '../../features/auth/presentation/politica_datos_screen.dart';
import '../../features/auth/presentation/recuperar_screen.dart';
import '../../features/auth/presentation/registro_screen.dart';
import '../../features/auth/presentation/verificar_correo_screen.dart';
import '../../features/calculadora/domain/modelos.dart';
import '../../features/calculadora/presentation/calculadora_screen.dart';
import '../../features/calculadora/presentation/resultados_screen.dart';
import '../../features/dashboard/domain/historial.dart';
import '../../features/dashboard/presentation/detalle_simulacion_screen.dart';
import '../../features/dashboard/presentation/historial_screen.dart';
import '../../features/dashboard/presentation/inicio_screen.dart';
import '../../features/degradacion/domain/comparacion.dart';
import '../../features/degradacion/domain/integracion.dart';
import '../../features/degradacion/presentation/resultados_simulacion_screen.dart';
import '../../features/degradacion/presentation/simulacion_screen.dart';
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
      invitado: ref.read(modoInvitadoProvider),
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
          GoRoute(
            path: Rutas.calculadora.substring(1),
            builder: (context, state) => const CalculadoraScreen(),
            routes: [
              GoRoute(
                path: _subruta(Rutas.resultados),
                // Sin datos (p. ej. al recargar en el navegador) vuelve a la
                // calculadora: los resultados se pasan en memoria.
                redirect: (context, state) =>
                    state.extra is (EntradasCalculo, ResultadoCalculo)
                    ? null
                    : Rutas.calculadora,
                builder: (context, state) {
                  final (entradas, resultado) =
                      state.extra! as (EntradasCalculo, ResultadoCalculo);
                  return ResultadosScreen(
                    entradas: entradas,
                    resultado: resultado,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: Rutas.historial.substring(1),
            builder: (context, state) => const HistorialScreen(),
            routes: [
              GoRoute(
                path: _subruta(Rutas.detalleSimulacion),
                redirect: (context, state) =>
                    state.extra is SimulacionGuardada ? null : Rutas.historial,
                builder: (context, state) => DetalleSimulacionScreen(
                  simulacion: state.extra! as SimulacionGuardada,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Rutas.simulacion.substring(1),
            // Desde la calculadora llega el cálculo de origen (Etapa 6).
            builder: (context, state) => SimulacionScreen(
              origen: state.extra is OrigenCalculo
                  ? state.extra! as OrigenCalculo
                  : null,
            ),
            routes: [
              GoRoute(
                path: _subruta(Rutas.resultadosSimulacion),
                // Igual que en la calculadora: los resultados van en memoria.
                redirect: (context, state) =>
                    state.extra is (ComparacionSimulacion, OrigenCalculo?)
                    ? null
                    : Rutas.simulacion,
                builder: (context, state) {
                  final (comparacion, origen) =
                      state.extra! as (ComparacionSimulacion, OrigenCalculo?);
                  return ResultadosSimulacionScreen(
                    comparacion: comparacion,
                    origen: origen,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      // Política de datos (Ley 1581): con o sin sesión, desde el registro y
      // el perfil.
      GoRoute(
        path: Rutas.politicaDatos,
        builder: (context, state) => const PoliticaDatosScreen(),
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
  // Entrar o salir del modo invitado también cambia qué se puede abrir; al
  // iniciar sesión el modo invitado se apaga.
  ref.listen(modoInvitadoProvider, (_, _) => refresco.avisar());
  ref.listen(sesionProvider, (_, sesion) {
    if (sesion.value != null) ref.read(modoInvitadoProvider.notifier).salir();
  });
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

  void avisar() => notifyListeners();

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
