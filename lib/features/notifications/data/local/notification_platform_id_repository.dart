import '../../domain/personalized_notification_ids.dart';
import '../../domain/personalized_notification_models.dart';
import 'shared_preferences_notification_schedule_store.dart';

class NotificationPlatformIdRepository {
  NotificationPlatformIdRepository({
    required SharedPreferencesNotificationScheduleStore scheduleStore,
  }) : _scheduleStore = scheduleStore;

  final SharedPreferencesNotificationScheduleStore _scheduleStore;

  Future<int> getOrAllocate(
    NotificationScope scope, {
    required NotificationFamily family,
    required String notificationKey,
    String timezoneId = 'unknown',
  }) async {
    final manifest = await _scheduleStore.load(scope);
    final platformIdIndex = manifest?.platformIdIndex ?? const <String, int>{};
    _validatePersistedIndex(platformIdIndex);

    final existing = platformIdIndex[notificationKey];
    if (existing != null) {
      final range = NotificationIdNamespace.rangeForFamily(family);
      if (!range.contains(existing)) {
        throw StateError(
          'Persisted platform id $existing is outside ${family.name} range.',
        );
      }
      return existing;
    }

    final allocator = NotificationPlatformIdAllocator(
      initialAssignments: platformIdIndex,
    );
    final allocated = allocator.allocate(
      family: family,
      notificationKey: notificationKey,
    );
    await _scheduleStore.savePlatformIdMapping(
      scope,
      family: family,
      notificationKey: notificationKey,
      platformId: allocated,
      timezoneId: timezoneId,
    );
    return allocated;
  }

  void _validatePersistedIndex(Map<String, int> index) {
    final byId = <int, String>{};
    for (final entry in index.entries) {
      final current = byId[entry.value];
      if (current != null && current != entry.key) {
        throw StateError(
          'Persisted platform id conflict: ${entry.value} '
          'is assigned to both $current and ${entry.key}.',
        );
      }
      byId[entry.value] = entry.key;
    }
  }
}
