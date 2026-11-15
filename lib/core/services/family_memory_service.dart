import 'package:uuid/uuid.dart';

import '../constants/patient_ids.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../models/family_memory.dart';
import 'local_care_storage.dart';

class FamilyMemoryService {
  FamilyMemoryService(this._storage);

  final LocalCareStorage _storage;
  static const _uuid = Uuid();

  static const _defaultMemories = [
    (name: 'María', relationship: 'Hija', emoji: '👩'),
    (name: 'Carlos', relationship: 'Nieto', emoji: '👦'),
    (name: 'Ana', relationship: 'Hermana', emoji: '👩‍🦳'),
    (name: 'Pedro', relationship: 'Esposo', emoji: '👨'),
  ];

  Future<List<FamilyMemory>> fetchActiveMemories({
    required String patientId,
  }) async {
    final all = await fetchAllMemories(patientId: patientId);
    return all.where((m) => m.active).toList();
  }

  Future<List<FamilyMemory>> fetchAllMemories({
    required String patientId,
  }) async {
    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final stored = await _storage.loadFamilyMemories(patientId);
      if (stored.isNotEmpty) return stored;

      return _defaultMemories
          .asMap()
          .entries
          .map(
            (entry) => FamilyMemory(
              id: 'local-fm-${entry.key}',
              patientId: patientId,
              displayName: entry.value.name,
              relationship: entry.value.relationship,
              emoji: entry.value.emoji,
            ),
          )
          .toList();
    }

    try {
      final response = await SupabaseConfig.client
          .from('family_memories')
          .select()
          .eq('patient_id', patientId)
          .order('created_at');

      return (response as List)
          .map((item) => FamilyMemory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addMemory({
    required String patientId,
    required String displayName,
    required String relationship,
    required String emoji,
  }) async {
    final memory = FamilyMemory(
      id: _uuid.v4(),
      patientId: patientId,
      displayName: displayName,
      relationship: relationship,
      emoji: emoji,
    );

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final stored = await _storage.loadFamilyMemories(patientId);
      await _storage.saveFamilyMemories(patientId, [...stored, memory]);
      return;
    }

    try {
      await SupabaseConfig.client.from('family_memories').insert(memory.toInsertJson());
    } catch (_) {
      final stored = await _storage.loadFamilyMemories(patientId);
      await _storage.saveFamilyMemories(patientId, [...stored, memory]);
    }
  }

  Future<void> deleteMemory(FamilyMemory memory) async {
    if (!Env.isSupabaseConfigured || memory.patientId == PatientIds.local) {
      final stored = await _storage.loadFamilyMemories(memory.patientId);
      await _storage.saveFamilyMemories(
        memory.patientId,
        stored.where((m) => m.id != memory.id).toList(),
      );
      return;
    }

    try {
      await SupabaseConfig.client
          .from('family_memories')
          .delete()
          .eq('id', memory.id);
    } catch (_) {
      final stored = await _storage.loadFamilyMemories(memory.patientId);
      await _storage.saveFamilyMemories(
        memory.patientId,
        stored.where((m) => m.id != memory.id).toList(),
      );
    }
  }
}
