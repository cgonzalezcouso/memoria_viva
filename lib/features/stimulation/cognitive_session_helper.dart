import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/cognitive_session.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/auth_providers.dart';

Future<void> saveCognitiveSession(
  WidgetRef ref, {
  required String activityType,
  required int score,
  required int durationSeconds,
}) async {
  final patientId = ref.read(activePatientIdProvider);
  await ref.read(cognitiveServiceProvider).saveSession(
        CognitiveSession(
          id: '',
          patientId: patientId,
          activityType: activityType,
          score: score,
          durationSeconds: durationSeconds,
          completedAt: DateTime.now(),
        ),
      );
  ref.invalidate(recentSessionsProvider);
  ref.invalidate(weeklyReportProvider);
}
