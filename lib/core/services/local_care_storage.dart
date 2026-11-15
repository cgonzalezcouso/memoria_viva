import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/accessibility_settings.dart';
import '../models/cognitive_difficulty.dart';
import '../models/cognitive_session.dart';
import '../models/family_memory.dart';
import '../models/medication.dart';
import '../models/routine_task.dart';

class LocalCareStorage {
  static const _medicationsKey = 'local_medications';
  static const _routinesKey = 'local_routines';
  static const _sessionsKey = 'local_cognitive_sessions';
  static const _familyMemoriesKey = 'local_family_memories';
  static const _accessibilityKey = 'accessibility_settings';
  static const _cognitiveDifficultyKey = 'cognitive_difficulty';

  Future<List<Medication>> loadMedications(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_medicationsKey:$patientId');
    if (raw == null) return const [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => Medication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMedications(
    String patientId,
    List<Medication> medications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(medications.map((med) => med.toLocalJson()).toList());
    await prefs.setString('$_medicationsKey:$patientId', encoded);
  }

  Future<List<RoutineTask>> loadRoutineTasks(String patientId, String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_routinesKey:$patientId:$dateKey');
    if (raw == null) return const [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => RoutineTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRoutineTasks(
    String patientId,
    String dateKey,
    List<RoutineTask> tasks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      tasks
          .map(
            (task) => {
              'id': task.id,
              'title': task.title,
              'scheduled_time': task.scheduledTime,
              'is_completed': task.isCompleted,
              'notes': task.notes,
            },
          )
          .toList(),
    );
    await prefs.setString('$_routinesKey:$patientId:$dateKey', encoded);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<AppAccessibilitySettings> loadAccessibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accessibilityKey);
    if (raw == null) return const AppAccessibilitySettings();

    return AppAccessibilitySettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveAccessibilitySettings(
    AppAccessibilitySettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessibilityKey, jsonEncode(settings.toJson()));
  }

  Future<void> addCognitiveSession(
    String patientId,
    CognitiveSession session,
  ) async {
    final sessions = await loadCognitiveSessions(patientId);
    final updated = [session, ...sessions];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_sessionsKey:$patientId',
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<CognitiveSession>> loadCognitiveSessions(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_sessionsKey:$patientId');
    if (raw == null) return const [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => CognitiveSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<FamilyMemory>> loadFamilyMemories(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_familyMemoriesKey:$patientId');
    if (raw == null) return const [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => FamilyMemory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFamilyMemories(
    String patientId,
    List<FamilyMemory> memories,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_familyMemoriesKey:$patientId',
      jsonEncode(memories.map((m) => m.toLocalJson()).toList()),
    );
  }

  Future<CognitiveDifficulty> loadCognitiveDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    return CognitiveDifficulty.fromStorage(
      prefs.getString(_cognitiveDifficultyKey),
    );
  }

  Future<void> saveCognitiveDifficulty(CognitiveDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cognitiveDifficultyKey, difficulty.name);
  }
}
