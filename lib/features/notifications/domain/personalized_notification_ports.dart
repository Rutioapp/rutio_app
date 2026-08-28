import 'personalized_notification_models.dart';

abstract class NotificationTemplateCatalog {
  List<NotificationTemplateDescriptor> templatesForKind(NotificationKind kind);
}

abstract class NotificationInstallIdProvider {
  Future<String> getOrCreateInstallId();
}

abstract class NotificationPreferencesStore {
  Future<NotificationPreferences> load(NotificationScope scope);

  Future<void> save(
    NotificationScope scope,
    NotificationPreferences preferences,
  );

  Future<NotificationPreferences> update(
    NotificationScope scope,
    NotificationPreferences Function(NotificationPreferences current) update,
  );

  Future<void> reset(NotificationScope scope);
}

abstract class NotificationHistoryStore {
  Future<NotificationMessageHistorySnapshot?> load(NotificationScope scope);

  Future<void> save(
    NotificationScope scope,
    NotificationMessageHistorySnapshot history,
  );

  Future<void> clear(NotificationScope scope);
}

abstract class NotificationScheduleStore {
  Future<NotificationScheduleManifest?> load(NotificationScope scope);

  Future<void> save(
    NotificationScope scope,
    NotificationScheduleManifest manifest,
  );

  Future<void> clear(NotificationScope scope);
}

abstract class NotificationScheduler {
  Future<void> schedule(NotificationPlanEntry entry);

  Future<void> cancel(int platformId);

  Future<void> cancelMany(Iterable<int> platformIds);

  Future<List<NotificationManifestEntry>> pending();
}

abstract class NotificationContextProvider {
  Future<NotificationContextSnapshot> buildContext(
    NotificationScope scope, {
    required NotificationTriggerReason trigger,
  });
}
