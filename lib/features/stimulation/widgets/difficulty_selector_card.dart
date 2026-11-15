import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cognitive_difficulty.dart';
import '../../../core/providers/cognitive_difficulty_provider.dart';
import '../../../shared/widgets/info_banner.dart';

class DifficultySelectorCard extends ConsumerWidget {
  const DifficultySelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(cognitiveDifficultyProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nivel de dificultad',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Elige el nivel según el deterioro cognitivo de la persona. '
              'Se aplicará a todas las actividades.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...CognitiveDifficulty.values.map((level) {
              final isSelected = level == selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        ref.read(cognitiveDifficultyProvider.notifier).set(level),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${level.label} · ${level.shortDescription}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  level.description,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            InfoBanner(
              icon: Icons.tune_outlined,
              message:
                  'Nivel ${selected.label}: '
                  '${selected == CognitiveDifficulty.suave ? '5' : selected == CognitiveDifficulty.medio ? '7' : '10'} '
                  'preguntas aprox. por actividad.',
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDifficultyBadge extends ConsumerWidget {
  const ExerciseDifficultyBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(cognitiveDifficultyProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: Chip(
          avatar: Icon(
            Icons.tune,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text('Nivel ${difficulty.label}'),
        ),
      ),
    );
  }
}
