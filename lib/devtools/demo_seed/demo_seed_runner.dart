import 'package:flutter/foundation.dart';

import '../../data/local/user_state_storage.dart';
import '../../data/repositories/user_state_repository.dart';
import '../rutio_runtime_profile.dart';
import 'demo_seed_data.dart';
import 'demo_seed_models.dart';

class DemoSeedRunner {
  DemoSeedRunner({
    required UserStateRepository repository,
    required UserStateStorage storage,
    DateTime Function()? nowProvider,
  })  : _repository = repository,
        _storage = storage,
        _nowProvider = nowProvider ?? DateTime.now;

  final UserStateRepository _repository;
  final UserStateStorage _storage;
  final DateTime Function() _nowProvider;

  Future<void> prepare() async {
    if (!RutioRuntimeProfile.isDemo) return;

    _repository.setActiveUserScope(DemoSeedScope.userId);

    final hasScopedState =
        await _storage.read(userId: DemoSeedScope.userId) != null;
    final shouldReseed = RutioRuntimeProfile.shouldResetDemo || !hasScopedState;

    if (!shouldReseed) {
      if (kDebugMode) {
        debugPrint('[demo_seed] existing demo scope found; keeping current data');
      }
      return;
    }

    if (RutioRuntimeProfile.shouldResetDemo) {
      await _repository.clearActiveScopeState();
    }

    final payload = DemoSeedData.build(now: _nowProvider());
    await _repository.save(payload.state);

    if (kDebugMode) {
      final action =
          RutioRuntimeProfile.shouldResetDemo ? 'reset+seeded' : 'seeded';
      debugPrint('[demo_seed] $action scope=${payload.userId}');
    }
  }
}
