class FamilyMemory {
  const FamilyMemory({
    required this.id,
    required this.patientId,
    required this.displayName,
    required this.relationship,
    required this.emoji,
    this.photoUrl,
    this.active = true,
  });

  final String id;
  final String patientId;
  final String displayName;
  final String relationship;
  final String emoji;
  final String? photoUrl;
  final bool active;

  factory FamilyMemory.fromJson(Map<String, dynamic> json) {
    return FamilyMemory(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      displayName: json['display_name'] as String,
      relationship: json['relationship'] as String,
      emoji: json['emoji'] as String? ?? '👤',
      photoUrl: json['photo_url'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'patient_id': patientId,
      'display_name': displayName,
      'relationship': relationship,
      'emoji': emoji,
      'photo_url': photoUrl,
      'active': active,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'display_name': displayName,
      'relationship': relationship,
      'emoji': emoji,
      'photo_url': photoUrl,
      'active': active,
    };
  }
}
