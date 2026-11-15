import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/patient_ids.dart';
import '../models/report_email_settings.dart';
import '../models/weekly_cognitive_report.dart';
import '../services/email_report_service.dart';
import '../services/report_email_settings_service.dart';
import '../services/report_email_storage.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

final reportEmailStorageProvider = Provider<ReportEmailStorage>(
  (ref) => ReportEmailStorage(),
);

final reportEmailSettingsServiceProvider = Provider<ReportEmailSettingsService>(
  (ref) => ReportEmailSettingsService(ref.watch(reportEmailStorageProvider)),
);

final emailReportServiceProvider = Provider<EmailReportService>(
  (ref) => EmailReportService(ref.watch(pdfReportServiceProvider)),
);

final reportEmailSettingsProvider =
    FutureProvider<ReportEmailSettings>((ref) async {
  final patientId = ref.watch(activePatientIdProvider);
  return ref.read(reportEmailSettingsServiceProvider).fetch(patientId);
});

/// Comprueba y envía el informe semanal si corresponde (al abrir la app).
final autoSendWeeklyReportProvider = FutureProvider<void>((ref) async {
  final patientId = ref.watch(activePatientIdProvider);
  if (!PatientIds.canSyncToSupabase(patientId)) return;

  final settings = await ref.read(reportEmailSettingsProvider.future);
  if (!settings.shouldSendAutomatically(DateTime.now())) return;

  final report = await ref.read(weeklyReportProvider.future);
  if (!report.hasData) return;

  final patientName = ref.read(authControllerProvider).value?.profile?.fullName;

  await ref.read(emailReportServiceProvider).sendWeeklyReport(
        report: report,
        recipientEmail: settings.recipientEmail,
        patientName: patientName,
      );

  await ref.read(reportEmailSettingsServiceProvider).markSent(patientId);
  ref.invalidate(reportEmailSettingsProvider);
});

Future<void> sendWeeklyReportByEmail(
  WidgetRef ref, {
  required WeeklyCognitiveReport report,
  required String recipientEmail,
  String? patientName,
}) async {
  await ref.read(emailReportServiceProvider).sendWeeklyReport(
        report: report,
        recipientEmail: recipientEmail,
        patientName: patientName,
      );

  final patientId = ref.read(activePatientIdProvider);
  await ref.read(reportEmailSettingsServiceProvider).markSent(patientId);
  ref.invalidate(reportEmailSettingsProvider);
}
