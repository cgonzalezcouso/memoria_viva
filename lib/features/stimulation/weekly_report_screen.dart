import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/weekly_cognitive_report.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/report_email_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd('es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informe semanal'),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => report.hasData
                ? IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Exportar PDF',
                    onPressed: () => _exportPdf(context, ref, report),
                  )
                : null,
            orElse: () => null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('No se pudo generar el informe.'),
        ),
        data: (report) {
          if (!report.hasData) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionHeader(
                  title: 'Tu progreso esta semana',
                  description:
                      'Completa ejercicios de estimulación cognitiva '
                      'para ver tu informe aquí.',
                ),
                const SizedBox(height: 20),
                const InfoBanner(
                  message:
                      'Aún no hay actividad registrada en los últimos 7 días.',
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(
                title: 'Progreso cognitivo',
                description:
                    'Del ${dateFormat.format(report.weekStart)} al '
                    '${dateFormat.format(report.weekEnd)}',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _exportPdf(context, ref, report),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar informe en PDF'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sendEmail(context, ref, report),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Enviar informe por correo'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.reportEmailSettings),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Configurar envío automático'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Sesiones',
                      value: '${report.totalSessions}',
                      icon: Icons.play_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Puntuación media',
                      value: report.averageScore.toStringAsFixed(0),
                      icon: Icons.star_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Actividad por día', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...report.dailySummaries.map(
                (day) => _DayBar(
                  label: DateFormat.E('es').format(day.date),
                  sessionCount: day.sessionCount,
                  averageScore: day.averageScore,
                  maxSessions: _maxSessions(report.dailySummaries),
                ),
              ),
              const SizedBox(height: 28),
              Text('Por tipo de ejercicio', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...report.sessionsByActivity.entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(CognitiveActivityType.icon(entry.key)),
                    title: Text(CognitiveActivityType.label(entry.key)),
                    subtitle: Text(
                      '${entry.value} sesiones · '
                      'media ${report.averageByActivity[entry.key]?.toStringAsFixed(0) ?? '0'} pts',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                icon: Icons.insights_outlined,
                message:
                    'Puedes compartir el PDF con familiares o profesionales '
                    'de salud como referencia orientativa.',
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendEmail(
    BuildContext context,
    WidgetRef ref,
    WeeklyCognitiveReport report,
  ) async {
    try {
      final settings = await ref.read(reportEmailSettingsProvider.future);
      if (!settings.isConfigured) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configura un correo en Envío de informes'),
            ),
          );
          context.push(AppRoutes.reportEmailSettings);
        }
        return;
      }

      final patientName = ref.read(authControllerProvider).value?.profile?.fullName;

      await sendWeeklyReportByEmail(
        ref,
        report: report,
        recipientEmail: settings.recipientEmail,
        patientName: patientName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Informe enviado a ${settings.recipientEmail}'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    WeeklyCognitiveReport report,
  ) async {
    try {
      final patientName = ref.read(authControllerProvider).value?.profile?.fullName;
      await ref.read(pdfReportServiceProvider).shareWeeklyReport(
            report: report,
            patientName: patientName,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar: $error')),
        );
      }
    }
  }

  int _maxSessions(List<DailyCognitiveSummary> summaries) {
    var max = 1;
    for (final day in summaries) {
      if (day.sessionCount > max) max = day.sessionCount;
    }
    return max;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.sessionCount,
    required this.averageScore,
    required this.maxSessions,
  });

  final String label;
  final int sessionCount;
  final double averageScore;
  final int maxSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = sessionCount / maxSessions;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label[0].toUpperCase() + label.substring(1),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                sessionCount == 0
                    ? 'Sin actividad'
                    : '$sessionCount ses. · ${averageScore.toStringAsFixed(0)} pts',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: sessionCount == 0 ? 0 : fraction,
              minHeight: 14,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
