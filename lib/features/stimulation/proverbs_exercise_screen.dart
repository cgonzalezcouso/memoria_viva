import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/activity_difficulty_config.dart';
import '../../core/models/cognitive_activity_type.dart';
import '../../core/models/cognitive_difficulty.dart';
import '../../core/providers/cognitive_difficulty_provider.dart';
import 'cognitive_session_helper.dart';
import 'widgets/difficulty_selector_card.dart';

class ProverbsExerciseScreen extends ConsumerStatefulWidget {
  const ProverbsExerciseScreen({super.key});

  @override
  ConsumerState<ProverbsExerciseScreen> createState() => _ProverbsExerciseScreenState();
}

class _ProverbsExerciseScreenState extends ConsumerState<ProverbsExerciseScreen> {
  static const _allProverbs = [
    _ProverbRound(
      beginning: 'A caballo regalado...',
      ending: 'no le mires el dentado',
      options: ['no le mires el dentado', 'corre muy rápido', 'tiene buena herradura'],
    ),
    _ProverbRound(
      beginning: 'Al mal tiempo...',
      ending: 'buena cara',
      options: ['buena cara', 'paraguas grande', 'abrígate bien'],
    ),
    _ProverbRound(
      beginning: 'Más vale pájaro en mano...',
      ending: 'que ciento volando',
      options: ['que ciento volando', 'que jaula vacía', 'que gato hambriento'],
    ),
    _ProverbRound(
      beginning: 'No por mucho madrugar...',
      ending: 'amanece más temprano',
      options: ['amanece más temprano', 'encuentras más dinero', 'te cansas menos'],
    ),
    _ProverbRound(
      beginning: 'Quien tiene un amigo...',
      ending: 'tiene un tesoro',
      options: ['tiene un tesoro', 'tiene un hermano', 'nunca está solo'],
    ),
    _ProverbRound(
      beginning: 'Perro ladrador...',
      ending: 'poco mordedor',
      options: ['poco mordedor', 'buen guardián', 'corre veloz'],
    ),
    _ProverbRound(
      beginning: 'Dime con quién andas...',
      ending: 'y te diré quién eres',
      options: ['y te diré quién eres', 'y sabré adónde vas', 'y andaremos juntos'],
    ),
    _ProverbRound(
      beginning: 'A quien madruga...',
      ending: 'Dios le ayuda',
      options: ['Dios le ayuda', 'le da sueño', 'desayuna temprano'],
    ),
    _ProverbRound(
      beginning: 'En boca cerrada...',
      ending: 'no entran moscas',
      options: ['no entran moscas', 'se guardan secretos', 'sale el silencio'],
    ),
    _ProverbRound(
      beginning: 'Más vale tarde...',
      ending: 'que nunca',
      options: ['que nunca', 'que a prisa', 'que ayer'],
    ),
    _ProverbRound(
      beginning: 'Agua que no has de beber...',
      ending: 'déjala correr',
      options: ['déjala correr', 'guárdala bien', 'mézclala con vino'],
    ),
    _ProverbRound(
      beginning: 'Cría cuervos...',
      ending: 'y te sacarán los ojos',
      options: ['y te sacarán los ojos', 'y volarán lejos', 'y te harán compañía'],
    ),
    _ProverbRound(
      beginning: 'Del dicho al hecho...',
      ending: 'hay mucho trecho',
      options: ['hay mucho trecho', 'no hay distancia', 'solo un paso'],
    ),
    _ProverbRound(
      beginning: 'Camarón que se duerme...',
      ending: 'se lo lleva la corriente',
      options: ['se lo lleva la corriente', 'despierta tarde', 'nada muy despacio'],
    ),
    _ProverbRound(
      beginning: 'El que mucho abarca...',
      ending: 'poco aprieta',
      options: ['poco aprieta', 'mucho consigue', 'siempre gana'],
    ),
    _ProverbRound(
      beginning: 'Cuando el río suena...',
      ending: 'agua lleva',
      options: ['agua lleva', 'llueve pronto', 'hay tormenta'],
    ),
    _ProverbRound(
      beginning: 'Hierba mala...',
      ending: 'nunca muere',
      options: ['nunca muere', 'crece despacio', 'se seca pronto'],
    ),
    _ProverbRound(
      beginning: 'Más sabe el diablo por viejo...',
      ending: 'que por diablo',
      options: ['que por diablo', 'que por listo', 'que por tonto'],
    ),
    _ProverbRound(
      beginning: 'Ladrón que roba a ladrón...',
      ending: 'tiene cien años de perdón',
      options: ['tiene cien años de perdón', 'siempre es pillado', 'nunca gana nada'],
    ),
    _ProverbRound(
      beginning: 'Mal de muchos...',
      ending: 'consuelo de tontos',
      options: ['consuelo de tontos', 'alegría de todos', 'culpa de uno'],
    ),
    _ProverbRound(
      beginning: 'Quien siembra vientos...',
      ending: 'recoge tempestades',
      options: ['recoge tempestades', 'cosecha trigo', 'gana amigos'],
    ),
    _ProverbRound(
      beginning: 'Quien calla...',
      ending: 'otorga',
      options: ['otorga', 'miente', 'duda siempre'],
    ),
    _ProverbRound(
      beginning: 'Genio y figura...',
      ending: 'hasta la sepultura',
      options: ['hasta la sepultura', 'poco dura', 'cambia con los años'],
    ),
    _ProverbRound(
      beginning: 'Hasta el cuarenta de mayo...',
      ending: 'no te quites el sayo',
      options: ['no te quites el sayo', 'verano ha llegado', 'llueve poco'],
    ),
  ];

