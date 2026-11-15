import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class OrientationExerciseScreen extends ConsumerStatefulWidget {
  const OrientationExerciseScreen({super.key});

  @override
  ConsumerState<OrientationExerciseScreen> createState() =>
      _OrientationExerciseScreenState();
}

class _OrientationExerciseScreenState
    extends ConsumerState<OrientationExerciseScreen> {
  final _random = Random();
  late final DateTime _now;
  late List<_OrientationQuestion> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _questions = _buildQuestions(_now, ref.read(cognitiveDifficultyProvider));
  }

  List<_OrientationQuestion> _buildQuestions(
    DateTime date,
    CognitiveDifficulty difficulty,
  ) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final distractorCount = ActivityDifficultyConfig.optionCount(difficulty) - 1;

    final questions = <_OrientationQuestion>[
      _weekdayQuestion(date, distractorCount),
      _monthQuestion(date, distractorCount),
      _momentQuestion(date, distractorCount),
      _yearQuestion(date, distractorCount),
      _seasonQuestion(date, distractorCount),
      _dayOfMonthQuestion(date, distractorCount),
      _yesterdayWeekdayQuestion(date, distractorCount),
      _tomorrowWeekdayQuestion(date, distractorCount),
      _previousMonthQuestion(date, distractorCount),
      _nextMonthQuestion(date, distractorCount),
    ]..shuffle(_random);

    return questions.take(rounds).toList();
  }

  _OrientationQuestion _weekdayQuestion(DateTime date, int distractorCount) {
    final weekday = _capitalize(DateFormat.EEEE('es').format(date));
    final wrong = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ]..remove(weekday.toLowerCase());

    return _OrientationQuestion(
      prompt: '¿Qué día de la semana es hoy?',
      correctAnswer: weekday,
      options: _shuffleOptions(
        weekday,
        wrong.take(distractorCount).map(_capitalize).toList(),
      ),
    );
  }

  _OrientationQuestion _monthQuestion(DateTime date, int distractorCount) {
    final month = _capitalize(DateFormat.MMMM('es').format(date));
    final wrong = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ]..remove(month.toLowerCase());

    return _OrientationQuestion(
      prompt: '¿En qué mes estamos?',
      correctAnswer: month,
      options: _shuffleOptions(
        month,
        wrong.take(distractorCount).map(_capitalize).toList(),
      ),
    );
  }

  _OrientationQuestion _momentQuestion(DateTime date, int distractorCount) {
    final hour = date.hour;
    final moment = hour < 12
        ? 'mañana'
        : hour < 19
            ? 'tarde'
            : 'noche';
    final capitalized = _capitalize(moment);
    final wrong = ['Mañana', 'Tarde', 'Noche']..remove(capitalized);

    return _OrientationQuestion(
      prompt: '¿Qué momento del día es ahora?',
      correctAnswer: capitalized,
      options: _shuffleOptions(
        capitalized,
        wrong.take(distractorCount).toList(),
      ),
    );
  }

  _OrientationQuestion _yearQuestion(DateTime date, int distractorCount) {
    final year = '${date.year}';
    final yearNum = date.year;
    final wrong = [
      '${yearNum - 1}',
      '${yearNum + 1}',
      '${yearNum - 2}',
    ];

    return _OrientationQuestion(
      prompt: '¿En qué año estamos?',
      correctAnswer: year,
      options: _shuffleOptions(year, wrong.take(distractorCount).toList()),
    );
  }

  _OrientationQuestion _seasonQuestion(DateTime date, int distractorCount) {
    final season = _capitalize(_seasonForMonth(date.month));
    final wrong = ['Primavera', 'Verano', 'Otoño', 'Invierno']..remove(season);

    return _OrientationQuestion(
      prompt: '¿En qué estación del año estamos?',
      correctAnswer: season,
      options: _shuffleOptions(season, wrong.take(distractorCount).toList()),
    );
  }

  _OrientationQuestion _dayOfMonthQuestion(DateTime date, int distractorCount) {
    final day = '${date.day}';
    final wrong = <String>[];
    for (final offset in [-2, -1, 1, 2, 3]) {
      final candidate = date.day + offset;
      if (candidate >= 1 && candidate <= 31 && candidate != date.day) {
        wrong.add('$candidate');
      }
      if (wrong.length >= distractorCount) break;
    }

    return _OrientationQuestion(
      prompt: '¿Qué día del mes es hoy?',
      correctAnswer: day,
      options: _shuffleOptions(day, wrong),
    );
  }

  _OrientationQuestion _yesterdayWeekdayQuestion(
    DateTime date,
    int distractorCount,
  ) {
    final yesterday = date.subtract(const Duration(days: 1));
    final weekday = _capitalize(DateFormat.EEEE('es').format(yesterday));
    final wrong = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ]..remove(weekday.toLowerCase());

    return _OrientationQuestion(
      prompt: '¿Qué día de la semana fue ayer?',
      correctAnswer: weekday,
      options: _shuffleOptions(
        weekday,
        wrong.take(distractorCount).map(_capitalize).toList(),
      ),
    );
  }

  _OrientationQuestion _tomorrowWeekdayQuestion(
    DateTime date,
    int distractorCount,
  ) {
    final tomorrow = date.add(const Duration(days: 1));
    final weekday = _capitalize(DateFormat.EEEE('es').format(tomorrow));
    final wrong = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ]..remove(weekday.toLowerCase());

    return _OrientationQuestion(
      prompt: '¿Qué día de la semana será mañana?',
      correctAnswer: weekday,
      options: _shuffleOptions(
        weekday,
        wrong.take(distractorCount).map(_capitalize).toList(),
      ),
    );
  }

  _OrientationQuestion _previousMonthQuestion(
    DateTime date,
    int distractorCount,
  ) {
    final previous = DateTime(date.year, date.month - 1, 1);
    final month = _capitalize(DateFormat.MMMM('es').format(previous));
    final wrong = _monthOptions()..remove(month.toLowerCase());

    return _OrientationQuestion(
      prompt: '¿Qué mes fue el anterior?',
      correctAnswer: month,
      options: _shuffleOptions(
        month,
        wrong.take(distractorCount).map(_capitalize).toList(),
      ),
    );
  }

  _OrientationQuestion _nextMonthQuestion(DateTime date, int distractorCount) {
    final next = DateTime(date.year, date.month + 1, 1);
    final month = _capitalize(DateFormat.MMMM('es').format(next));
    final wrong = _monthOptions()..remove(month.toLowerCase());

    return _OrientationQuestion(
      prompt: '¿Cuál es el mes siguiente?',
      correctAnswer: month,
      options: _shuffleOptions(
        month,
        wrong.take(distractorCount).map(_capitalize).toList(),
      ),
    );
  }

  List<String> _monthOptions() => [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];

  String _seasonForMonth(int month) {
    return switch (month) {
      12 || 1 || 2 => 'invierno',
      3 || 4 || 5 => 'primavera',
      6 || 7 || 8 => 'verano',
      _ => 'otoño',
    };
  }

  List<String> _shuffleOptions(String correct, List<String> wrong) {
    final options = [correct, ...wrong]..shuffle(_random);
    return options;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _answer(String option) async {
    if (_finished) return;
    final difficulty = ref.read(cognitiveDifficultyProvider);

    if (option == _questions[_index].correctAnswer) {
      _score += ActivityDifficultyConfig.pointsPerRound(_questions.length);
    }

    if (_index == _questions.length - 1) {
      setState(() => _finished = true);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.orientacion,
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
      _questions = _buildQuestions(DateTime.now(), difficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next && mounted) _restart(next);
    });

    final theme = Theme.of(context);
    final question = _questions[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orientación temporal'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _finished
                  ? 'Ejercicio completado. Puntuación: ${min(_score, 100)}'
                  : 'Pregunta ${_index + 1} de ${_questions.length}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              question.prompt,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...question.options.map(
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

class _OrientationQuestion {
  const _OrientationQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  final String prompt;
  final String correctAnswer;
  final List<String> options;
}
