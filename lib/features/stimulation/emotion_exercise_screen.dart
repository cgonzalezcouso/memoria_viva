import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

/// Catálogo de emociones básicas para reconocimiento facial.
abstract final class EmotionCatalog {
  static const items = [
    _Emotion(emoji: '😊', label: 'Feliz'),
    _Emotion(emoji: '😄', label: 'Alegre'),
    _Emotion(emoji: '🙂', label: 'Contento'),
    _Emotion(emoji: '😆', label: 'Satisfecho'),
    _Emotion(emoji: '🤩', label: 'Emocionado'),
    _Emotion(emoji: '🥰', label: 'Cariñoso'),
    _Emotion(emoji: '😍', label: 'Enamorado'),
    _Emotion(emoji: '😌', label: 'Tranquilo'),
    _Emotion(emoji: '😢', label: 'Triste'),
    _Emotion(emoji: '😭', label: 'Llorando'),
    _Emotion(emoji: '😔', label: 'Apenado'),
    _Emotion(emoji: '🥺', label: 'Solitario'),
    _Emotion(emoji: '😞', label: 'Decepcionado'),
    _Emotion(emoji: '😠', label: 'Enfadado'),
    _Emotion(emoji: '😡', label: 'Furioso'),
    _Emotion(emoji: '😒', label: 'Molesto'),
    _Emotion(emoji: '🙄', label: 'Fastidiado'),
    _Emotion(emoji: '😤', label: 'Orgulloso'),
    _Emotion(emoji: '😨', label: 'Asustado'),
    _Emotion(emoji: '😱', label: 'Atemorizado'),
    _Emotion(emoji: '😰', label: 'Nervioso'),
    _Emotion(emoji: '😟', label: 'Preocupado'),
    _Emotion(emoji: '😲', label: 'Sorprendido'),
    _Emotion(emoji: '😮', label: 'Asombrado'),
    _Emotion(emoji: '🤢', label: 'Disgustado'),
    _Emotion(emoji: '😳', label: 'Avergonzado'),
    _Emotion(emoji: '😬', label: 'Incómodo'),
    _Emotion(emoji: '😕', label: 'Confundido'),
    _Emotion(emoji: '🤔', label: 'Curioso'),
    _Emotion(emoji: '😑', label: 'Aburrido'),
    _Emotion(emoji: '😐', label: 'Indiferente'),
    _Emotion(emoji: '😴', label: 'Cansado'),
    _Emotion(emoji: '😏', label: 'Celoso'),
    _Emotion(emoji: '😖', label: 'Angustiado'),
    _Emotion(emoji: '😯', label: 'Desconcertado'),
  ];
}

class EmotionExerciseScreen extends ConsumerStatefulWidget {
  const EmotionExerciseScreen({super.key});

  @override
  ConsumerState<EmotionExerciseScreen> createState() =>
      _EmotionExerciseScreenState();
}

class _EmotionExerciseScreenState extends ConsumerState<EmotionExerciseScreen> {
  final _random = Random();
  late List<_EmotionRound> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(ref.read(cognitiveDifficultyProvider));
  }

  List<_EmotionRound> _generateQuestions(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final pool = [...EmotionCatalog.items]..shuffle(_random);
    final selected = pool.take(min(rounds, pool.length));
    final allLabels = EmotionCatalog.items.map((e) => e.label).toList();

    return selected.map((emotion) {
      final distractors = allLabels.where((l) => l != emotion.label).toList()
        ..shuffle(_random);
      final options = [
        emotion.label,
        ...distractors.take(optionCount - 1),
      ]..shuffle(_random);

      return _EmotionRound(
        emoji: emotion.emoji,
        correct: emotion.label,
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
        activityType: CognitiveActivityType.emociones,
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
        title: const Text('Reconocimiento de emociones'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
            '¿Qué emoción muestra esta cara?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            q.emoji,
            style: const TextStyle(fontSize: 96),
            textAlign: TextAlign.center,
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _restart(difficulty),
              child: const Text('Repetir ejercicio'),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Emociones incluidas (${EmotionCatalog.items.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Cada sesión muestra ${ActivityDifficultyConfig.rounds(difficulty)} '
            'caras al azar del catálogo completo.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EmotionCatalog.items.map((emotion) {
              return Chip(
                avatar: Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
                label: Text(emotion.label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Emotion {
  const _Emotion({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

class _EmotionRound {
  const _EmotionRound({
    required this.emoji,
    required this.correct,
    required this.options,
  });

  final String emoji;
  final String correct;
  final List<String> options;
}
