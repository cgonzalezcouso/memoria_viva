class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.title,
    required this.scheduledTime,
    required this.isCompleted,
    this.notes,
  });

  final String id;
  final String title;
  final String scheduledTime;
  final bool isCompleted;
  final String? notes;

  RoutineTask copyWith({
    String? title,
    String? scheduledTime,
    bool? isCompleted,
    String? notes,
  }) {
    return RoutineTask(
      id: id,
      title: title ?? this.title,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  factory RoutineTask.fromJson(Map<String, dynamic> json) {
    return RoutineTask(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledTime: json['scheduled_time'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({
    required String patientId,
    required String taskDate,
  }) {
    return {
      'patient_id': patientId,
      'title': title,
      'scheduled_time': scheduledTime,
      'notes': notes,
      'is_completed': isCompleted,
      'task_date': taskDate,
    };
  }
}
