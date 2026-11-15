/// Identificadores usados como `patientId` en servicios y providers.
abstract final class PatientIds {
  static const local = 'local-user';
  static const unlinked = 'unlinked-caregiver';

  static bool usesLocalStorage(String patientId) =>
      patientId == local || patientId == unlinked;

  static bool canSyncToSupabase(String patientId) =>
      patientId != local && patientId != unlinked;
}
