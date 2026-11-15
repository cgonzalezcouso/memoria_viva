import 'package:uuid/uuid.dart';

import '../constants/patient_ids.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../models/routine_task.dart';
import 'local_care_storage.dart';

class RoutineService {
  RoutineService(this._storage);

  final LocalCareStorage _storage;
  static const _uuid = Uuid();

  static const _defaultTasks = [
    RoutineTask(
      id: '1',
      title: 'Desayunar',
      scheduledTime: '08:00',
      isCompleted: false,
    ),
    RoutineTask(
      id: '2',
      title: 'Tomar medicación de la mañana',
      scheduledTime: '09:00',
      isCompleted: false,
    ),
    RoutineTask(
      id: '3',
      title: 'Caminata corta',
      scheduledTime: '11:00',
      isCompleted: false,
    ),
    RoutineTask(
      id: '4',
      title: 'Almorzar',
      scheduledTime: '13:30',
      isCompleted: false,
    ),
    RoutineTask(
      id: '5',
      title: 'Actividad de memoria',
      scheduledTime: '16:00',
      isCompleted: false,
    ),
  ];

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  Future<List<RoutineTask>> fetchTodayTasks({required String patientId}) async {
    final dateKey = _todayKey();

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final stored = await _storage.loadRoutineTasks(patientId, dateKey);
      final base = stored.isNotEmpty ? stored : _defaultTasks;
      return base;
    }

    try {
      final response = await SupabaseConfig.client
          .from('routine_tasks')
          .select()
          .eq('patient_id', patientId)
          .eq('task_date', dateKey)
          .order('scheduled_time');

      final tasks = (response as List)
          .map((item) => RoutineTask.fromJson(item as Map<String, dynamic>))
          .toList();

      if (tasks.isNotEmpty) {
        return tasks;
      }
    } catch (_) {
      // Fallback local.
    }

    return _defaultTasks;
  }

  Future<void> toggleTask({
    required String patientId,
    required String taskId,
    required bool isCompleted,
  }) async {
    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final dateKey = _todayKey();
      final tasks = await _storage.loadRoutineTasks(patientId, dateKey);
      final base = tasks.isNotEmpty ? tasks : List<RoutineTask>.from(_defaultTasks);
      final updated = base
          .map(
            (task) =>
                task.id == taskId ? task.copyWith(isCompleted: isCompleted) : task,
          )
          .toList();
      await _storage.saveRoutineTasks(patientId, dateKey, updated);
      return;
    }

    try {
      await SupabaseConfig.client
          .from('routine_tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId);
    } catch (_) {
      // Silenciar errores de red.
    }
  }

  Future<RoutineTask> addTask({
    required String patientId,
    required String title,
    required String scheduledTime,
    String? notes,
  }) async {
    final dateKey = _todayKey();
    final task = RoutineTask(
      id: _uuid.v4(),
      title: title.trim(),
      scheduledTime: scheduledTime,
      isCompleted: false,
      notes: notes?.trim(),
    );

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final existing = await fetchTodayTasks(patientId: patientId);
      final updated = [...existing, task]..sort(
          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
        );
      await _storage.saveRoutineTasks(patientId, dateKey, updated);
      return task;
    }

    final response = await SupabaseConfig.client
        .from('routine_tasks')
        .insert(task.toInsertJson(patientId: patientId, taskDate: dateKey))
        .select()
        .single();

    return RoutineTask.fromJson(response);
  }

  Future<void> deleteTask({
    required String patientId,
    required String taskId,
  }) async {
    final dateKey = _todayKey();

    if (!Env.isSupabaseConfigured || patientId == PatientIds.local) {
      final existing = await fetchTodayTasks(patientId: patientId);
      final updated = existing.where((task) => task.id != taskId).toList();
      await _storage.saveRoutineTasks(patientId, dateKey, updated);
      return;
    }

    await SupabaseConfig.client
        .from('routine_tasks')
        .delete()
        .eq('id', taskId);
  }
}
