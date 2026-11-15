import '../constants/patient_ids.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../models/report_email_settings.dart';
import 'report_email_storage.dart';

class ReportEmailSettingsService {
  ReportEmailSettingsService(this._localStorage);

  final ReportEmailStorage _localStorage;

  Future<ReportEmailSettings> fetch(String patientId) async {
    if (!Env.isSupabaseConfigured || !PatientIds.canSyncToSupabase(patientId)) {
      return _localStorage.load(patientId);
    }

    try {
      final response = await SupabaseConfig.client
          .from('report_email_settings')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      if (response == null) {
        return ReportEmailSettings.empty(patientId);
      }
      return ReportEmailSettings.fromJson(response);
    } catch (_) {
      return _localStorage.load(patientId);
    }
  }

  Future<void> save(ReportEmailSettings settings) async {
    await _localStorage.save(settings);

    if (!Env.isSupabaseConfigured || !PatientIds.canSyncToSupabase(settings.patientId)) {
      return;
    }

    await SupabaseConfig.client.from('report_email_settings').upsert(
      {
        ...settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'patient_id',
    );
  }

  Future<void> markSent(String patientId) async {
    final current = await fetch(patientId);
    final updated = current.copyWith(lastSentAt: DateTime.now());
    await save(updated);
  }
}
