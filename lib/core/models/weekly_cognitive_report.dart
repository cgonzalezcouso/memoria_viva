class DailyCognitiveSummary {
  const DailyCognitiveSummary({
    required this.date,
    required this.sessionCount,
    required this.averageScore,
  });

  final DateTime date;
  final int sessionCount;
  final double averageScore;
}

class WeeklyCognitiveReport {
  const WeeklyCognitiveReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSessions,
    required this.averageScore,
    required this.sessionsByActivity,
    required this.averageByActivity,
    required this.dailySummaries,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalSessions;
  final double averageScore;
  final Map<String, int> sessionsByActivity;
  final Map<String, double> averageByActivity;
  final List<DailyCognitiveSummary> dailySummaries;

  bool get hasData => totalSessions > 0;
}
