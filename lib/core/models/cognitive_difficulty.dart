enum CognitiveDifficulty {
  suave,
  medio,
  intenso;

  String get label => switch (this) {
        suave => 'Suave',
        medio => 'Medio',
        intenso => 'Intenso',
      };

  String get shortDescription => switch (this) {
        suave => 'Deterioro marcado',
        medio => 'Deterioro moderado',
        intenso => 'Deterioro leve',
      };

  String get description => switch (this) {
        suave =>
          'Menos preguntas, más tiempo y menos opciones. '
          'Recomendado con deterioro cognitivo marcado.',
        medio =>
          'Equilibrio entre apoyo y reto. '
          'Recomendado con deterioro moderado.',
        intenso =>
          'Más preguntas, menos tiempo y más opciones. '
          'Recomendado con deterioro leve o mantenimiento.',
      };

  static CognitiveDifficulty fromStorage(String? value) {
    return CognitiveDifficulty.values.firstWhere(
      (level) => level.name == value,
      orElse: () => CognitiveDifficulty.medio,
    );
  }
}
