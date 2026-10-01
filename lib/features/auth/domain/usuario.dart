/// Usuario autenticado, independiente del tipo `User` de Supabase.
class Usuario {
  const Usuario({required this.id, required this.email});

  final String id;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is Usuario && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
