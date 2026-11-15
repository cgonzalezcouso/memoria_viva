import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

abstract final class CategoryCatalog {
  static const items = [
    _CategoryItem(word: 'Manzana', category: 'Fruta'),
    _CategoryItem(word: 'Plátano', category: 'Fruta'),
    _CategoryItem(word: 'Naranja', category: 'Fruta'),
    _CategoryItem(word: 'Lechuga', category: 'Verdura'),
    _CategoryItem(word: 'Zanahoria', category: 'Verdura'),
    _CategoryItem(word: 'Tomate', category: 'Verdura'),
    _CategoryItem(word: 'Perro', category: 'Animal'),
    _CategoryItem(word: 'Gato', category: 'Animal'),
    _CategoryItem(word: 'Caballo', category: 'Animal'),
    _CategoryItem(word: 'Pájaro', category: 'Animal'),
    _CategoryItem(word: 'Silla', category: 'Mueble'),
    _CategoryItem(word: 'Mesa', category: 'Mueble'),
    _CategoryItem(word: 'Cama', category: 'Mueble'),
    _CategoryItem(word: 'Armario', category: 'Mueble'),
    _CategoryItem(word: 'Camisa', category: 'Ropa'),
    _CategoryItem(word: 'Pantalón', category: 'Ropa'),
    _CategoryItem(word: 'Zapatos', category: 'Ropa'),
    _CategoryItem(word: 'Sombrero', category: 'Ropa'),
    _CategoryItem(word: 'Pan', category: 'Comida'),
    _CategoryItem(word: 'Arroz', category: 'Comida'),
    _CategoryItem(word: 'Sopa', category: 'Comida'),
    _CategoryItem(word: 'Queso', category: 'Comida'),
    _CategoryItem(word: 'Coche', category: 'Transporte'),
    _CategoryItem(word: 'Autobús', category: 'Transporte'),
    _CategoryItem(word: 'Bicicleta', category: 'Transporte'),
    _CategoryItem(word: 'Tren', category: 'Transporte'),
    _CategoryItem(word: 'Martillo', category: 'Herramienta'),
    _CategoryItem(word: 'Tijeras', category: 'Herramienta'),
    _CategoryItem(word: 'Destornillador', category: 'Herramienta'),
    _CategoryItem(word: 'Pelota', category: 'Deporte'),
    _CategoryItem(word: 'Raqueta', category: 'Deporte'),
    _CategoryItem(word: 'Balón', category: 'Deporte'),
    _CategoryItem(word: 'Mano', category: 'Parte del cuerpo'),
    _CategoryItem(word: 'Ojo', category: 'Parte del cuerpo'),
    _CategoryItem(word: 'Pierna', category: 'Parte del cuerpo'),
    _CategoryItem(word: 'Corazón', category: 'Parte del cuerpo'),
    _CategoryItem(word: 'Médico', category: 'Profesión'),
    _CategoryItem(word: 'Profesor', category: 'Profesión'),
    _CategoryItem(word: 'Panadero', category: 'Profesión'),
    _CategoryItem(word: 'Hospital', category: 'Lugar'),
    _CategoryItem(word: 'Escuela', category: 'Lugar'),
    _CategoryItem(word: 'Parque', category: 'Lugar'),
    _CategoryItem(word: 'Playa', category: 'Lugar'),
    _CategoryItem(word: 'Guitarra', category: 'Instrumento musical'),
    _CategoryItem(word: 'Piano', category: 'Instrumento musical'),
    _CategoryItem(word: 'Tambor', category: 'Instrumento musical'),
  ];

  static List<String> get categories =>
      items.map((item) => item.category).toSet().toList();
}

class CategoryExerciseScreen extends ConsumerStatefulWidget {
  const CategoryExerciseScreen({super.key});

  @override
  ConsumerState<CategoryExerciseScreen> createState() =>
      _CategoryExerciseScreenState();
}

class _CategoryExerciseScreenState extends ConsumerState<CategoryExerciseScreen> {
  final _random = Random();
  late List<_CategoryRound> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(ref.read(cognitiveDifficultyProvider));
  }

  List<_CategoryRound> _generateQuestions(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final pool = [...CategoryCatalog.items]..shuffle(_random);
    final selected = pool.take(min(rounds, pool.length));
    final allCategories = CategoryCatalog.categories;

    return selected.map((item) {
      final distractors = allCategories
          .where((category) => category != item.category)
          .toList()
        ..shuffle(_random);

      final options = [
        item.category,
        ...distractors.take(optionCount - 1),
      ]..shuffle(_random);

      return _CategoryRound(
        word: item.word,
        correct: item.category,
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
        activityType: CognitiveActivityType.categorias,
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
    final question = _questions[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asociación de categorías'),
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
              '¿A qué categoría pertenece?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  question.word,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
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

class _CategoryItem {
  const _CategoryItem({required this.word, required this.category});

  final String word;
  final String category;
}

class _CategoryRound {
  const _CategoryRound({
    required this.word,
    required this.correct,
    required this.options,
  });

  final String word;
  final String correct;
  final List<String> options;
}
