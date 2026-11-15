import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase_config.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

/// Inicialización en segundo plano (Supabase, notificaciones).
/// No bloquea el primer frame de la app.
final appStartupProvider = FutureProvider<void>((ref) async {
  try {
    await SupabaseConfig.initialize().timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw TimeoutException('Supabase tardó demasiado en conectar');
      },
    );
  } catch (error, stackTrace) {
    debugPrint('Supabase no se pudo inicializar: $error\n$stackTrace');
  }

  try {
    await ref.read(notificationServiceProvider).initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Notificaciones tardaron demasiado');
          },
        );
  } catch (error, stackTrace) {
    debugPrint('Notificaciones no inicializadas: $error\n$stackTrace');
  }

  ref.invalidate(authControllerProvider);
});
