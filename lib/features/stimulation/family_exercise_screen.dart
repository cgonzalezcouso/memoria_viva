import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/models/family_memory.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class FamilyExerciseScreen extends ConsumerStatefulWidget {
  const FamilyExerciseScreen({super.key});

  @override
  ConsumerState<FamilyExerciseScreen> createState() => _FamilyExerciseScreenState();
}

class _FamilyExerciseScreenState extends ConsumerState<FamilyExerciseScreen> {
  final _random = Random();
  List<_FamilyRound> _questions = [];
  int _index = 0;
  int _score = 0;
  bool _finished = false;
  bool _initialized = false;
  int _pointsPerRound = 25;

  List<_FamilyRound> _buildQuestions(
    List<FamilyMemory> memories,
    CognitiveDifficulty difficulty,
  ) {
    final distractorCount = ActivityDifficultyConfig.familyDistractors(difficulty);

    final rounds = memories.map((m) {
      final others = memories.where((o) => o.id != m.id).toList()..shuffle(_random);
      final distractors = others
          .take(distractorCount)
          .map((o) => o.displayName)
          .toList();
      final options = [m.displayName, ...distractors]..shuffle(_random);
      return _FamilyRound(
        emoji: m.emoji,
        name: m.displayName,
        correct: m.displayName,
        prompt: '¿Cómo se llama esta persona?',
        options: options,
      );
    }).toList();

    rounds.addAll(
      memories.map((m) {
        final others = memories.where((o) => o.id != m.id).toList()..shuffle(_random);
        final distractors = others
            .take(distractorCount)
            .map((o) => o.relationship)
            .toList();
        final options = [m.relationship, ...distractors]..shuffle(_random);
        return _FamilyRound(
          emoji: m.emoji,
          name: m.displayName,
          correct: m.relationship,
          prompt: '¿Qué relación tiene ${m.displayName} contigo?',
          options: options,
        );
      }),
    );

    return rounds..shuffle(_random);
  }

  Future<void> _answer(String option) async {
    if (_finished || _questions.isEmpty) return;
    if (option == _questions[_index].correct) _score += _pointsPerRound;

    if (_index == _questions.length - 1) {
      setState(() => _finished = true);
      final difficulty = ref.read(cognitiveDifficultyProvider);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.familia,
        score: min(_score, 100),
        durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
          difficulty,
          _questions.length,
        ),
      );
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next) {
        setState(() => _initialized = false);
      }
    });

    final theme = Theme.of(context);
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    final memoriesAsync = ref.watch(familyMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuerdos familiares'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: memoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('No se pudieron cargar los recuerdos.')),
        data: (memories) {
          if (memories.length < 2) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.family_restroom_outlined, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Se necesitan al menos dos personas familiares.',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Un cuidador puede añadirlas en Personalizar cuidados → Recuerdos familiares.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (!_initialized) {
            final available = _buildQuestions(memories, difficulty);
            final roundCount = min(
              ActivityDifficultyConfig.rounds(difficulty),
              available.length,
            );
            _questions = available.take(roundCount).toList();
            _pointsPerRound =
                ActivityDifficultyConfig.pointsPerRound(_questions.length);
            _index = 0;
            _score = 0;
            _finished = false;
            _initialized = true;
          }

          final q = _questions[_index];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _finished
                      ? 'Puntuación: ${min(_score, 100)}'
                      : 'Pregunta ${_index + 1} de ${_questions.length}',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(q.prompt, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(q.emoji, style: const TextStyle(fontSize: 64)),
                        if (q.prompt.contains('relación'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              q.name,
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...q.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: _finished ? null : () => _answer(option),
                      child: Text(option),
                    ),
                  ),
                ),
                if (_finished) ...[
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _index = 0;
                      _score = 0;
                      _finished = false;
                      _initialized = false;
                    }),
                    child: const Text('Repetir ejercicio'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FamilyRound {
  const _FamilyRound({
    required this.emoji,
    required this.name,
    required this.correct,
    required this.prompt,
    required this.options,
  });

  final String emoji;
  final String name;
  final String correct;
  final String prompt;
  final List<String> options;
}
