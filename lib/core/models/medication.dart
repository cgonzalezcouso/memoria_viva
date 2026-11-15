class Medication {
  const Medication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.scheduledTime,
    this.instructions,
    this.active = true,
  });

  final String id;
  final String patientId;
  final String name;
  final String scheduledTime;
  final String? instructions;
  final bool active;

  Medication copyWith({
    String? name,
    String? scheduledTime,
    String? instructions,
    bool? active,
  }) {
    return Medication(
      id: id,
      patientId: patientId,
      name: name ?? this.name,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      instructions: instructions ?? this.instructions,
      active: active ?? this.active,
    );
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      scheduledTime: json['scheduled_time'] as String,
      instructions: json['instructions'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'patient_id': patientId,
      'name': name,
      'scheduled_time': scheduledTime,
      'instructions': instructions,
      'active': active,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'scheduled_time': scheduledTime,
      'instructions': instructions,
      'active': active,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'name': name,
      'scheduled_time': scheduledTime,
      'instructions': instructions,
      'active': active,
    };
  }
}
