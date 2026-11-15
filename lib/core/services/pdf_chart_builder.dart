import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cognitive_activity_type.dart';
import '../models/weekly_cognitive_report.dart';

abstract final class PdfChartBuilder {
  static pw.Widget dailySessionsBarChart({
    required List<DailyCognitiveSummary> summaries,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    final maxSessions = summaries
        .map((day) => day.sessionCount)
        .fold(1, (max, count) => count > max ? count : max);
    const chartHeight = 130.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Sesiones por día',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          pw.SizedBox(
            height: chartHeight + 24,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: summaries.map((day) {
                final dayLabel = DateFormat.E('es').format(day.date);
                final shortLabel = dayLabel.substring(0, 1).toUpperCase();
                final barHeight = day.sessionCount == 0
                    ? 4.0
                    : (day.sessionCount / maxSessions) * chartHeight;

                return pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      if (day.sessionCount > 0)
                        pw.Text(
                          '${day.sessionCount}',
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        height: barHeight,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                        decoration: pw.BoxDecoration(
                          color: day.sessionCount == 0
                              ? PdfColors.grey300
                              : PdfColors.blue800,
                          borderRadius: const pw.BorderRadius.vertical(
                            top: pw.Radius.circular(4),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        shortLabel,
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget activityDistributionChart({
    required Map<String, int> sessionsByActivity,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    if (sessionsByActivity.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final maxCount = sessionsByActivity.values.fold(1, (a, b) => a > b ? a : b);
    const barWidth = 220.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Distribución por ejercicio',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          ...sessionsByActivity.entries.map((entry) {
            final fraction = entry.value / maxCount;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          CognitiveActivityType.label(entry.key),
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ),
                      pw.Text(
                        '${entry.value}',
                        style: pw.TextStyle(font: fontBold, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Stack(
                    children: [
                      pw.Container(
                        width: barWidth,
                        height: 10,
                        color: PdfColors.grey200,
                      ),
                      pw.Container(
                        width: barWidth * fraction,
                        height: 10,
                        color: PdfColors.teal700,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget averageScoreLineChart({
    required List<DailyCognitiveSummary> summaries,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    const chartHeight = 80.0;
    const chartWidth = 400.0;

    final points = <PdfPoint>[];
    for (var i = 0; i < summaries.length; i++) {
      final day = summaries[i];
      final x = summaries.length == 1
          ? chartWidth / 2
          : (i / (summaries.length - 1)) * chartWidth;
      final y = chartHeight - (day.averageScore / 100 * chartHeight);
      points.add(PdfPoint(x, day.sessionCount == 0 ? chartHeight : y));
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Puntuación media diaria',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.CustomPaint(
            size: PdfPoint(chartWidth, chartHeight),
            painter: (canvas, size) {
              canvas.setStrokeColor(PdfColors.grey300);
              for (var i = 0; i <= 4; i++) {
                final y = (i / 4) * chartHeight;
                canvas
                  ..moveTo(0, y)
                  ..lineTo(chartWidth, y)
                  ..strokePath();
              }

              if (points.length >= 2) {
                canvas.setStrokeColor(PdfColors.orange800);
                canvas.setLineWidth(2);
                canvas.moveTo(points.first.x, points.first.y);
                for (var i = 1; i < points.length; i++) {
                  canvas.lineTo(points[i].x, points[i].y);
                }
                canvas.strokePath();
              }

              canvas.setFillColor(PdfColors.orange800);
              for (final point in points) {
                canvas.drawEllipse(point.x - 2, point.y - 2, 4, 4);
                canvas.fillPath();
              }
            },
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Escala: 0–100 puntos',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }
}
