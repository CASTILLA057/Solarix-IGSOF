import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/errors/mensajes_error.dart';
import '../../../core/errors/traducir_error.dart';
import '../domain/perfil.dart';

/// Lectura y edición del perfil del usuario (tabla `perfiles`, protegida
/// por RLS: cada usuario solo accede a su propia fila).
abstract interface class PerfilRepository {
  Future<Perfil> obtener(String usuarioId);
  Future<void> guardar(Perfil perfil);
}

class SupabasePerfilRepository implements PerfilRepository {
  SupabasePerfilRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<Perfil> obtener(String usuarioId) async {
    try {
      final fila = await _db
          .from('perfiles')
          .select('id, nombre, ciudad, zona_irradiancia')
          .eq('id', usuarioId)
          .maybeSingle();
      // El trigger crea la fila al registrarse; si faltara, perfil vacío.
      return fila == null ? Perfil(id: usuarioId) : Perfil.desdeMapa(fila);
    } catch (e) {
      throw errorDesde(e, accion: 'cargar tu perfil');
    }
  }

  @override
  Future<void> guardar(Perfil perfil) async {
    try {
      await _db
          .from('perfiles')
          .update({
            ...perfil.aMapaEditable(),
            'actualizado_en': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', perfil.id);
    } catch (e) {
      throw errorDesde(e, accion: 'guardar tu perfil');
    }
  }
}

class SinBackendPerfilRepository implements PerfilRepository {
  const SinBackendPerfilRepository();

  @override
  Future<Perfil> obtener(String usuarioId) =>
      Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));

  @override
  Future<void> guardar(Perfil perfil) =>
      Future.error(ErrorApp(mensajeErrorAuth(CodigosError.sinBackend)));
}
