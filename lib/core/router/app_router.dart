import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/inicio_screen.dart';

/// Rutas de la app. En la Etapa 2 se agregan login/registro y la
/// redirección según la sesión de Supabase.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: InicioScreen.ruta,
    routes: [
      GoRoute(
        path: InicioScreen.ruta,
        builder: (context, state) => const InicioScreen(),
      ),
    ],
  );
});
