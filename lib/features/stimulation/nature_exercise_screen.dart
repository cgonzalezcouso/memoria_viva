import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

abstract final class NatureCatalog {
  static const items = [
    _NatureRound(
      emoji: '🌸',
      prompt: '¿En qué estación florecen muchas flores?',
      correct: 'Primavera',
      options: ['Primavera', 'Invierno', 'Otoño', 'Verano'],
    ),
    _NatureRound(
      emoji: '☀️',
      prompt: '¿Qué estación suele ser más calurosa?',
      correct: 'Verano',
      options: ['Verano', 'Invierno', 'Primavera', 'Otoño'],
    ),
    _NatureRound(
      emoji: '🍂',
      prompt: '¿Cuándo caen las hojas de los árboles?',
      correct: 'Otoño',
      options: ['Otoño', 'Primavera', 'Verano', 'Invierno'],
    ),
    _NatureRound(
      emoji: '❄️',
      prompt: '¿En qué estación puede nevar?',
      correct: 'Invierno',
      options: ['Invierno', 'Verano', 'Primavera', 'Otoño'],
    ),
    _NatureRound(
      emoji: '🌧️',
      prompt: '¿Qué fenómeno trae agua del cielo?',
      correct: 'Lluvia',
      options: ['Lluvia', 'Viento', 'Nieve', 'Sol'],
    ),
    _NatureRound(
      emoji: '🌈',
      prompt: '¿Qué aparece después de la lluvia con sol?',
      correct: 'Arcoíris',
      options: ['Arcoíris', 'Nube', 'Relámpago', 'Tormenta'],
    ),
    _NatureRound(
      emoji: '🐝',
      prompt: '¿Qué insecto hace miel?',
      correct: 'Abeja',
      options: ['Abeja', 'Mariposa', 'Mosca', 'Hormiga'],
    ),
    _NatureRound(
      emoji: '🌳',
      prompt: '¿Qué planta da sombra y oxígeno?',
      correct: 'Árbol',
      options: ['Árbol', 'Hierba', 'Flor', 'Musgo'],
    ),
    _NatureRound(
      emoji: '🐟',
      prompt: '¿Dónde viven los peces?',
      correct: 'Agua',
      options: ['Agua', 'Aire', 'Tierra', 'Fuego'],
    ),
    _NatureRound(
      emoji: '🦋',
      prompt: '¿Qué animal sale de una oruga?',
      correct: 'Mariposa',
      options: ['Mariposa', 'Abeja', 'Libélula', 'Mosca'],
    ),
    _NatureRound(
      emoji: '🌻',
      prompt: '¿Qué planta sigue el movimiento del sol?',
      correct: 'Girasol',
      options: ['Girasol', 'Rosa', 'Cactus', 'Helecho'],
    ),
    _NatureRound(
      emoji: '🌊',
      prompt: '¿Cómo se llama el agua salada del mar?',
      correct: 'Océano',
      options: ['Océano', 'Río', 'Lago', 'Charco'],
    ),
  ];
}

class NatureExerciseScreen extends ConsumerStatefulWidget {
  const NatureExerciseScreen({super.key});

  @override
  ConsumerState<NatureExerciseScreen> createState() => _NatureExerciseScreenState();
}

class _NatureExerciseScreenState extends ConsumerState<NatureExerciseScreen> {
  final _random = Random();
  late List<_NatureRound> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(ref.read(cognitiveDifficultyProvider));
  }

  List<_NatureRound> _generateQuestions(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final pool = [...NatureCatalog.items]..shuffle(_random);

    return pool.take(min(rounds, pool.length)).map((round) {
      final distractors =
          round.options.where((o) => o != round.correct).toList()..shuffle(_random);
      final options = [
        round.correct,
        ...distractors.take(optionCount - 1),
      ]..shuffle(_random);
      return _NatureRound(
        emoji: round.emoji,
        prompt: round.prompt,
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
        activityType: CognitiveActivityType.naturaleza,
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
        title: const Text('Naturaleza y estaciones'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(q.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(
                      q.prompt,
                      style: theme.textTheme.titleLarge,
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

class _NatureRound {
  const _NatureRound({
    required this.emoji,
    required this.prompt,
    required this.correct,
    required this.options,
  });

  final String emoji;
  final String prompt;
  final String correct;
  final List<String> options;
}
