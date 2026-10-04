import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/theme/tema_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sin env.json la app arranca igual (útil para CI y pruebas de UI),
  // pero sin backend.
  if (Env.supabaseConfigurado) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  // Preferencias locales (modo claro/oscuro). Si fallan, tema del sistema.
  SharedPreferences? preferencias;
  try {
    preferencias = await SharedPreferences.getInstance();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [preferenciasProvider.overrideWithValue(preferencias)],
      child: const SolarixApp(),
    ),
  );
}