  final _random = Random();
  late List<_ProverbRound> _gameRounds;
  int _index = 0;
  int _score = 0;
  bool _finished = false;
  String? _selectedOption;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _startNewGame(ref.read(cognitiveDifficultyProvider));
  }

  void _startNewGame(CognitiveDifficulty difficulty) {
    final rounds = ActivityDifficultyConfig.rounds(difficulty);
    final list = [..._allProverbs]..shuffle(_random);
    _gameRounds = list.take(min(rounds, list.length)).map((round) {
      final shuffledOptions = [...round.options]..shuffle(_random);
      return _ProverbRound(
        beginning: round.beginning,
        ending: round.ending,
        options: shuffledOptions,
      );
    }).toList();
    _index = 0;
    _score = 0;
    _finished = false;
    _selectedOption = null;
    _hasAnswered = false;
  }

  Future<void> _selectOption(String option) async {
    if (_hasAnswered) return;

    setState(() {
      _selectedOption = option;
      _hasAnswered = true;
    });

    final currentRound = _gameRounds[_index];
    final isCorrect = option == currentRound.ending;

    setState(() {
      if (isCorrect) {
        _score += ActivityDifficultyConfig.pointsPerRound(_gameRounds.length);
      }
    });
  }

  Future<void> _nextStep() async {
    if (_index == _gameRounds.length - 1) {
      final difficulty = ref.read(cognitiveDifficultyProvider);
      setState(() => _finished = true);
      await saveCognitiveSession(
        ref,
        activityType: CognitiveActivityType.refranes,
        score: min(_score, 100),
        durationSeconds: ActivityDifficultyConfig.sessionDurationSeconds(
          difficulty,
          _gameRounds.length,
        ),
      );
      return;
    }

    setState(() {
      _index++;
      _selectedOption = null;
      _hasAnswered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(cognitiveDifficultyProvider);
    ref.listen(cognitiveDifficultyProvider, (previous, next) {
      if (previous != next && mounted) _startNewGame(next);
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_finished) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Completar refranes'),
          actions: const [ExerciseDifficultyBadge()],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  _score >= 80 ? Icons.emoji_events_outlined : Icons.star_outline_rounded,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Ejercicio completado!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu puntuación ha sido de:',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${min(_score, 100)} / 100',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _startNewGame(difficulty),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Repetir ejercicio'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver al menú'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentRound = _gameRounds[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar refranes'),
        actions: const [ExerciseDifficultyBadge()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_index + 1) / _gameRounds.length,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text(
                'Refrán ${_index + 1} de ${_gameRounds.length}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Prompt container
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Text(
                        currentRound.beginning,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_hasAnswered) ...[
                        const SizedBox(height: 16),
                        Text(
                          currentRound.ending,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Options list
              ...currentRound.options.map((option) {
                final isSelected = _selectedOption == option;
                final isCorrect = option == currentRound.ending;

                Color cardColor = theme.cardColor;
                Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
                BorderSide border = BorderSide(color: theme.colorScheme.outlineVariant);

                if (_hasAnswered) {
                  if (isCorrect) {
                    cardColor = Colors.green.shade100;
                    textColor = Colors.green.shade900;
                    border = const BorderSide(color: Colors.green, width: 2);
                  } else if (isSelected) {
                    cardColor = Colors.red.shade100;
                    textColor = Colors.red.shade900;
                    border = const BorderSide(color: Colors.red, width: 2);
                  }
                } else {
                  if (isSelected) {
                    cardColor = theme.colorScheme.primaryContainer;
                    textColor = theme.colorScheme.onPrimaryContainer;
                    border = BorderSide(color: theme.colorScheme.primary, width: 2);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: border,
                    ),
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: _hasAnswered ? null : () => _selectOption(option),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        child: Text(
                          option,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (_hasAnswered)
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _index == _gameRounds.length - 1 ? 'Finalizar' : 'Siguiente',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProverbRound {
  const _ProverbRound({
    required this.beginning,
    required this.ending,
    required this.options,
  });

  final String beginning;
  final String ending;
  final List<String> options;
}
