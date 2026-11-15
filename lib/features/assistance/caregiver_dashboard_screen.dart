import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/cognitive_activity_type.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/active_patient_banner.dart';
import '../../shared/widgets/info_banner.dart';

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final routinesAsync = ref.watch(todayRoutineProvider);
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMMEEEEd('es').format(DateTime.now());
    final isCaregiver = ref.watch(isCaregiverProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel del cuidador')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(dateLabel, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          const ActivePatientBanner(),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.volunteer_activism_outlined,
            message:
                'Este panel resume la actividad reciente para apoyar '
                'el seguimiento entre familiares y cuidadores.',
          ),
          if (isCaregiver) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.manageCare),
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Personalizar rutinas y medicación'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.weeklyReport),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Ver informe semanal'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Rutina de hoy', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          routinesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Sin datos de rutina disponibles.'),
            data: (tasks) {
              final completed = tasks.where((t) => t.isCompleted).length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed de ${tasks.length} actividades completadas',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...tasks.map(
                        (task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: task.isCompleted
                                ? Colors.green
                                : theme.colorScheme.outline,
                          ),
                          title: Text(task.title),
                          subtitle: Text(task.scheduledTime),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Actividad cognitiva reciente',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Sin sesiones registradas aún.'),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Text(
                  'Aún no hay sesiones guardadas. '
                  'Completa un ejercicio de estimulación cognitiva.',
                );
              }

              return Column(
                children: sessions
                    .map(
                      (session) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            CognitiveActivityType.icon(session.activityType),
                          ),
                          title: Text(
                            CognitiveActivityType.label(session.activityType),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd('es').add_Hm().format(
                                  session.completedAt,
                                ),
                          ),
                          trailing: Text(
                            '${session.score} pts',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
