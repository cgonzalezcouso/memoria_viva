import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';
import '../../config/supabase_config.dart';
import 'auth_providers.dart';

class SupabaseSettingsState {
  const SupabaseSettingsState({
    required this.url,
    required this.anonKey,
    required this.isLockedByBuild,
    required this.isConfigured,
  });

  final String url;
  final String anonKey;
  final bool isLockedByBuild;
  final bool isConfigured;

  SupabaseSettingsState copyWith({
    String? url,
    String? anonKey,
  }) {
    return SupabaseSettingsState(
      url: url ?? this.url,
      anonKey: anonKey ?? this.anonKey,
      isLockedByBuild: isLockedByBuild,
      isConfigured: isConfigured,
    );
  }
}

final supabaseSettingsProvider =
    AsyncNotifierProvider<SupabaseSettingsController, SupabaseSettingsState>(
  SupabaseSettingsController.new,
);

class SupabaseSettingsController extends AsyncNotifier<SupabaseSettingsState> {
  @override
  Future<SupabaseSettingsState> build() async {
    await Env.loadStoredConfig();
    return _currentState();
  }

  SupabaseSettingsState _currentState() {
    return SupabaseSettingsState(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      isLockedByBuild: Env.isSupabaseLockedByBuild,
      isConfigured: Env.isSupabaseConfigured,
    );
  }

  Future<String?> save({
    required String url,
    required String anonKey,
  }) async {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();

    if (trimmedUrl.isEmpty || trimmedKey.isEmpty) {
      return 'Indica la URL y la clave anónima de Supabase.';
    }

    if (!trimmedUrl.startsWith('https://')) {
      return 'La URL debe empezar por https://';
    }

    try {
      await Env.saveSupabaseConfig(url: trimmedUrl, anonKey: trimmedKey);
    } catch (error) {
      return '$error';
    }

    state = AsyncData(_currentState());

    bool isSupabaseInitialized = false;
    try {
      isSupabaseInitialized = Supabase.instance.isInitialized;
    } catch (_) {}

    if (isSupabaseInitialized) {
      ref.invalidate(authControllerProvider);
      ref.read(routerRefreshProvider).notify();
      return 'Credenciales guardadas. Reinicia la app para aplicar los cambios.';
    }

    try {
      await SupabaseConfig.initializeAfterSave();
    } catch (error) {
      return 'No se pudo conectar: $error';
    }

    ref.invalidate(authControllerProvider);
    ref.read(routerRefreshProvider).notify();
    return null;
  }

  Future<String?> clearStoredConfig() async {
    try {
      await Env.clearStoredSupabaseConfig();
    } catch (error) {
      return '$error';
    }

    state = AsyncData(_currentState());
    ref.invalidate(authControllerProvider);
    ref.read(routerRefreshProvider).notify();

    bool isSupabaseInitializedClear = false;
    try {
      isSupabaseInitializedClear = Supabase.instance.isInitialized;
    } catch (_) {}

    if (isSupabaseInitializedClear) {
      return 'Datos borrados. Reinicia la app para volver al modo local.';
    }

    return null;
  }
}
