import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class RecallExerciseScreen extends ConsumerStatefulWidget {
  const RecallExerciseScreen({super.key});

  @override
  ConsumerState<RecallExerciseScreen> createState() =>
      _RecallExerciseScreenState();
}

class _RecallExerciseScreenState extends ConsumerState<RecallExerciseScreen> {
  static const _itemPool = [
    '🍎',
    '🌻',
    '🔑',
    '📖',
    '☂️',
    '🎵',
    '🐶',
    '🏠',
    '🌙',
    '⭐',
    '🎂',
    '🚗',
    '🌳',
    '🔔',
    '👓',
    '🧢',
    '⚽',
    '🍞',
    '☕',
    '🎁',
  ];

  final _random = Random();
  late List<String> _itemsToRemember;
  late List<String> _quizOptions;
  late String _correctItem;
  bool _showingItems = true;
  bool _timerStarted = false;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  int _totalRounds(CognitiveDifficulty difficulty) =>
      ActivityDifficultyConfig.rounds(difficulty);

  @override
  void initState() {
    super.initState();
    _startRound(ref.read(cognitiveDifficultyProvider));
  }

  void _startRound(CognitiveDifficulty difficulty) {
    final itemsPerRound = ActivityDifficultyConfig.recallItems(difficulty);
    final pool = [..._itemPool]..shuffle(_random);
    _itemsToRemember = pool.take(itemsPerRound).toList();
    _correctItem = _itemsToRemember[_random.nextInt(_itemsToRemember.length)];
    _quizOptions = {..._itemsToRemember, pool[itemsPerRound]}.toList()
      ..shuffle(_random);
    _showingItems = true;
    _timerStarted = false;
  }

  Future<void> _showQuiz(CognitiveDifficulty difficulty) async {
    final seconds = ActivityDifficultyConfig.recallDisplaySeconds(difficulty);
    await Future<void>.delayed(Duration(seconds: seconds));
    if (!mounted) return;
    setState(() => _showingItems = false);
  }

  Future<void> _answer(String item) async {
    if (_showingItems || _finished) return;
    final difficulty = ref.read(cognitiveDifficultyProvider);
    final totalRounds = _totalRounds(difficulty);

    if (item == _correctItem) {
      _score += ActivityDifficultyConfig.pointsPerRound(totalRounds);
    }

    if (_index >= totalRounds - 1) {
      setState(() => _finished = true);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.recuerdo,
        score: min(_score, 100),
        durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
          difficulty,
          totalRounds,
        ),
      );
      return;
    }

    setState(() {
      _index++;
      _startRound(difficulty);
    });
    _showQuiz(difficulty);
  }

  void _restart(CognitiveDifficulty difficulty) {
    setState(() {
      _index = 0;
      _score = 0;
      _finished = false;
      _startRound(difficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next && mounted) _restart(next);
    });

    final theme = Theme.of(context);
    final totalRounds = _totalRounds(difficulty);

    if (_showingItems && !_finished && !_timerStarted) {
      _timerStarted = true;
      _showQuiz(difficulty);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria inmediata'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _finished
                  ? 'Puntuación: ${min(_score, 100)}'
                  : _showingItems
                      ? 'Ronda ${_index + 1} de $totalRounds — '
                          'Memoriza estos objetos'
                      : 'Ronda ${_index + 1} de $totalRounds — '
                          '¿Cuál viste?',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_showingItems && !_finished)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _itemsToRemember
                    .map(
                      (item) => Text(item, style: const TextStyle(fontSize: 64)),
                    )
                    .toList(),
              )
            else if (!_finished) ...[
              Text(
                'Selecciona el objeto que apareció',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _quizOptions.map((item) {
                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: ElevatedButton(
                      onPressed: () => _answer(item),
                      child: Text(item, style: const TextStyle(fontSize: 40)),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (_finished) ...[
              const Spacer(),
              ElevatedButton(
                onPressed: () => _restart(difficulty),
                child: const Text('Jugar de nuevo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
