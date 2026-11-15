import '../models/cognitive_difficulty.dart';

abstract final class ActivityDifficultyConfig {
  static int rounds(CognitiveDifficulty difficulty) => switch (difficulty) {
        CognitiveDifficulty.suave => 5,
        CognitiveDifficulty.medio => 7,
        CognitiveDifficulty.intenso => 10,
      };

  static int optionCount(CognitiveDifficulty difficulty) => switch (difficulty) {
        CognitiveDifficulty.suave => 3,
        CognitiveDifficulty.medio => 3,
        CognitiveDifficulty.intenso => 4,
      };

  static int pointsPerRound(int totalRounds) =>
      totalRounds == 0 ? 0 : (100 / totalRounds).round();

  static int memoryPairs(CognitiveDifficulty difficulty) => switch (difficulty) {
        CognitiveDifficulty.suave => 3,
        CognitiveDifficulty.medio => 4,
        CognitiveDifficulty.intenso => 6,
      };

  static int memoryGridColumns(int pairs) => pairs <= 3 ? 3 : 4;

  static int recallItems(CognitiveDifficulty difficulty) => switch (difficulty) {
        CognitiveDifficulty.suave => 2,
        CognitiveDifficulty.medio => 3,
        CognitiveDifficulty.intenso => 4,
      };

  static int recallDisplaySeconds(CognitiveDifficulty difficulty) =>
      switch (difficulty) {
        CognitiveDifficulty.suave => 6,
        CognitiveDifficulty.medio => 4,
        CognitiveDifficulty.intenso => 3,
      };

  static int attentionDots(CognitiveDifficulty difficulty) => switch (difficulty) {
        CognitiveDifficulty.suave => 8,
        CognitiveDifficulty.medio => 12,
        CognitiveDifficulty.intenso => 16,
      };

  static int attentionMaxTarget(CognitiveDifficulty difficulty) =>
      switch (difficulty) {
        CognitiveDifficulty.suave => 3,
        CognitiveDifficulty.medio => 4,
        CognitiveDifficulty.intenso => 5,
      };

  static int sequenceSteps(CognitiveDifficulty difficulty) => switch (difficulty) {
        CognitiveDifficulty.suave => 3,
        CognitiveDifficulty.medio => 4,
        CognitiveDifficulty.intenso => 5,
      };

  static int familyDistractors(CognitiveDifficulty difficulty) =>
      optionCount(difficulty) - 1;

  static bool calculationAllowSubtract(CognitiveDifficulty difficulty) =>
      difficulty != CognitiveDifficulty.suave;

  static bool calculationAllowMultiply(CognitiveDifficulty difficulty) =>
      difficulty == CognitiveDifficulty.intenso;

  static bool calculationAllowDivide(CognitiveDifficulty difficulty) =>
      difficulty == CognitiveDifficulty.intenso;

  static bool calculationAllowCombined(CognitiveDifficulty difficulty) =>
      difficulty == CognitiveDifficulty.intenso;

  static int calculationMaxOperand(CognitiveDifficulty difficulty) =>
      switch (difficulty) {
        CognitiveDifficulty.suave => 5,
        CognitiveDifficulty.medio => 9,
        CognitiveDifficulty.intenso => 9,
      };

  static int sessionDurationSeconds(
    CognitiveDifficulty difficulty,
    int totalRounds,
  ) =>
      totalRounds * switch (difficulty) {
        CognitiveDifficulty.suave => 20,
        CognitiveDifficulty.medio => 16,
        CognitiveDifficulty.intenso => 14,
      };
}
