import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';
import 'local_care_storage.dart';

class NotificationService {
  NotificationService(this._storage);

  final LocalCareStorage _storage;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      tz_data.initializeTimeZones();
      await _configureLocalTimeZone();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('NotificationService.initialize failed: $error\n$stackTrace');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone().timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw StateError('timezone timeout'),
    );
    final candidates = _timeZoneCandidates(timeZoneInfo.identifier);

    for (final candidate in candidates) {
      try {
        tz.setLocalLocation(tz.getLocation(candidate));
        return;
      } catch (_) {
        continue;
      }
    }

    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  /// Algunos dispositivos/emuladores devuelven IDs no IANA (p. ej. "GMT").
  List<String> _timeZoneCandidates(String identifier) {
    const aliases = {
      'GMT': 'UTC',
      'GMT0': 'UTC',
      'Greenwich': 'UTC',
      'Etc/Greenwich': 'UTC',
      'GMT+0': 'UTC',
      'GMT-0': 'UTC',
    };

    final normalized = aliases[identifier] ?? identifier;
    return {
      identifier,
      normalized,
      if (normalized != 'UTC') 'UTC',
      'Etc/UTC',
    }.toList();
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb || !_initialized) return false;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidPlugin?.requestNotificationsPermission() ?? true;
    final iosGranted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted;
  }

  Future<void> syncMedicationReminders(List<Medication> medications) async {
    if (kIsWeb || !_initialized) return;

    final enabled = await _storage.areNotificationsEnabled();
    await _plugin.cancelAll();
    if (!enabled) return;

    for (final medication in medications.where((med) => med.active)) {
      await _scheduleMedication(medication);
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    await _storage.setNotificationsEnabled(enabled);

    if (!enabled) {
      await _plugin.cancelAll();
    }
  }

  Future<bool> areRemindersEnabled() => _storage.areNotificationsEnabled();

  Future<void> _scheduleMedication(Medication medication) async {
    final parts = medication.scheduledTime.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final notificationId = medication.id.hashCode.abs() % 100000;

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Hora de tu medicación',
      body: '${medication.name} — ${medication.scheduledTime}',
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Recordatorios de medicación',
          channelDescription:
              'Avisos diarios para tomar medicación a la hora indicada',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
