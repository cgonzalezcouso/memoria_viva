import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/weekly_cognitive_report.dart';
import 'pdf_chart_builder.dart';

class PdfReportService {
  Future<void> shareWeeklyReport({
    required WeeklyCognitiveReport report,
    String? patientName,
  }) async {
    final bytes = await buildWeeklyReportPdf(
      report: report,
      patientName: patientName,
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final filename =
        'informe_memoria_viva_${dateFormat.format(report.weekStart)}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<Uint8List> buildWeeklyReportPdf({
    required WeeklyCognitiveReport report,
    String? patientName,
  }) async {
    final dateFormat = DateFormat.yMMMd('es');
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            'Memoria Viva',
            style: pw.TextStyle(font: fontBold, fontSize: 22),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Informe semanal de estimulación cognitiva',
            style: pw.TextStyle(font: font, fontSize: 14),
          ),
          if (patientName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Persona: $patientName',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'Periodo: ${dateFormat.format(report.weekStart)} – '
            '${dateFormat.format(report.weekEnd)}',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              _pdfStatBox(
                font: font,
                fontBold: fontBold,
                label: 'Sesiones totales',
                value: '${report.totalSessions}',
              ),
              pw.SizedBox(width: 16),
              _pdfStatBox(
                font: font,
                fontBold: fontBold,
                label: 'Puntuación media',
                value: report.averageScore.toStringAsFixed(0),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          PdfChartBuilder.dailySessionsBarChart(
            summaries: report.dailySummaries,
            font: font,
            fontBold: fontBold,
          ),
          pw.SizedBox(height: 16),
          PdfChartBuilder.averageScoreLineChart(
            summaries: report.dailySummaries,
            font: font,
            fontBold: fontBold,
          ),
          pw.SizedBox(height: 16),
          PdfChartBuilder.activityDistributionChart(
            sessionsByActivity: report.sessionsByActivity,
            font: font,
            fontBold: fontBold,
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Detalle por día',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Día', 'Sesiones', 'Puntuación media'],
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 11),
            cellStyle: pw.TextStyle(font: font, fontSize: 11),
            data: report.dailySummaries.map((day) {
              final dayLabel = DateFormat.E('es').format(day.date);
              final capitalized =
                  dayLabel[0].toUpperCase() + dayLabel.substring(1);
              return [
                capitalized,
                '${day.sessionCount}',
                day.sessionCount == 0
                    ? '—'
                    : day.averageScore.toStringAsFixed(0),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 32),
          pw.Text(
            'Este informe es orientativo y no sustituye evaluación clínica.',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _pdfStatBox({
    required pw.Font font,
    required pw.Font fontBold,
    required String label,
    required String value,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 20)),
            pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
