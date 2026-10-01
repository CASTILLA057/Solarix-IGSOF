import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../data/auth_repository.dart';
import '../data/perfil_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/perfil.dart';
import '../domain/usuario.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!Env.supabaseConfigurado) return const SinBackendAuthRepository();
  return SupabaseAuthRepository(Supabase.instance.client.auth);
});

final perfilRepositoryProvider = Provider<PerfilRepository>((ref) {
  if (!Env.supabaseConfigurado) return const SinBackendPerfilRepository();
  return SupabasePerfilRepository(Supabase.instance.client);
});

/// Usuario con sesión activa, o `null` si no hay sesión.
final sesionProvider = StreamProvider<Usuario?>(
  (ref) => ref.watch(authRepositoryProvider).cambiosDeSesion,
);

/// Perfil del usuario con sesión activa.
final perfilProvider = FutureProvider.autoDispose<Perfil>((ref) async {
  final usuario = await ref.watch(sesionProvider.future);
  if (usuario == null) throw StateError('No hay sesión activa.');
  return ref.watch(perfilRepositoryProvider).obtener(usuario.id);
});
