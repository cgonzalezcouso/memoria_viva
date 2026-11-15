import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  SupabaseClient? get _client => SupabaseConfig.clientOrNull;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange.map((event) {
      return AuthState(session: event.session);
    });
  }

  Session? get currentSession => _client?.auth.currentSession;

  Future<UserProfile?> fetchProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } on PostgrestException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  UserProfile? _profileFromRpcResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      return UserProfile.fromJson(response);
    }
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return UserProfile.fromJson(first);
      }
    }
    return null;
  }

  /// Obtiene el perfil o lo crea a partir de los metadatos de registro si falta.
  Future<UserProfile?> ensureProfile(String userId) async {
    final existing = await fetchProfile(userId);
    if (existing != null) return existing;

    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || user.id != userId) return null;

    try {
      final response = await client.rpc('ensure_my_profile');
      final fromRpc = _profileFromRpcResponse(response);
      if (fromRpc != null) return fromRpc;
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202') {
        rethrow;
      }
      // RPC no desplegada: continuar con inserción desde el cliente.
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final rawName = (metadata['full_name'] as String?)?.trim();
    final fullName = rawName != null && rawName.isNotEmpty
        ? rawName
        : (user.email?.split('@').first ?? 'Usuario');
    final role = UserRole.fromValue(metadata['role'] as String? ?? 'persona');

    final profile = UserProfile(
      id: userId,
      fullName: fullName,
      role: role,
      createdAt: DateTime.now(),
    );

    try {
      await client.from('profiles').insert(profile.toInsertJson());
      return profile;
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        return fetchProfile(userId);
      }
      rethrow;
    }
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final client = _client;
    if (client == null) {
      throw AuthFailure('Supabase no está configurado.');
    }

    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'role': role.value,
      },
    );

    final user = response.user;
    if (user == null) {
      throw AuthFailure('No se pudo crear la cuenta.');
    }

    final profile = UserProfile(
      id: user.id,
      fullName: fullName.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    try {
      await client.from('profiles').insert(profile.toInsertJson());
    } catch (_) {
      // El trigger puede haber creado el perfil antes que el cliente.
    }

    final ensured = await ensureProfile(user.id);
    if (ensured != null) return ensured;

    return profile;
  }

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw AuthFailure('Supabase no está configurado.');
    }

    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthFailure('No se pudo iniciar sesión.');
    }

    final profile = await ensureProfile(userId);
    if (profile == null) {
      throw AuthFailure(
        'No se pudo cargar tu perfil. Cierra sesión e inténtalo de nuevo.',
      );
    }

    return profile;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sin red el servidor no responde; limpiamos la sesión local igual.
      await client.auth.signOut(scope: SignOutScope.local);
    }
  }

  Future<void> linkPatient({
    required String caregiverId,
    required String patientId,
  }) async {
    final client = _client;
    if (client == null) {
      throw AuthFailure('Supabase no está configurado.');
    }

    if (caregiverId == patientId) {
      throw AuthFailure('No puedes vincularte contigo mismo.');
    }

    final patient = await client
        .from('profiles')
        .select('id, role')
        .eq('id', patientId)
        .maybeSingle();

    if (patient == null) {
      throw AuthFailure('No se encontró una persona con ese código.');
    }

    if (patient['role'] != UserRole.patient.value) {
      throw AuthFailure('El código pertenece a un cuidador, no a una persona.');
    }

    try {
      await client.from('patient_caregiver_links').insert({
        'patient_id': patientId,
        'caregiver_id': caregiverId,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw AuthFailure('Esta persona ya está vinculada.');
      }
      rethrow;
    }
  }

  Future<List<UserProfile>> fetchLinkedPatients(String caregiverId) async {
    final client = _client;
    if (client == null) return const [];

    try {
      print('--- fetchLinkedPatients: caregiverId=$caregiverId ---');
      final links = await client
          .from('patient_caregiver_links')
          .select('patient_id')
          .eq('caregiver_id', caregiverId);

      print('links query result: $links');

      final patientIds = (links as List)
          .map((link) => link['patient_id'] as String)
          .toList();

      print('patientIds: $patientIds');
      if (patientIds.isEmpty) return const [];

      final profiles = await client
          .from('profiles')
          .select()
          .inFilter('id', patientIds);

      print('profiles query result: $profiles');

      return (profiles as List)
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      print('Error in fetchLinkedPatients: $e\n$stack');
      rethrow;
    }
  }
}

class AuthState {
  const AuthState({
    this.session,
    this.profile,
    this.isGuest = false,
  });

  final Session? session;
  final UserProfile? profile;
  final bool isGuest;

  bool get isAuthenticated => isGuest || session != null;

  bool get needsProfile => session != null && profile == null;

  UserRole? get role => profile?.role;

  String? get userId => profile?.id ?? session?.user.id;
}
