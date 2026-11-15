import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../config/env.dart';
import '../../features/auth/auth_error_message.dart';
import '../constants/patient_ids.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

final selectedPatientIdProvider = NotifierProvider<SelectedPatientNotifier, String?>(
  SelectedPatientNotifier.new,
);

final activePatientIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null || auth.isGuest) return PatientIds.local;

  final profile = auth.profile;
  if (profile == null) return PatientIds.local;

  if (profile.role == UserRole.patient) {
    return profile.id;
  }

  final selected = ref.watch(selectedPatientIdProvider);
  if (selected != null) return selected;

  final linked = ref.watch(linkedPatientsProvider).value;
  if (linked != null && linked.isNotEmpty) {
    return linked.first.id;
  }

  return PatientIds.unlinked;
});

final hasLinkedPatientProvider = Provider<bool>((ref) {
  final patientId = ref.watch(activePatientIdProvider);
  return PatientIds.canSyncToSupabase(patientId);
});

final linkedPatientsProvider = FutureProvider<List<UserProfile>>((ref) async {
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null || auth.isGuest || auth.profile == null) {
    return const [];
  }

  if (auth.profile!.role != UserRole.caregiver) {
    return const [];
  }

  return ref.read(authServiceProvider).fetchLinkedPatients(auth.profile!.id);
});

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    if (!Env.isSupabaseConfigured) {
      return const AuthState(isGuest: true);
    }

    final authService = ref.read(authServiceProvider);
    final refresh = ref.read(routerRefreshProvider);

    bool isFirstEvent = true;
    final subscription = authService.authStateChanges.listen((_) {
      if (isFirstEvent) {
        isFirstEvent = false;
        return;
      }
      refresh.notify();
      ref.invalidateSelf();
    });
    ref.onDispose(subscription.cancel);

    final session = authService.currentSession;
    if (session == null) {
      return const AuthState();
    }

    try {
      final profile = await authService
          .ensureProfile(session.user.id)
          .timeout(const Duration(seconds: 10));
      return AuthState(session: session, profile: profile);
    } catch (_) {
      return AuthState(session: session);
    }
  }

  Future<String?> ensureProfileLoaded() async {
    final session =
        state.value?.session ?? ref.read(authServiceProvider).currentSession;
    if (session == null) return null;

    try {
      final profile = await ref
          .read(authServiceProvider)
          .ensureProfile(session.user.id)
          .timeout(const Duration(seconds: 12));
      if (profile == null) {
        return 'No se pudo recuperar el perfil. Aplica las migraciones '
            'de Supabase o cierra sesión e inténtalo de nuevo.';
      }

      state = AsyncData(AuthState(session: session, profile: profile));
      ref.read(routerRefreshProvider).notify();
      return null;
    } on TimeoutException {
      return 'Sin respuesta del servidor. Comprueba tu conexión a internet '
          'y vuelve a intentarlo.';
    } on PostgrestException catch (error) {
      return authErrorMessage(error);
    } catch (error) {
      return authErrorMessage(error);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(authServiceProvider).signIn(
            email: email,
            password: password,
          );
      final session = ref.read(authServiceProvider).currentSession;
      ref.read(selectedPatientIdProvider.notifier).clear();
      return AuthState(session: session, profile: profile);
    });
    ref.read(routerRefreshProvider).notify();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(authServiceProvider).signUp(
            email: email,
            password: password,
            fullName: fullName,
            role: role,
          );
      final session = ref.read(authServiceProvider).currentSession;
      return AuthState(session: session, profile: profile);
    });
    ref.read(routerRefreshProvider).notify();
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    ref.read(selectedPatientIdProvider.notifier).clear();
    state = const AsyncData(AuthState());
    ref.read(routerRefreshProvider).notify();
  }

  Future<void> linkPatient(String patientId) async {
    final auth = state.value;
    final caregiverId = auth?.profile?.id;
    if (caregiverId == null) return;

    await ref.read(authServiceProvider).linkPatient(
          caregiverId: caregiverId,
          patientId: patientId.trim(),
        );
    ref.invalidate(linkedPatientsProvider);
  }
}

class SelectedPatientNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? patientId) => state = patientId;

  void clear() => state = null;
}

class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
