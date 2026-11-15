import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class CalculationExerciseScreen extends ConsumerStatefulWidget {
  const CalculationExerciseScreen({super.key});

  @override
  ConsumerState<CalculationExerciseScreen> createState() =>
      _CalculationExerciseScreenState();
}

class _CalculationExerciseScreenState
    extends ConsumerState<CalculationExerciseScreen> {
  final _random = Random();
  late List<_CalcQuestion> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;
  bool _answered = false;
  int _pointsPerRound = 14;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
  }

  List<_CalcQuestion> _generateQuestions() {
    final difficulty = ref.read(cognitiveDifficultyProvider);
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    _pointsPerRound = ActivityDifficultyConfig.pointsPerRound(rounds);
    return List.generate(rounds, (_) => _randomQuestion(difficulty));
  }

  _CalcQuestion _randomQuestion(CognitiveDifficulty difficulty) {
    final types = <int>[0];
    if (ActivityDifficultyConfig.calculationAllowSubtract(difficulty)) {
      types.add(1);
    }
    if (ActivityDifficultyConfig.calculationAllowMultiply(difficulty)) {
      types.add(2);
    }
    if (ActivityDifficultyConfig.calculationAllowDivide(difficulty)) {
      types.add(3);
    }
    if (ActivityDifficultyConfig.calculationAllowCombined(difficulty)) {
      types.add(4);
    }

    for (var attempt = 0; attempt < 30; attempt++) {
      final question = switch (types[_random.nextInt(types.length)]) {
        0 => _simpleAdd(difficulty),
        1 => _simpleSubtract(difficulty),
        2 => _simpleMultiply(difficulty),
        3 => _simpleDivide(difficulty),
        _ => _combined(difficulty),
      };
      if (question != null) return question;
    }
    return _simpleAdd(difficulty);
  }

  _CalcQuestion _simpleAdd(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final a = _random.nextInt(max) + 1;
    final b = _random.nextInt(max) + 1;
    return _makeQuestion('$a + $b', a + b, difficulty);
  }

  _CalcQuestion _simpleSubtract(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final b = _random.nextInt(max - 1) + 1;
    final a = b + _random.nextInt(max) + 1;
    return _makeQuestion('$a − $b', a - b, difficulty);
  }

  _CalcQuestion _simpleMultiply(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final a = _random.nextInt(max - 1) + 2;
    final b = _random.nextInt(max - 1) + 2;
    return _makeQuestion('$a × $b', a * b, difficulty);
  }

  _CalcQuestion _simpleDivide(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final divisor = _random.nextInt(max - 1) + 2;
    final quotient = _random.nextInt(max - 1) + 2;
    final dividend = divisor * quotient;
    return _makeQuestion('$dividend ÷ $divisor', quotient, difficulty);
  }

  _CalcQuestion? _combined(CognitiveDifficulty difficulty) {
    return switch (_random.nextInt(4)) {
      0 => _combinedAddSubtract(difficulty),
      1 => _combinedMultiplyAdd(difficulty),
      2 => _combinedAddMultiply(difficulty),
      _ => _combinedDivideAdd(difficulty),
    };
  }

  /// Operaciones encadenadas de suma y resta (de izquierda a derecha).
  _CalcQuestion? _combinedAddSubtract(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final a = _random.nextInt(max - 1) + 2;
    final b = _random.nextInt(max ~/ 2) + 1;
    final c = _random.nextInt(max ~/ 2) + 1;
    final subtractMiddle = _random.nextBool();

    if (subtractMiddle) {
      if (a < b) return null;
      final answer = a - b + c;
      if (answer < 0) return null;
      return _makeQuestion('$a − $b + $c', answer, difficulty);
    }

    final answer = a + b - c;
    if (answer < 0) return null;
    return _makeQuestion('$a + $b − $c', answer, difficulty);
  }

  /// Producto seguido de suma o resta.
  _CalcQuestion? _combinedMultiplyAdd(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final a = _random.nextInt(min(4, max - 1)) + 2;
    final b = _random.nextInt(min(4, max - 1)) + 2;
    final c = _random.nextInt(max) + 1;
    final product = a * b;

    if (_random.nextBool()) {
      return _makeQuestion('$a × $b + $c', product + c, difficulty);
    }

    if (product <= c) return null;
    return _makeQuestion('$a × $b − $c', product - c, difficulty);
  }

  /// Suma seguida de un producto.
  _CalcQuestion? _combinedAddMultiply(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final a = _random.nextInt(max) + 1;
    final b = _random.nextInt(min(4, max - 1)) + 2;
    final c = _random.nextInt(min(4, max - 1)) + 2;
    return _makeQuestion('$a + $b × $c', a + b * c, difficulty);
  }

  /// División exacta seguida de suma o resta.
  _CalcQuestion? _combinedDivideAdd(CognitiveDifficulty difficulty) {
    final max = ActivityDifficultyConfig.calculationMaxOperand(difficulty);
    final divisor = _random.nextInt(min(4, max - 1)) + 2;
    final quotient = _random.nextInt(min(4, max - 1)) + 2;
    final dividend = divisor * quotient;
    final c = _random.nextInt(max) + 1;

    if (_random.nextBool()) {
      return _makeQuestion('$dividend ÷ $divisor + $c', quotient + c, difficulty);
    }

    if (quotient <= c) return null;
    return _makeQuestion('$dividend ÷ $divisor − $c', quotient - c, difficulty);
  }

  _CalcQuestion _makeQuestion(
    String prompt,
    int answer,
    CognitiveDifficulty difficulty,
  ) {
    return _CalcQuestion(
      prompt: prompt,
      correctAnswer: answer,
      options: _buildOptions(answer, difficulty),
    );
  }

  List<int> _buildOptions(int correct, CognitiveDifficulty difficulty) {
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final options = <int>{correct};
    final upperBound = max(20, correct + 6);

    for (final offset in [-4, -3, -2, -1, 1, 2, 3, 4, 5, 6]) {
      if (options.length >= optionCount) break;
      final candidate = correct + offset;
      if (candidate >= 0 && candidate <= upperBound) {
        options.add(candidate);
      }
    }

    while (options.length < optionCount) {
      final candidate = _random.nextInt(upperBound + 1);
      options.add(candidate);
    }

    return options.toList()..shuffle(_random);
  }

  String _difficultyDescription(CognitiveDifficulty difficulty) {
    return switch (difficulty) {
      CognitiveDifficulty.suave => 'Sumas con números pequeños',
      CognitiveDifficulty.medio => 'Sumas y restas',
      CognitiveDifficulty.intenso =>
        'Sumas, restas, multiplicaciones, divisiones y operaciones combinadas',
    };
  }

  Future<void> _answer(int value) async {
    if (_answered || _finished) return;

    final question = _questions[_index];
    setState(() {
      _answered = true;
      if (value == question.correctAnswer) _score += _pointsPerRound;
    });

    if (_index == _questions.length - 1) {
      final difficulty = ref.read(cognitiveDifficultyProvider);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.calculo,
        score: min(_score, 100),
        durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
          difficulty,
          _questions.length,
        ),
      );
      if (!mounted) return;
      setState(() => _finished = true);
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _index++;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _finished = false;
      _answered = false;
      _questions = _generateQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next) {
        _restart();
      }
    });

    final theme = Theme.of(context);
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    final question = _questions[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo sencillo'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _finished
                  ? 'Ejercicio completado. Puntuación: ${min(_score, 100)}'
                  : 'Pregunta ${_index + 1} de ${_questions.length}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!_finished)
              Text(
                _difficultyDescription(difficulty),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '¿Cuánto es ${question.prompt}?',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: question.options.map((option) {
                return SizedBox(
                  width: 88,
                  height: 88,
                  child: ElevatedButton(
                    onPressed:
                        _answered || _finished ? null : () => _answer(option),
                    child: Text('$option', style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            if (_finished) ...[
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _restart,
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

class _CalcQuestion {
  const _CalcQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  final String prompt;
  final int correctAnswer;
  final List<int> options;
}
