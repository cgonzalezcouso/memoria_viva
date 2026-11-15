import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

abstract final class SequenceCatalog {
  static const tasks = [
    _SequenceTask(
      title: 'Preparar un té',
      steps: ['Hervir agua', 'Poner la bolsita', 'Verter agua', 'Esperar y retirar'],
    ),
    _SequenceTask(
      title: 'Lavarse las manos',
      steps: ['Mojar manos', 'Poner jabón', 'Frotar', 'Enjuagar y secar'],
    ),
    _SequenceTask(
      title: 'Cepillarse los dientes',
      steps: [
        'Mojar el cepillo',
        'Poner pasta dental',
        'Cepillar dientes',
        'Enjuagar la boca',
      ],
    ),
    _SequenceTask(
      title: 'Hacer la cama',
      steps: [
        'Quitar las mantas',
        'Estirar la sábana',
        'Colocar la funda',
        'Ordenar las almohadas',
      ],
    ),
    _SequenceTask(
      title: 'Vestirse por la mañana',
      steps: [
        'Poner ropa interior',
        'Poner la camisa',
        'Poner el pantalón',
        'Calzar los zapatos',
      ],
    ),
    _SequenceTask(
      title: 'Preparar un café',
      steps: [
        'Llenar la cafetera de agua',
        'Añadir café molido',
        'Encender la cafetera',
        'Servir en la taza',
      ],
    ),
    _SequenceTask(
      title: 'Salir de casa',
      steps: [
        'Recoger las llaves',
        'Cerrar las ventanas',
        'Ponerse el abrigo',
        'Cerrar la puerta',
      ],
    ),
    _SequenceTask(
      title: 'Poner la mesa',
      steps: [
        'Colocar el mantel',
        'Poner los platos',
        'Poner los cubiertos',
        'Poner los vasos',
      ],
    ),
    _SequenceTask(
      title: 'Lavar los platos',
      steps: [
        'Quitar restos de comida',
        'Fregar con jabón',
        'Aclarar con agua',
        'Secar y guardar',
      ],
    ),
    _SequenceTask(
      title: 'Comprar en la tienda',
      steps: [
        'Hacer la lista',
        'Coger la cesta',
        'Elegir los productos',
        'Pagar en caja',
      ],
    ),
    _SequenceTask(
      title: 'Tomar una medicina',
      steps: [
        'Leer la etiqueta',
        'Servir el vaso de agua',
        'Tomar la pastilla',
        'Guardar el medicamento',
      ],
    ),
    _SequenceTask(
      title: 'Regar las plantas',
      steps: [
        'Llenar la regadera',
        'Comprobar la tierra',
        'Echar agua con cuidado',
        'Vaciar el plato si sobra',
      ],
    ),
    _SequenceTask(
      title: 'Preparar un bocadillo',
      steps: [
        'Sacar el pan',
        'Untar mantequilla',
        'Añadir el relleno',
        'Cortar y servir',
      ],
    ),
    _SequenceTask(
      title: 'Llamar por teléfono',
      steps: [
        'Coger el teléfono',
        'Buscar el contacto',
        'Marcar el número',
        'Saludar y hablar',
      ],
    ),
    _SequenceTask(
      title: 'Ordenar la habitación',
      steps: [
        'Recoger la ropa',
        'Guardar los objetos',
        'Pasar la aspiradora',
        'Ventilar la estancia',
      ],
    ),
  ];
}

class SequenceExerciseScreen extends ConsumerStatefulWidget {
  const SequenceExerciseScreen({super.key});

  @override
  ConsumerState<SequenceExerciseScreen> createState() =>
      _SequenceExerciseScreenState();
}

class _SequenceExerciseScreenState extends ConsumerState<SequenceExerciseScreen> {
  final _random = Random();
  late List<_SequenceTask> _tasks;
  late _SequenceTask _task;
  late List<String> _shuffled;
  final List<String> _selected = [];
  int _index = 0;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final difficulty = ref.read(cognitiveDifficultyProvider);
    _tasks = _generateSession(difficulty);
    _startRound();
  }

  List<_SequenceTask> _generateSession(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final stepCount = ActivityDifficultyConfig.sequenceSteps(difficulty);
    final pool = [...SequenceCatalog.tasks]..shuffle(_random);

    return pool.take(min(rounds, pool.length)).map((task) {
      return _SequenceTask(
        title: task.title,
        steps: task.steps.take(stepCount).toList(),
      );
    }).toList();
  }

  void _startRound() {
    _task = _tasks[_index];
    _shuffled = [..._task.steps]..shuffle(_random);
    _selected.clear();
  }

  Future<void> _selectStep(String step) async {
    if (_finished || _selected.contains(step)) return;
    final difficulty = ref.read(cognitiveDifficultyProvider);

    setState(() => _selected.add(step));

    if (_selected.length < _task.steps.length) return;

    if (_listsEqual(_selected, _task.steps)) {
      _score += ActivityDifficultyConfig.pointsPerRound(_tasks.length);
    }

    if (_index >= _tasks.length - 1) {
      setState(() => _finished = true);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.secuencias,
        score: min(_score, 100),
        durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
          difficulty,
          _tasks.length,
        ),
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _index++;
      _startRound();
    });
  }

  void _restart(CognitiveDifficulty difficulty) {
    setState(() {
      _index = 0;
      _score = 0;
      _finished = false;
      _tasks = _generateSession(difficulty);
      _startRound();
    });
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next && mounted) _restart(next);
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orden de secuencias'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _finished
                  ? 'Sesión completada. Puntuación: ${min(_score, 100)}'
                  : 'Ronda ${_index + 1} de ${_tasks.length}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _task.title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca los pasos en el orden correcto',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_selected.isNotEmpty) ...[
              Text('Tu orden:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selected
                    .asMap()
                    .entries
                    .map(
                      (entry) => Chip(
                        label: Text('${entry.key + 1}. ${entry.value}'),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: ListView(
                children: _shuffled
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          onPressed: _finished || _selected.contains(step)
                              ? null
                              : () => _selectStep(step),
                          child: Text(step),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (_finished)
              ElevatedButton(
                onPressed: () => _restart(difficulty),
                child: const Text('Jugar de nuevo'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SequenceTask {
  const _SequenceTask({required this.title, required this.steps});

  final String title;
  final List<String> steps;
}
