import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cognitive_session.dart';
import '../models/medication.dart';
import '../models/routine_task.dart';
import '../models/user_role.dart';
import '../models/weekly_cognitive_report.dart';
import '../models/family_memory.dart';
import '../services/cognitive_service.dart';
import '../services/family_memory_service.dart';
import '../services/local_care_storage.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_report_service.dart';
import '../services/routine_service.dart';
import 'auth_providers.dart';

final localCareStorageProvider = Provider<LocalCareStorage>(
  (ref) => LocalCareStorage(),
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(localCareStorageProvider));
});

final userRoleProvider = Provider<UserRole?>((ref) {
  final auth = ref.watch(authControllerProvider).value;
  return auth?.profile?.role;
});

final isCaregiverProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.caregiver;
});

final cognitiveServiceProvider = Provider<CognitiveService>((ref) {
  return CognitiveService(ref.watch(localCareStorageProvider));
});

final routineServiceProvider = Provider<RoutineService>((ref) {
  return RoutineService(ref.watch(localCareStorageProvider));
});

final medicationServiceProvider = Provider<MedicationService>((ref) {
  return MedicationService(ref.watch(localCareStorageProvider));
});

final familyMemoryServiceProvider = Provider<FamilyMemoryService>((ref) {
  return FamilyMemoryService(ref.watch(localCareStorageProvider));
});

final pdfReportServiceProvider = Provider<PdfReportService>(
  (ref) => PdfReportService(),
);

final todayRoutineProvider = FutureProvider<List<RoutineTask>>((ref) async {
  final service = ref.watch(routineServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  return service.fetchTodayTasks(patientId: patientId);
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final service = ref.watch(medicationServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  final medications = await service.fetchMedications(patientId: patientId);

  ref.read(notificationServiceProvider).syncMedicationReminders(medications);

  return medications;
});

final allMedicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final service = ref.watch(medicationServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  return service.fetchAllMedications(patientId: patientId);
});

final familyMemoriesProvider = FutureProvider<List<FamilyMemory>>((ref) async {
  final service = ref.watch(familyMemoryServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  return service.fetchActiveMemories(patientId: patientId);
});

final allFamilyMemoriesProvider = FutureProvider<List<FamilyMemory>>((ref) async {
  final service = ref.watch(familyMemoryServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  return service.fetchAllMemories(patientId: patientId);
});

final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(notificationServiceProvider).areRemindersEnabled();
});

final recentSessionsProvider =
    FutureProvider<List<CognitiveSession>>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  return service.fetchRecentSessions(patientId: patientId);
});

final weeklyReportProvider = FutureProvider<WeeklyCognitiveReport>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final patientId = ref.watch(activePatientIdProvider);
  return service.buildWeeklyReport(patientId: patientId);
});
