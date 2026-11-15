import 'package:flutter/material.dart';

Future<String?> pickTime(BuildContext context, {String? initialTime}) async {
  TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
  if (initialTime != null) {
    final parts = initialTime.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        initial = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
    helpText: 'Seleccionar hora',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );

  if (picked == null) return null;
  final hour = picked.hour.toString().padLeft(2, '0');
  final minute = picked.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String? validateTime(String? value) {
  if (value == null || value.isEmpty) return 'Indica una hora';
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
  if (match == null) return 'Formato HH:MM (ej. 09:00)';
  return null;
}
