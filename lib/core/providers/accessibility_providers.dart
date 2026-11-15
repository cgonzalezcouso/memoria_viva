import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accessibility_settings.dart';
import 'app_providers.dart';

final accessibilitySettingsProvider =
    AsyncNotifierProvider<AccessibilitySettingsController, AppAccessibilitySettings>(
  AccessibilitySettingsController.new,
);

class AccessibilitySettingsController extends AsyncNotifier<AppAccessibilitySettings> {
  @override
  Future<AppAccessibilitySettings> build() async {
    return ref.read(localCareStorageProvider).loadAccessibilitySettings();
  }

  Future<void> setHighContrast(bool enabled) async {
    final updated = state.requireValue.copyWith(highContrast: enabled);
    state = AsyncData(updated);
    await ref.read(localCareStorageProvider).saveAccessibilitySettings(updated);
  }

  Future<void> setTextSize(TextSizeOption textSize) async {
    final updated = state.requireValue.copyWith(textSize: textSize);
    state = AsyncData(updated);
    await ref.read(localCareStorageProvider).saveAccessibilitySettings(updated);
  }
}
