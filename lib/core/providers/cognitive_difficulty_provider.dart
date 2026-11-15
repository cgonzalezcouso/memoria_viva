import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cognitive_difficulty.dart';
import 'app_providers.dart';

final cognitiveDifficultyProvider =
    NotifierProvider<CognitiveDifficultyController, CognitiveDifficulty>(
  CognitiveDifficultyController.new,
);

class CognitiveDifficultyController extends Notifier<CognitiveDifficulty> {
  @override
  CognitiveDifficulty build() {
    _load();
    return CognitiveDifficulty.medio;
  }

  Future<void> _load() async {
    final stored =
        await ref.read(localCareStorageProvider).loadCognitiveDifficulty();
    state = stored;
  }

  Future<void> set(CognitiveDifficulty difficulty) async {
    state = difficulty;
    await ref.read(localCareStorageProvider).saveCognitiveDifficulty(difficulty);
  }
}
