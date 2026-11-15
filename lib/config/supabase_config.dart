import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

abstract final class SupabaseConfig {
  static SupabaseClient? get clientOrNull {
    try {
      if (!Env.isSupabaseConfigured) {
        return null;
      }
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static SupabaseClient get client {
    final existing = clientOrNull;
    if (existing != null) return existing;
    throw StateError('Supabase no está inicializado');
  }

  static Future<void> initialize() async {
    if (!Env.isSupabaseConfigured) {
      return;
    }

    bool isInitialized = false;
    try {
      isInitialized = Supabase.instance.isInitialized;
    } catch (_) {
      // Ignorar: si lanza error de aserción significa que no está inicializado
    }

    if (isInitialized) {
      return;
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  static Future<void> initializeAfterSave() async {
    if (!Env.isSupabaseConfigured) {
      return;
    }

    bool isInitialized = false;
    try {
      isInitialized = Supabase.instance.isInitialized;
    } catch (_) {
      // Ignorar
    }

    if (isInitialized) {
      return;
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }
}
