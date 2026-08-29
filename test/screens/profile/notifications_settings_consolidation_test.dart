import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/core/notifications/notification_permission_service.dart'
    as core_permission;
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/notifications/application/notification_permission_controller.dart';
import 'package:rutio/features/notifications/application/personalized_notification_settings_controller.dart';
import 'package:rutio/features/notifications/presentation/personalized_notifications_settings_section.dart';
import 'package:rutio/features/notifications/domain/personalized_notification_models.dart';
import 'package:rutio/features/notifications/domain/personalized_notification_ports.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/profile/notification_settings_screen.dart';
import 'package:rutio/screens/profile/settings_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool previousFeatureGateState;

  setUp(() {
    previousFeatureGateState = PersonalizedNotificationsFeatureGate.enabled;
    PersonalizedNotificationsFeatureGate.enabled = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    PersonalizedNotificationsFeatureGate.enabled = previousFeatureGateState;
  });

  testWidgets('Settings opens the canonical notifications screen', (
    tester,
  ) async {
    final store = await _createStore();
    var syncCalls = 0;

    await tester.pumpWidget(
      _app(
        store,
        child: SettingsScreen(
          notificationSettingsScreenBuilder: (_) => NotificationSettingsScreen(
            permissionController: _FakePermissionController(),
            syncPhaseOne: (_) async {
              syncCalls += 1;
            },
          ),
        ),
      ),
    );

    expect(find.text('Open Rutio notifications and reminders'), findsOneWidget);
    await tester.tap(find.text('Notification settings'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
    expect(syncCalls, 0);
  });

  testWidgets('gate off hides personalized settings and keeps legacy visible', (
    tester,
  ) async {
    final store = await _createStore();
    var syncCalls = 0;

    await tester.pumpWidget(
      _app(
        store,
        child: NotificationSettingsScreen(
          permissionController: _FakePermissionController(),
          syncPhaseOne: (_) async {
            syncCalls += 1;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Rutio notifications'),
      findsNothing,
    );
    expect(find.byType(PersonalizedNotificationsSettingsSection), findsNothing);
    expect(find.text('Habit reminders'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(syncCalls, 0);
  });

  testWidgets('gate on shows personalized settings in the same screen', (
    tester,
  ) async {
    PersonalizedNotificationsFeatureGate.enabled = true;
    final store = await _createStore();
    final controller = PersonalizedNotificationSettingsController(
      userStateStore: store,
      preferencesStore: _MemoryNotificationPreferencesStore(),
    );

    await tester.pumpWidget(
      _app(
        store,
        personalizedController: controller,
        child: NotificationSettingsScreen(
          permissionController: _FakePermissionController(),
          syncPhaseOne: (_) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rutio notifications'), findsOneWidget);
    expect(
        find.byType(PersonalizedNotificationsSettingsSection), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
  });

  testWidgets('legacy and personalized toggles still work', (tester) async {
    PersonalizedNotificationsFeatureGate.enabled = true;
    final store = await _createStore();
    final preferencesStore = _MemoryNotificationPreferencesStore();
    final controller = PersonalizedNotificationSettingsController(
      userStateStore: store,
      preferencesStore: preferencesStore,
    );
    var syncCalls = 0;

    await tester.pumpWidget(
      _app(
        store,
        personalizedController: controller,
        child: NotificationSettingsScreen(
          permissionController: _FakePermissionController(),
          syncPhaseOne: (_) async {
            syncCalls += 1;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(0));
    await tester.pumpAndSettle();

    expect(controller.personalizedNotificationsEnabled, isFalse);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(store.notificationsEnabled, isFalse);
    expect(syncCalls, 1);
  });

  testWidgets('back navigation returns to Settings', (tester) async {
    final store = await _createStore();

    await tester.pumpWidget(
      _app(
        store,
        child: SettingsScreen(
          notificationSettingsScreenBuilder: (_) => NotificationSettingsScreen(
            permissionController: _FakePermissionController(),
            syncPhaseOne: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Notification settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(NotificationSettingsScreen), findsNothing);
  });
}

class _FakePermissionController extends NotificationPermissionController {
  @override
  Future<core_permission.NotificationPermissionResult>
      getSystemPermissionResult() async {
    return const core_permission.NotificationPermissionResult(
      status: core_permission.NotificationPermissionStatus.authorized,
    );
  }

  @override
  Future<bool> areNotificationsAllowed() async => true;

  @override
  Future<bool> requestSystemPermission() async => true;
}

class _MemoryNotificationPreferencesStore
    implements NotificationPreferencesStore {
  final Map<String, NotificationPreferences> _values =
      <String, NotificationPreferences>{};

  @override
  Future<NotificationPreferences> load(NotificationScope scope) async {
    return _values[scope.scopeKey] ?? NotificationPreferences.defaults();
  }

  @override
  Future<NotificationPreferences> update(
    NotificationScope scope,
    NotificationPreferences Function(NotificationPreferences current) update,
  ) async {
    final next = update(await load(scope));
    _values[scope.scopeKey] = next;
    return next;
  }

  @override
  Future<void> reset(NotificationScope scope) async {
    _values.remove(scope.scopeKey);
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationPreferences preferences,
  ) async {
    _values[scope.scopeKey] = preferences;
  }
}

Future<UserStateStore> _createStore() async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-123');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState());
  await store.switchLocalScope(userId: 'user-123', forceReload: true);
  return store;
}

Widget _app(
  UserStateStore store, {
  Widget child = const SizedBox.shrink(),
  PersonalizedNotificationSettingsController? personalizedController,
}) {
  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: personalizedController == null
        ? MaterialApp(
            theme: ThemeData(
              useMaterial3: false,
              splashFactory: NoSplash.splashFactory,
            ),
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          )
        : ChangeNotifierProvider<
            PersonalizedNotificationSettingsController>.value(
            value: personalizedController,
            child: MaterialApp(
              theme: ThemeData(
                useMaterial3: false,
                splashFactory: NoSplash.splashFactory,
              ),
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: child,
            ),
          ),
  );
}

Map<String, dynamic> _baseState() {
  final today = DateTime(2026, 8, 29);
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'user-123',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': today.toUtc().toIso8601String(),
        'activeViewDateKey': '2026-08-29',
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'settings': <String, dynamic>{
        'locale': <String, dynamic>{'languageCode': 'es'},
        'notifications': <String, dynamic>{
          'enabled': true,
          'habitReminders': true,
        },
      },
      'progression': <String, dynamic>{'level': 1, 'xp': 0, 'prestige': 0},
      'wallet': <String, dynamic>{'coins': 0},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{
          'avatar_skin': null,
          'aura': null,
          'badge': null,
          'title': null,
          'animation': null,
        },
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'activeHabits': <dynamic>[],
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitLogs': <String, dynamic>{},
      },
      'daily': <String, dynamic>{
        'habitsCompletedToday': <String, dynamic>{},
      },
    },
  };
}
