import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

abstract final class IntruderCatalog {
  static const rounds = [
    _IntruderRound(
      prompt: '¿Cuál no es una fruta?',
      correct: 'Silla',
      options: ['Manzana', 'Pera', 'Silla', 'Uva'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un animal?',
      correct: 'Mesa',
      options: ['Gato', 'Mesa', 'Perro', 'Pájaro'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es ropa?',
      correct: 'Coche',
      options: ['Camisa', 'Pantalón', 'Coche', 'Zapatos'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no pertenece al baño?',
      correct: 'Sofá',
      options: ['Toalla', 'Jabón', 'Sofá', 'Cepillo de dientes'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es una verdura?',
      correct: 'Reloj',
      options: ['Lechuga', 'Zanahoria', 'Reloj', 'Tomate'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un mueble?',
      correct: 'Plátano',
      options: ['Silla', 'Mesa', 'Plátano', 'Armario'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un medio de transporte?',
      correct: 'Ventana',
      options: ['Coche', 'Autobús', 'Ventana', 'Tren'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un instrumento musical?',
      correct: 'Cuchara',
      options: ['Guitarra', 'Piano', 'Cuchara', 'Tambor'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es una herramienta?',
      correct: 'Sandía',
      options: ['Martillo', 'Tijeras', 'Sandía', 'Destornillador'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es una profesión?',
      correct: 'Lámpara',
      options: ['Médico', 'Profesor', 'Lámpara', 'Panadero'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es una parte del cuerpo?',
      correct: 'Televisión',
      options: ['Mano', 'Ojo', 'Televisión', 'Pierna'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no pertenece a la cocina?',
      correct: 'Cama',
      options: ['Sartén', 'Olla', 'Cama', 'Cuchillo'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un deporte?',
      correct: 'Libro',
      options: ['Fútbol', 'Tenis', 'Libro', 'Natación'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un lugar?',
      correct: 'Calcetín',
      options: ['Hospital', 'Escuela', 'Calcetín', 'Parque'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un alimento?',
      correct: 'Paraguas',
      options: ['Pan', 'Arroz', 'Paraguas', 'Queso'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no pertenece al jardín?',
      correct: 'Televisor',
      options: ['Flor', 'Regadera', 'Televisor', 'Maceta'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un color?',
      correct: 'Silla',
      options: ['Rojo', 'Azul', 'Silla', 'Verde'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un día de la semana?',
      correct: 'Enero',
      options: ['Lunes', 'Martes', 'Enero', 'Viernes'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no es un mes del año?',
      correct: 'Domingo',
      options: ['Marzo', 'Julio', 'Domingo', 'Octubre'],
    ),
    _IntruderRound(
      prompt: '¿Cuál no pertenece al dormitorio?',
      correct: 'Microondas',
      options: ['Almohada', 'Manta', 'Microondas', 'Mesita de noche'],
    ),
  ];
}

class IntruderExerciseScreen extends ConsumerStatefulWidget {
  const IntruderExerciseScreen({super.key});

  @override
  ConsumerState<IntruderExerciseScreen> createState() =>
      _IntruderExerciseScreenState();
}

class _IntruderExerciseScreenState extends ConsumerState<IntruderExerciseScreen> {
  final _random = Random();
  late List<_IntruderRound> _questions;
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(ref.read(cognitiveDifficultyProvider));
  }

  List<_IntruderRound> _generateQuestions(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final optionCount = ActivityDifficultyConfig.optionCount(difficulty);
    final pool = [...IntruderCatalog.rounds]..shuffle(_random);

    return pool.take(min(rounds, pool.length)).map((round) {
      if (optionCount >= round.options.length) return round;
      final distractors =
          round.options.where((o) => o != round.correct).toList()..shuffle(_random);
      final options = [
        round.correct,
        ...distractors.take(optionCount - 1),
      ]..shuffle(_random);
      return _IntruderRound(
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
        activityType: CognitiveActivityType.intruso,
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
        title: const Text('Encuentra el intruso'),
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
              q.prompt,
              style: theme.textTheme.headlineMedium,
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

class _IntruderRound {
  const _IntruderRound({
    required this.prompt,
    required this.correct,
    required this.options,
  });

  final String prompt;
  final String correct;
  final List<String> options;
}
