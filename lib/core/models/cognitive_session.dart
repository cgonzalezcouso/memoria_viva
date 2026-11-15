class CognitiveSession {
  const CognitiveSession({
    required this.id,
    required this.patientId,
    required this.activityType,
    required this.score,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String id;
  final String patientId;
  final String activityType;
  final int score;
  final int durationSeconds;
  final DateTime completedAt;

  factory CognitiveSession.fromJson(Map<String, dynamic> json) {
    return CognitiveSession(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String,
      activityType: json['activity_type'] as String,
      score: json['score'] as int,
      durationSeconds: json['duration_seconds'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'patient_id': patientId,
      'activity_type': activityType,
      'score': score,
      'duration_seconds': durationSeconds,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}
