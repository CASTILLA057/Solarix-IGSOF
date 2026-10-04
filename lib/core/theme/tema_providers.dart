import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias del dispositivo; `main` las carga al arrancar. En pruebas
/// queda nulo y el tema no se guarda.
final preferenciasProvider = Provider<SharedPreferences?>((ref) => null);

/// Modo de tema elegido por el usuario (sistema, claro u oscuro), guardado
/// en el dispositivo.
final modoTemaProvider = NotifierProvider<ModoTema, ThemeMode>(ModoTema.new);

class ModoTema extends Notifier<ThemeMode> {
  static const _clave = 'modo_tema';

  @override
  ThemeMode build() {
    final guardado = ref.watch(preferenciasProvider)?.getString(_clave);
    return ThemeMode.values.firstWhere(
      (m) => m.name == guardado,
      orElse: () => ThemeMode.system,
    );
  }

  void cambiar(ThemeMode modo) {
    state = modo;
    ref.read(preferenciasProvider)?.setString(_clave, modo.name);
  }
}
