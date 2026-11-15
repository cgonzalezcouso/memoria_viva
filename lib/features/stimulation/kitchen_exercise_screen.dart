import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

abstract final class KitchenCatalog {
  static const items = [
    _KitchenRound(
      food: '🥐',
      name: 'Croissant',
      correct: 'Desayuno',
      options: ['Desayuno', 'Cena', 'Merienda nocturna', 'Picoteo'],
    ),
    _KitchenRound(
      food: '🍲',
      name: 'Sopa',
      correct: 'Comida',
      options: ['Comida', 'Desayuno', 'Postre', 'Merienda'],
    ),
    _KitchenRound(
      food: '🥗',
      name: 'Ensalada',
      correct: 'Comida',
      options: ['Comida', 'Desayuno', 'Cena tardía', 'Merienda dulce'],
    ),
    _KitchenRound(
      food: '🍵',
      name: 'Infusión',
      correct: 'Merienda',
      options: ['Merienda', 'Desayuno fuerte', 'Cena', 'Brunch'],
    ),
    _KitchenRound(
      food: '🍳',
      name: 'Huevos revueltos',
      correct: 'Desayuno',
      options: ['Desayuno', 'Cena', 'Merienda', 'Postre'],
    ),
    _KitchenRound(
      food: '🍝',
      name: 'Pasta',
      correct: 'Comida',
      options: ['Comida', 'Desayuno', 'Merienda', 'Brunch'],
    ),
    _KitchenRound(
      food: '🍰',
      name: 'Tarta',
      correct: 'Merienda',
      options: ['Merienda', 'Desayuno', 'Comida', 'Cena'],
    ),
    _KitchenRound(
      food: '🥣',
      name: 'Cereales con leche',
      correct: 'Desayuno',
      options: ['Desayuno', 'Comida', 'Cena', 'Merienda'],
    ),
    _KitchenRound(
      food: '🍎',
      name: 'Manzana',
      correct: 'Merienda',
      options: ['Merienda', 'Desayuno', 'Cena', 'Comida'],
    ),
    _KitchenRound(
      food: '🍖',
      name: 'Estofado',
      correct: 'Comida',
      options: ['Comida', 'Desayuno', 'Merienda', 'Brunch'],
    ),
    _KitchenRound(
      food: '🥛',
      name: 'Leche caliente',
      correct: 'Desayuno',
      options: ['Desayuno', 'Comida', 'Cena', 'Merienda nocturna'],
    ),
    _KitchenRound(
      food: '🥪',
      name: 'Bocadillo',
      correct: 'Comida',
      options: ['Comida', 'Desayuno', 'Cena', 'Postre'],
    ),
  ];
}

class KitchenExerciseScreen extends ConsumerStatefulWidget {
  const KitchenExerciseScreen({super.key});

  @override
  ConsumerState<KitchenExerciseScreen> createState() => _KitchenExerciseScreenState();
}

class _KitchenExerciseScreenState extends ConsumerState<KitchenExerciseScreen> {
  final _random = Random();
  late List<_KitchenRound> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(ref.read(cognitiveDifficultyProvider));
  }

  List<_KitchenRound> _generateQuestions(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final pool = [...KitchenCatalog.items]..shuffle(_random);

    return pool.take(min(rounds, pool.length)).map((round) {
      final distractors =
          round.options.where((o) => o != round.correct).toList()..shuffle(_random);
      final options = [
        round.correct,
        ...distractors.take(optionCount - 1),
      ]..shuffle(_random);
      return _KitchenRound(
        food: round.food,
        name: round.name,
        correct: round.correct,
        options: options,
      );
    }).toList();
  }

  Future<void> _answer(String option) async {
    if (_finished) return;
    final difficulty = ref.read(cognitiveDifficultyProvider);
    if (option == _questions[_index].correct) {
      _score += ActivityDifficultyConfig.pointsPerRound(_questions.length);
    }

    if (_index == _questions.length - 1) {
      setState(() => _finished = true);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.cocina,
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

  void _restart(CognitiveDifficulty difficulty) {
    setState(() {
      _index = 0;
      _score = 0;
      _finished = false;
      _questions = _generateQuestions(difficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next && mounted) _restart(next);
    });

    final theme = Theme.of(context);
    final q = _questions[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cocina y alimentación'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
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
            Text(
              '¿En qué momento del día encaja mejor?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(q.food, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      q.name,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
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
                onPressed: () => _restart(difficulty),
                child: const Text('Repetir ejercicio'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KitchenRound {
  const _KitchenRound({
    required this.food,
    required this.name,
    required this.correct,
    required this.options,
  });

  final String food;
  final String name;
  final String correct;
  final List<String> options;
}
