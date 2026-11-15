class ReportEmailSettings {
  const ReportEmailSettings({
    required this.patientId,
    required this.recipientEmail,
    this.autoSendWeekly = false,
    this.lastSentAt,
  });

  final String patientId;
  final String recipientEmail;
  final bool autoSendWeekly;
  final DateTime? lastSentAt;

  bool get isConfigured => recipientEmail.trim().isNotEmpty;

  bool shouldSendAutomatically(DateTime now) {
    if (!autoSendWeekly || !isConfigured) return false;
    if (lastSentAt == null) return true;
    return now.difference(lastSentAt!).inDays >= 7;
  }

  ReportEmailSettings copyWith({
    String? recipientEmail,
    bool? autoSendWeekly,
    DateTime? lastSentAt,
  }) {
    return ReportEmailSettings(
      patientId: patientId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      autoSendWeekly: autoSendWeekly ?? this.autoSendWeekly,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }

  factory ReportEmailSettings.empty(String patientId) {
    return ReportEmailSettings(patientId: patientId, recipientEmail: '');
  }

  factory ReportEmailSettings.fromJson(Map<String, dynamic> json) {
    return ReportEmailSettings(
      patientId: json['patient_id'] as String,
      recipientEmail: json['recipient_email'] as String,
      autoSendWeekly: json['auto_send_weekly'] as bool? ?? false,
      lastSentAt: json['last_sent_at'] != null
          ? DateTime.parse(json['last_sent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'recipient_email': recipientEmail.trim(),
      'auto_send_weekly': autoSendWeekly,
      if (lastSentAt != null) 'last_sent_at': lastSentAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalJson() => toJson();
}
