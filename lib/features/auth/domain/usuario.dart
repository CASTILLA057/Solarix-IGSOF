/// Usuario autenticado, independiente del tipo `User` de Supabase.
class Usuario {
  const Usuario({required this.id, required this.email, this.versionPolitica});

  final String id;
  final String email;

  /// Versión de la política de datos que aceptó (metadatos de la cuenta);
  /// `null` si no consta.
  final String? versionPolitica;

  @override
  bool operator ==(Object other) =>
      other is Usuario &&
      other.id == id &&
      other.email == email &&
      other.versionPolitica == versionPolitica;

  @override
  int get hashCode => Object.hash(id, email, versionPolitica);
}
