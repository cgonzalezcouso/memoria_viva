import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_defaults.dart';

/// Credenciales de Supabase.
///
/// Prioridad: `--dart-define` > valores guardados en el dispositivo > valores
/// integrados en [SupabaseDefaults].
abstract final class Env {
  static const _defineUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const _defineAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const _urlKey = 'supabase_url';
  static const _anonKeyKey = 'supabase_anon_key';

  static String _storedUrl = '';
  static String _storedAnonKey = '';

  static String get supabaseUrl {
    if (_defineUrl.isNotEmpty) return _defineUrl;
    if (_storedUrl.isNotEmpty) return _storedUrl;
    return SupabaseDefaults.url;
  }

  static String get supabaseAnonKey {
    if (_defineAnonKey.isNotEmpty) return _defineAnonKey;
    if (_storedAnonKey.isNotEmpty) return _storedAnonKey;
    return SupabaseDefaults.anonKey;
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Supabase viene fijado al compilar o integrado en la app.
  static bool get isSupabaseLockedByBuild =>
      _defineUrl.isNotEmpty ||
      _defineAnonKey.isNotEmpty ||
      SupabaseDefaults.hasConfig;

  static bool get usesStoredSupabaseConfig =>
      !isSupabaseLockedByBuild && _storedUrl.isNotEmpty;

  static Future<void> loadStoredConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _storedUrl = prefs.getString(_urlKey) ?? '';
    _storedAnonKey = prefs.getString(_anonKeyKey) ?? '';
  }

  static Future<void> persistBuildDefinesIfNeeded() async {
    if (_defineUrl.isEmpty || _defineAnonKey.isEmpty) return;
    if (_storedUrl.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, _defineUrl);
    await prefs.setString(_anonKeyKey, _defineAnonKey);
    _storedUrl = _defineUrl;
    _storedAnonKey = _defineAnonKey;
  }

  static Future<void> saveSupabaseConfig({
    required String url,
    required String anonKey,
  }) async {
    if (isSupabaseLockedByBuild) {
      throw StateError('Supabase ya está configurado en la aplicación.');
    }

    final normalizedUrl = url.trim();
    final normalizedKey = anonKey.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, normalizedUrl);
    await prefs.setString(_anonKeyKey, normalizedKey);
    _storedUrl = normalizedUrl;
    _storedAnonKey = normalizedKey;
  }

  static Future<void> clearStoredSupabaseConfig() async {
    if (isSupabaseLockedByBuild) {
      throw StateError('Supabase ya está configurado en la aplicación.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await prefs.remove(_anonKeyKey);
    _storedUrl = '';
    _storedAnonKey = '';
  }
}
