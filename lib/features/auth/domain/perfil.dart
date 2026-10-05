/// Fila de la tabla `perfiles`.
///
/// La ciudad se elige de la lista de la calculadora (`ciudadesBase`) y es el
/// lugar por defecto de la calculadora y de la simulación (Etapa 12).
class Perfil {
  const Perfil({required this.id, this.nombre, this.ciudad});

  factory Perfil.desdeMapa(Map<String, dynamic> fila) => Perfil(
    id: fila['id'] as String,
    nombre: fila['nombre'] as String?,
    ciudad: fila['ciudad'] as String?,
  );

  final String id;
  final String? nombre;
  final String? ciudad;

  /// Columnas editables, listas para un `update` en Supabase.
  Map<String, dynamic> aMapaEditable() => {'nombre': nombre, 'ciudad': ciudad};
}
