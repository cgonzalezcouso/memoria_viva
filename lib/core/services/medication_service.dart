import 'package:uuid/uuid.dart';

import '../constants/patient_ids.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../models/medication.dart';
import 'local_care_storage.dart';

class MedicationService {
  MedicationService(this._storage);

  final LocalCareStorage _storage;
  static const _uuid = Uuid();

  static const _defaultMedications = [
    (name: 'Medicamento matutino', time: '09:00', instructions: 'Tomar con un vaso de agua después del desayuno.'),
    (name: 'Medicamento vespertino', time: '20:00', instructions: 'Tomar después de la cena.'),
  ];

  Future<List<Medication>> fetchMedications({required String patientId}) async {
    if (patientId == PatientIds.unlinked) return const [];

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final stored = await _storage.loadMedications(PatientIds.local);
      if (stored.isNotEmpty) return stored.where((med) => med.active).toList();

      return _defaultMedications
          .asMap()
          .entries
          .map(
            (entry) => Medication(
              id: 'local-med-${entry.key}',
              patientId: PatientIds.local,
              name: entry.value.name,
              scheduledTime: entry.value.time,
              instructions: entry.value.instructions,
            ),
          )
          .toList();
    }

    try {
      final response = await SupabaseConfig.client
          .from('medications')
          .select()
          .eq('patient_id', patientId)
          .eq('active', true)
          .order('scheduled_time');

      return (response as List)
          .map((item) => Medication.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Medication>> fetchAllMedications({required String patientId}) async {
    if (patientId == PatientIds.unlinked) return const [];

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final stored = await _storage.loadMedications(PatientIds.local);
      if (stored.isNotEmpty) return stored;

      return fetchMedications(patientId: patientId);
    }

    try {
      final response = await SupabaseConfig.client
          .from('medications')
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_time');

      return (response as List)
          .map((item) => Medication.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Medication> addMedication({
    required String patientId,
    required String name,
    required String scheduledTime,
    String? instructions,
  }) async {
    final medication = Medication(
      id: _uuid.v4(),
      patientId: patientId,
      name: name.trim(),
      scheduledTime: scheduledTime,
      instructions: instructions?.trim(),
    );

    if (patientId == PatientIds.unlinked) {
      throw StateError('Vincula una persona antes de añadir medicación.');
    }

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final localMedication = Medication(
        id: medication.id,
        patientId: PatientIds.local,
        name: medication.name,
        scheduledTime: medication.scheduledTime,
        instructions: medication.instructions,
      );
      final all = await fetchAllMedications(patientId: PatientIds.local);
      await _storage.saveMedications(
        PatientIds.local,
        [...all, localMedication],
      );
      return localMedication;
    }

    final response = await SupabaseConfig.client
        .from('medications')
        .insert(medication.toInsertJson())
        .select()
        .single();

    return Medication.fromJson(response);
  }

  Future<void> updateMedication(Medication medication) async {
    if (medication.patientId == PatientIds.unlinked) return;

    if (!Env.isSupabaseConfigured || medication.patientId == PatientIds.local) {
      final all = await fetchAllMedications(patientId: PatientIds.local);
      final updated = all
          .map((med) => med.id == medication.id ? medication : med)
          .toList();
      await _storage.saveMedications(PatientIds.local, updated);
      return;
    }

    await SupabaseConfig.client
        .from('medications')
        .update(medication.toUpdateJson())
        .eq('id', medication.id);
  }

  Future<void> deleteMedication(Medication medication) async {
    if (medication.patientId == PatientIds.unlinked) return;

    if (!Env.isSupabaseConfigured || medication.patientId == PatientIds.local) {
      final all = await fetchAllMedications(patientId: PatientIds.local);
      final updated = all.where((med) => med.id != medication.id).toList();
      await _storage.saveMedications(PatientIds.local, updated);
      return;
    }

    await SupabaseConfig.client
        .from('medications')
        .update({'active': false})
        .eq('id', medication.id);
  }
}
