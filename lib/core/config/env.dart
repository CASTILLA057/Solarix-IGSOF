/// Variables de entorno inyectadas en compilación con
/// `flutter run --dart-define-from-file=env.json`.
///
/// Ver `env.example.json` para la plantilla. `env.json` no se sube al repo.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clave pública (`sb_publishable_...`). Es segura en el cliente porque
  /// el acceso a los datos lo restringe RLS.
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// `true` cuando ambas credenciales de Supabase fueron provistas.
  static bool get supabaseConfigurado =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
