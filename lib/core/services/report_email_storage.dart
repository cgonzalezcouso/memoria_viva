import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_email_settings.dart';

class ReportEmailStorage {
  static const _keyPrefix = 'report_email_settings';

  Future<ReportEmailSettings> load(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix:$patientId');
    if (raw == null) return ReportEmailSettings.empty(patientId);

    return ReportEmailSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> save(ReportEmailSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix:${settings.patientId}',
      jsonEncode(settings.toLocalJson()),
    );
  }
}
