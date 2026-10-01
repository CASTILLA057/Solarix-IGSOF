/// Nivel de irradiancia por defecto del usuario (columna `zona_irradiancia`).
///
/// Las mismas tres categorías del modelo de NetLogo; en la Etapa 3 se suma
/// la tabla de ciudades con sus horas solares pico.
enum ZonaIrradiancia {
  baja('Baja (selva / nublado)'),
  media('Media (zona andina)'),
  alta('Alta (costa / llanos)');

  const ZonaIrradiancia(this.etiqueta);

  final String etiqueta;

  static ZonaIrradiancia? desdeTexto(String? valor) {
    for (final zona in values) {
      if (zona.name == valor) return zona;
    }
    return null;
  }
}

/// Fila de la tabla `perfiles`.
class Perfil {
  const Perfil({
    required this.id,
    this.nombre,
    this.ciudad,
    this.zonaIrradiancia,
  });

  factory Perfil.desdeMapa(Map<String, dynamic> fila) => Perfil(
    id: fila['id'] as String,
    nombre: fila['nombre'] as String?,
    ciudad: fila['ciudad'] as String?,
    zonaIrradiancia: ZonaIrradiancia.desdeTexto(
      fila['zona_irradiancia'] as String?,
    ),
  );

  final String id;
  final String? nombre;
  final String? ciudad;
  final ZonaIrradiancia? zonaIrradiancia;

  /// Columnas editables, listas para un `update` en Supabase.
  Map<String, dynamic> aMapaEditable() => {
    'nombre': nombre,
    'ciudad': ciudad,
    'zona_irradiancia': zonaIrradiancia?.name,
  };
}
