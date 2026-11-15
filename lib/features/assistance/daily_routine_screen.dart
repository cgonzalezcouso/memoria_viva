import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/auth_providers.dart';

class DailyRoutineScreen extends ConsumerWidget {
  const DailyRoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayRoutineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutina diaria')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudo cargar la rutina: $error'),
        ),
        data: (tasks) {
          final completed = tasks.where((task) => task.isCompleted).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Completadas: $completed de ${tasks.length}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: tasks.isEmpty ? 0 : completed / tasks.length,
                minHeight: 12,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 24),
              ...tasks.map(
                (task) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: task.isCompleted,
                    onChanged: (value) async {
                      final patientId = ref.read(activePatientIdProvider);
                      await ref.read(routineServiceProvider).toggleTask(
                            patientId: patientId,
                            taskId: task.id,
                            isCompleted: value ?? false,
                          );
                      ref.invalidate(todayRoutineProvider);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    title: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text('Hora: ${task.scheduledTime}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
