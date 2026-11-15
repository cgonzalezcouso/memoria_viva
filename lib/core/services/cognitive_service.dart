import 'package:uuid/uuid.dart';

import '../constants/patient_ids.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../models/cognitive_session.dart';
import '../models/weekly_cognitive_report.dart';
import 'local_care_storage.dart';

class CognitiveService {
  CognitiveService(this._storage);

  final LocalCareStorage _storage;
  static const _uuid = Uuid();

  Future<void> saveSession(CognitiveSession session) async {
    if (session.patientId == PatientIds.unlinked) return;

    final storedSession = session.id.isEmpty
        ? CognitiveSession(
            id: _uuid.v4(),
            patientId: session.patientId,
            activityType: session.activityType,
            score: session.score,
            durationSeconds: session.durationSeconds,
            completedAt: session.completedAt,
          )
        : session;

    if (session.patientId == PatientIds.local || !Env.isSupabaseConfigured) {
      await _storage.addCognitiveSession(
        PatientIds.local,
        storedSession,
      );
    }

    if (!Env.isSupabaseConfigured || !PatientIds.canSyncToSupabase(storedSession.patientId)) {
      return;
    }

    try {
      await SupabaseConfig.client
          .from('cognitive_sessions')
          .insert(storedSession.toJson());
    } catch (_) {
      // Silenciar errores de red en modo degradado.
    }
  }

  Future<List<CognitiveSession>> fetchRecentSessions({String? patientId}) async {
    final id = patientId ?? PatientIds.local;
    if (id == PatientIds.unlinked) return const [];

    if (id == PatientIds.local || !Env.isSupabaseConfigured) {
      final local = await _storage.loadCognitiveSessions(PatientIds.local);
      return local.take(10).toList();
    }

    try {
      final response = await SupabaseConfig.client
          .from('cognitive_sessions')
          .select()
          .eq('patient_id', id)
          .order('completed_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((item) => CognitiveSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _storage.loadCognitiveSessions(id);
    }
  }

  Future<List<CognitiveSession>> fetchSessionsForWeek({
    required String patientId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    if (patientId == PatientIds.unlinked) return const [];

    if (patientId == PatientIds.local || !Env.isSupabaseConfigured) {
      final local = await _storage.loadCognitiveSessions(PatientIds.local);
      return local.where((session) {
        return !session.completedAt.isBefore(weekStart) &&
            session.completedAt.isBefore(weekEnd);
      }).toList();
    }

    try {
      final response = await SupabaseConfig.client
          .from('cognitive_sessions')
          .select()
          .eq('patient_id', patientId)
          .gte('completed_at', weekStart.toIso8601String())
          .lt('completed_at', weekEnd.toIso8601String())
          .order('completed_at');

      return (response as List)
          .map((item) => CognitiveSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<WeeklyCognitiveReport> buildWeeklyReport({
    required String patientId,
    DateTime? referenceDate,
  }) async {
    final reference = referenceDate ?? DateTime.now();
    final weekStart = DateTime(reference.year, reference.month, reference.day)
        .subtract(Duration(days: reference.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final sessions = await fetchSessionsForWeek(
      patientId: patientId,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );

    final sessionsByActivity = <String, int>{};
    final scoreSumByActivity = <String, int>{};
    final dailyMap = <String, List<int>>{};

    for (final session in sessions) {
      sessionsByActivity.update(
        session.activityType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      scoreSumByActivity.update(
        session.activityType,
        (value) => value + session.score,
        ifAbsent: () => session.score,
      );

      final dayKey = _dayKey(session.completedAt);
      dailyMap.putIfAbsent(dayKey, () => []).add(session.score);
    }

    final averageByActivity = scoreSumByActivity.map(
      (activity, sum) => MapEntry(
        activity,
        sum / sessionsByActivity[activity]!,
      ),
    );

    final dailySummaries = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final scores = dailyMap[_dayKey(date)] ?? const [];
      return DailyCognitiveSummary(
        date: date,
        sessionCount: scores.length,
        averageScore: scores.isEmpty
            ? 0
            : scores.reduce((a, b) => a + b) / scores.length,
      );
    });

    final totalScore = sessions.fold<int>(0, (sum, s) => sum + s.score);

    return WeeklyCognitiveReport(
      weekStart: weekStart,
      weekEnd: weekEnd.subtract(const Duration(days: 1)),
      totalSessions: sessions.length,
      averageScore: sessions.isEmpty ? 0 : totalScore / sessions.length,
      sessionsByActivity: sessionsByActivity,
      averageByActivity: averageByActivity,
      dailySummaries: dailySummaries,
    );
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
