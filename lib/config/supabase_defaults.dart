/// Credenciales del proyecto Supabase de Memoria Viva.
///
/// La clave anon es pública (va en apps cliente). No incluir aquí la service_role.
abstract final class SupabaseDefaults {
  static const url = 'https://lstevooxegofrvlurosn.supabase.co';

  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzdGV2b294ZWdvZnJ2bHVyb3NuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNjQxNjksImV4cCI6MjA5NTc0MDE2OX0.'
      'UjDP2PnYongGre4LbRoFOn2kllRuWGmjJpIXz2PWX2A';

  static bool get hasConfig => url.isNotEmpty && anonKey.isNotEmpty;
}
