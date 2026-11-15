import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

abstract final class MusicCatalog {
  static const items = [
    _MusicItem(emoji: '🎸', name: 'Guitarra'),
    _MusicItem(emoji: '🎹', name: 'Piano'),
    _MusicItem(emoji: '🎺', name: 'Trompeta'),
    _MusicItem(emoji: '🥁', name: 'Tambor'),
    _MusicItem(emoji: '🎻', name: 'Violín'),
    _MusicItem(emoji: '🎷', name: 'Saxofón'),
    _MusicItem(emoji: '🪗', name: 'Acordeón'),
    _MusicItem(emoji: '🪈', name: 'Flauta'),
    _MusicItem(emoji: '🎤', name: 'Micrófono'),
    _MusicItem(emoji: '🪕', name: 'Banjo'),
    _MusicItem(emoji: '📯', name: 'Corneta'),
    _MusicItem(emoji: '🪇', name: 'Maracas'),
  ];

  static List<String> get names => items.map((item) => item.name).toList();
}

class MusicExerciseScreen extends ConsumerStatefulWidget {
  const MusicExerciseScreen({super.key});

  @override
  ConsumerState<MusicExerciseScreen> createState() => _MusicExerciseScreenState();
}

class _MusicExerciseScreenState extends ConsumerState<MusicExerciseScreen> {
  final _random = Random();
  late List<_MusicRound> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(ref.read(cognitiveDifficultyProvider));
  }

  List<_MusicRound> _generateQuestions(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final pool = [...MusicCatalog.items]..shuffle(_random);
    final selected = pool.take(min(rounds, pool.length));
    final allNames = MusicCatalog.names;

    return selected.map((item) {
      final distractors = allNames.where((name) => name != item.name).toList()
        ..shuffle(_random);

      final options = [
        item.name,
        ...distractors.take(optionCount - 1),
      ]..shuffle(_random);

      return _MusicRound(
        instrument: item.emoji,
        correct: item.name,
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
        activityType: CognitiveActivityType.musica,
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
        title: const Text('Música e instrumentos'),
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
              '¿Qué instrumento es este?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  q.instrument,
                  style: const TextStyle(fontSize: 72),
                  textAlign: TextAlign.center,
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

class _MusicItem {
  const _MusicItem({required this.emoji, required this.name});

  final String emoji;
  final String name;
}

class _MusicRound {
  const _MusicRound({
    required this.instrument,
    required this.correct,
    required this.options,
  });

  final String instrument;
  final String correct;
  final List<String> options;
}
