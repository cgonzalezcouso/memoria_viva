import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen> {
  static const _symbols = ['🍎', '🌻', '🐶', '🎵', '⭐', '🏠'];

  late List<String> _cards;
  final List<int> _flipped = [];
  final List<int> _matched = [];
  int _moves = 0;
  bool _busy = false;
  bool _completed = false;
  bool _initialized = false;
  int _gridColumns = 3;

  void _startNewGame() {
    final difficulty = ref.read(cognitiveDifficultyProvider);
    final pairs = ActivityDifficultyConfig.memoryPairs(difficulty);
    final symbols = _symbols.take(pairs).toList();
    _gridColumns = ActivityDifficultyConfig.memoryGridColumns(pairs);
    _cards = [...symbols, ...symbols]..shuffle(Random());
    _flipped.clear();
    _matched.clear();
    _moves = 0;
    _busy = false;
    _completed = false;
  }

  Future<void> _onCardTap(int index) async {
    if (_busy || _matched.contains(index) || _flipped.contains(index)) {
      return;
    }

    setState(() => _flipped.add(index));

    if (_flipped.length == 2) {
      _moves++;
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final first = _flipped[0];
      final second = _flipped[1];
      final isMatch = _cards[first] == _cards[second];

      setState(() {
        if (isMatch) {
          _matched.addAll([first, second]);
        }
        _flipped.clear();
        _busy = false;
        _completed = _matched.length == _cards.length;
      });

      if (_completed) {
        await _saveSession();
      }
    }
  }

  Future<void> _saveSession() async {
    final difficulty = ref.read(cognitiveDifficultyProvider);
    final pairs = ActivityDifficultyConfig.memoryPairs(difficulty);
    await saveCognitiveSession(
      ref,
      activityType: CognitiveActivityType.memoria,
      score: max(0, 100 - (_moves * 5)),
      durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
        difficulty,
        pairs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      _startNewGame();
    }

    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next) {
        setState(_startNewGame);
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego de memoria'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _completed
                  ? '¡Muy bien! Completaste el juego.'
                  : 'Encuentra las parejas. Movimientos: $_moves',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridColumns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final isVisible =
                      _flipped.contains(index) || _matched.contains(index);

                  return Semantics(
                    button: true,
                    label: isVisible ? 'Carta ${_cards[index]}' : 'Carta oculta',
                    child: Material(
                      color: isVisible
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _onCardTap(index),
                        child: Center(
                          child: Text(
                            isVisible ? _cards[index] : '?',
                            style: TextStyle(
                              fontSize: isVisible ? 40 : 28,
                              color: isVisible
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(_startNewGame),
                child: const Text('Nuevo juego'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
