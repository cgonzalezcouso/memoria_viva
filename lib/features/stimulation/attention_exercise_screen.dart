import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class AttentionExerciseScreen extends ConsumerStatefulWidget {
  const AttentionExerciseScreen({super.key});

  @override
  ConsumerState<AttentionExerciseScreen> createState() =>
      _AttentionExerciseScreenState();
}

class _AttentionExerciseScreenState
    extends ConsumerState<AttentionExerciseScreen> {
  final _random = Random();
  late Color _targetColor;
  late int _targetCount;
  late List<Color> _colors;
  int? _selectedAnswer;
  bool _answered = false;
  int _round = 1;
  int _score = 0;
  int _totalRounds = 7;
  int _pointsPerRound = 14;

  static const _palette = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _configureSession();
    _newRound();
  }

  void _configureSession() {
    final difficulty = ref.read(cognitiveDifficultyProvider);
    _totalRounds = ActivityDifficultyConfig.rounds(difficulty);
    _pointsPerRound = ActivityDifficultyConfig.pointsPerRound(_totalRounds);
  }

  void _resetSession() {
    _configureSession();
    _round = 1;
    _score = 0;
    _newRound();
  }

  void _newRound() {
    final difficulty = ref.read(cognitiveDifficultyProvider);
    final dotCount = ActivityDifficultyConfig.attentionDots(difficulty);
    final maxTarget = ActivityDifficultyConfig.attentionMaxTarget(difficulty);

    _targetColor = _palette[_random.nextInt(_palette.length)];
    _targetCount = _random.nextInt(maxTarget - 1) + 2;
    _colors = List.generate(dotCount, (index) {
      if (index < _targetCount) {
        return _targetColor;
      }
      return _palette[_random.nextInt(_palette.length)];
    })..shuffle(_random);
    _selectedAnswer = null;
    _answered = false;
  }

  Future<void> _checkAnswer(int answer) async {
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == _targetCount) {
        _score += _pointsPerRound;
      }
    });

    if (_round >= _totalRounds) {
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.atencion,
        score: min(_score, 100),
        durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
          ref.read(cognitiveDifficultyProvider),
          _totalRounds,
        ),
      );
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _round++;
      _newRound();
    });
  }

  String _colorName(Color color) {
    if (color == Colors.red) return 'rojos';
    if (color == Colors.blue) return 'azules';
    if (color == Colors.green) return 'verdes';
    if (color == Colors.orange) return 'naranjas';
    return 'morados';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next) {
        setState(_resetSession);
      }
    });

    final theme = Theme.of(context);
    final finished = _answered && _round >= _totalRounds;
    final maxAnswer = ActivityDifficultyConfig.attentionMaxTarget(
      ref.watch(cognitiveDifficultyProvider),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicio de atención'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              finished
                  ? 'Sesión completada. Puntuación: ${min(_score, 100)}'
                  : 'Ronda $_round de $_totalRounds',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '¿Cuántos círculos ${_colorName(_targetColor)} ves?',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _colors
                    .map(
                      (color) => CircleAvatar(
                        radius: 28,
                        backgroundColor: color,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(maxAnswer + 1, (index) {
                final value = index + 1;
                final isSelected = _selectedAnswer == value;

                return SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _answered ? null : () => _checkAnswer(value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                    child: Text('$value', style: const TextStyle(fontSize: 24)),
                  ),
                );
              }),
            ),
            if (finished) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(_resetSession),
                  child: const Text('Jugar de nuevo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
