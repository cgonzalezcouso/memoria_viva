import 'dart:convert';

import 'package:intl/intl.dart';

import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../models/weekly_cognitive_report.dart';
import 'pdf_report_service.dart';

class EmailReportFailure implements Exception {
  EmailReportFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class EmailReportService {
  EmailReportService(this._pdfService);

  final PdfReportService _pdfService;

  Future<void> sendWeeklyReport({
    required WeeklyCognitiveReport report,
    required String recipientEmail,
    String? patientName,
  }) async {
    if (!Env.isSupabaseConfigured) {
      throw EmailReportFailure(
        'El envío automático por correo requiere Supabase configurado '
        'y la función send-weekly-report desplegada.',
      );
    }

    final email = recipientEmail.trim();
    if (!email.contains('@')) {
      throw EmailReportFailure('Correo de destino no válido.');
    }

    final pdfBytes = await _pdfService.buildWeeklyReportPdf(
      report: report,
      patientName: patientName,
    );

    final dateFormat = DateFormat.yMMMd('es');
    final periodLabel =
        '${dateFormat.format(report.weekStart)} – ${dateFormat.format(report.weekEnd)}';

    final response = await SupabaseConfig.client.functions.invoke(
      'send-weekly-report',
      body: {
        'recipient_email': email,
        'patient_name': patientName ?? 'Usuario',
        'period_label': periodLabel,
        'pdf_base64': base64Encode(pdfBytes),
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Error ${response.status} al enviar el correo.';
      throw EmailReportFailure(message);
    }
  }
}
