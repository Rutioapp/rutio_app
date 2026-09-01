import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/notifications/application/notification_context_builder.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:rutio/models/diary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoreBackedNotificationContextBuilder', () {
    late FakeNotificationClock clock;
    late InMemoryNotificationHistoryStore historyStore;
    late FakeNotificationInstallIdProvider installIdProvider;

    setUp(() {
      clock = FakeNotificationClock(
        currentTime: DateTime(2026, 8, 29, 9, 15),
      );
      historyStore = InMemoryNotificationHistoryStore();
      installIdProvider = FakeNotificationInstallIdProvider('install-1');
    });

    test('fails closed when there is no authenticated user', () async {
      final source = FakeNotificationContextStateSource(
        userId: null,
        state: _rootState(userId: null),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: null,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        NotificationContextBuildFailureReason.unauthenticatedUser,
      );
    });

    test('exposes logical journal signals in both context models', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          diaryEntries: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'journal-1',
              'createdAt': clock
                  .now()
                  .subtract(const Duration(days: 1))
                  .millisecondsSinceEpoch,
              'dateKey': '2026-08-28',
              'text': 'Yesterday',
            },
            <String, dynamic>{
              'id': 'journal-2',
              'createdAt': clock.now().millisecondsSinceEpoch,
              'dateKey': '2026-08-29',
              'text': 'Today',
            },
          ],
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.isSuccess, isTrue);
      expect(result.snapshot!.journalWrittenToday, isTrue);
      expect(result.snapshot!.journalWrittenLast24h, isTrue);
      expect(result.snapshot!.journalEntriesLast7Days, 2);
      expect(result.selectionContext!.journalWrittenToday, isTrue);
      expect(result.selectionContext!.journalEntriesLast7Days, 2);
    });

    test('bridges a valid Phase 1 streak marker into context', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          notificationMetadata: <String, dynamic>{
            'streakMilestoneDailySent': <String, dynamic>{
              'dateKey': '2026-08-29',
              'habitId': 'habit-1',
              'milestone': 7,
              'sentAt': '2026-08-29T08:00:00.000Z',
            },
          },
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.isSuccess, isTrue);
      expect(result.snapshot!.journalMilestoneSignal, isNotNull);
      expect(result.snapshot!.journalMilestoneSignal!.eventId,
          'habit-1:7:2026-08-29');
      expect(result.selectionContext!.journalMilestoneSignal, isNotNull);
    });

    test('ignores legacy streak markers without sentAt', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          notificationMetadata: <String, dynamic>{
            'streakMilestoneDailySent': <String, dynamic>{
              'dateKey': '2026-08-29',
              'habitId': 'habit-1',
              'milestone': 7,
            },
          },
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.snapshot!.journalMilestoneSignal, isNull);
    });

    test('fails closed on expected user mismatch', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(userId: 'user-a'),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-b',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        NotificationContextBuildFailureReason.scopeMismatch,
      );
    });

    test('fails closed if the scope switches during build', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(userId: 'user-a'),
      );
      installIdProvider.onRead = () async {
        source.setScope(
          userId: 'user-b',
          state: _rootState(userId: 'user-b'),
        );
      };
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        NotificationContextBuildFailureReason.scopeChangedDuringBuild,
      );
    });

    test('keeps progress unknown when no habits are expected today', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(
              id: 'weekly-run',
              name: 'Run',
              schedule: <String, dynamic>{
                'type': 'weekly',
                'weekdays': <int>[DateTime.monday],
              },
            ),
          ],
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.isSuccess, isTrue);
      expect(result.selectionContext!.totalCount, 0);
      expect(result.selectionContext!.progressRatio, isNull);
      expect(result.snapshot!.progressTodayRatio, isNull);
    });

    test('uses Home semantics for pending, skipped and archived habits',
        () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-1', name: 'Read'),
            _habit(id: 'daily-2', name: 'Walk', archived: true),
            _habit(
              id: 'once-1',
              name: 'Doctor',
              schedule: const <String, dynamic>{
                'type': 'once',
                'date': '2026-08-29',
              },
            ),
          ],
          history: <String, dynamic>{
            'habitCompletions': <String, dynamic>{},
            'habitCountValues': <String, dynamic>{},
            'habitSkips': <String, dynamic>{
              '2026-08-29': <String, dynamic>{'once-1': true},
            },
          },
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.isSuccess, isTrue);
      expect(result.selectionContext!.totalCount, 2);
      expect(result.selectionContext!.pendingCount, 1);
      expect(result.selectionContext!.completedCount, 0);
      expect(result.snapshot!.activeHabitsSummary, contains('Read'));
      expect(result.snapshot!.activeHabitsSummary, isNot(contains('Walk')));
    });

    test('computes progress for partial and completed days', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-check', name: 'Read'),
            _habit(
              id: 'count-1',
              name: 'Water',
              type: 'count',
              target: 2,
            ),
            _habit(
              id: 'times-1',
              name: 'Stretch',
              schedule: <String, dynamic>{
                'type': 'timesPerWeek',
                'timesPerWeek': 3,
                'weekStartsOn': 1,
              },
            ),
          ],
          history: <String, dynamic>{
            'habitCompletions': <String, dynamic>{
              '2026-08-29': <String, dynamic>{'daily-check': true},
            },
            'habitCountValues': <String, dynamic>{
              '2026-08-29': <String, dynamic>{'count-1': 1},
            },
            'habitSkips': <String, dynamic>{},
          },
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final partial = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(partial.selectionContext!.progressRatio, closeTo(1 / 3, 0.0001));

      source.replaceState(
        _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-check', name: 'Read'),
            _habit(
              id: 'count-1',
              name: 'Water',
              type: 'count',
              target: 2,
            ),
          ],
          history: <String, dynamic>{
            'habitCompletions': <String, dynamic>{
              '2026-08-29': <String, dynamic>{'daily-check': true},
            },
            'habitCountValues': <String, dynamic>{
              '2026-08-29': <String, dynamic>{'count-1': 2},
            },
            'habitSkips': <String, dynamic>{},
          },
        ),
      );

      final completed = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(completed.selectionContext!.progressRatio, 1.0);
      expect(completed.selectionContext!.completedCount, 2);
    });

    test('supports daily, weekly, timesPerWeek and once schedules', () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-1', name: 'Read'),
            _habit(
              id: 'weekly-1',
              name: 'Run',
              schedule: <String, dynamic>{
                'type': 'weekly',
                'weekdays': <int>[DateTime.saturday],
              },
            ),
            _habit(
              id: 'tpw-1',
              name: 'Stretch',
              schedule: <String, dynamic>{
                'type': 'timesPerWeek',
                'timesPerWeek': 3,
                'weekStartsOn': 1,
              },
            ),
            _habit(
              id: 'once-1',
              name: 'Doctor',
              schedule: const <String, dynamic>{
                'type': 'once',
                'date': '2026-08-29',
              },
            ),
          ],
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.selectionContext!.totalCount, 4);
    });

    test('uses authoritative streak source and distinguishes unknown and zero',
        () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-1', name: 'Read'),
          ],
        ),
        streaksByHabitId: <String, HabitStreakSnapshot>{
          'daily-1': const HabitStreakSnapshot(
            habitId: 'daily-1',
            currentStreak: 0,
            bestStreak: 0,
            totalCompletedDays: 0,
          ),
        },
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final zeroStreak = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );
      expect(zeroStreak.selectionContext!.streak, 0);

      source.replaceState(
        _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[],
        ),
      );

      final unknownStreak = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );
      expect(unknownStreak.selectionContext!.streak, isNull);

      source.replaceState(
        _rootState(
          userId: 'user-a',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-1', name: 'Read'),
          ],
        ),
      );
      source.streaksByHabitId = <String, HabitStreakSnapshot>{
        'daily-1': const HabitStreakSnapshot(
          habitId: 'daily-1',
          currentStreak: 2,
          bestStreak: 2,
          totalCompletedDays: 2,
        ),
      };

      final positiveStreak = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );
      expect(positiveStreak.selectionContext!.streak, 2);
    });

    test('includes displayName, locale, inactivity and latest diary signal',
        () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          displayName: 'Nora',
          preferredLanguageCode: 'en',
          notificationMetadata: const <String, dynamic>{
            'lastAppOpenAt': '2026-08-25T07:00:00.000',
          },
          diaryEntries: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'entry-1',
              'createdAt': DateTime(2026, 8, 28, 22).millisecondsSinceEpoch,
              'text': 'A good day',
            },
          ],
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.selectionContext!.displayName, 'Nora');
      expect(result.selectionContext!.locale, 'en');
      expect(result.selectionContext!.inactivityDays, 4);
      expect(result.selectionContext!.latestDiaryEntryAt, isNotNull);
    });

    test('derives morning, afternoon, evening and night from the fake clock',
        () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(userId: 'user-a'),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      clock.setNow(DateTime(2026, 8, 29, 9, 15));
      expect(
        (await builder.build(
          trigger: NotificationTriggerReason.appBootstrap,
          expectedUserId: 'user-a',
        ))
            .selectionContext!
            .timeOfDay,
        NotificationContextTimeOfDay.morning,
      );

      clock.setNow(DateTime(2026, 8, 29, 13, 15));
      expect(
        (await builder.build(
          trigger: NotificationTriggerReason.appBootstrap,
          expectedUserId: 'user-a',
        ))
            .selectionContext!
            .timeOfDay,
        NotificationContextTimeOfDay.afternoon,
      );

      clock.setNow(DateTime(2026, 8, 29, 19, 15));
      expect(
        (await builder.build(
          trigger: NotificationTriggerReason.appBootstrap,
          expectedUserId: 'user-a',
        ))
            .selectionContext!
            .timeOfDay,
        NotificationContextTimeOfDay.evening,
      );

      clock.setNow(DateTime(2026, 8, 29, 23, 15));
      expect(
        (await builder.build(
          trigger: NotificationTriggerReason.appBootstrap,
          expectedUserId: 'user-a',
        ))
            .selectionContext!
            .timeOfDay,
        NotificationContextTimeOfDay.night,
      );
    });

    test(
        'reports partial context quality when wake-up and mood are unavailable',
        () async {
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          displayName: 'Nora',
          notificationMetadata: const <String, dynamic>{
            'lastAppOpenAt': '2026-08-28T08:00:00.000',
          },
        ),
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );

      final result = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );

      expect(result.isSuccess, isTrue);
      expect(result.quality, NotificationContextQuality.partial);
      expect(result.diagnostics.hasMoodSignal, isFalse);
      expect(result.diagnostics.hasWakeUpTime, isFalse);
    });

    test('integrates with SelectionEngine without scheduling', () async {
      clock.setNow(DateTime(2026, 8, 29, 19, 30));
      final source = FakeNotificationContextStateSource(
        userId: 'user-a',
        state: _rootState(
          userId: 'user-a',
          displayName: 'Nora',
          activeHabits: <Map<String, dynamic>>[
            _habit(id: 'daily-1', name: 'Read'),
          ],
        ),
        streaksByHabitId: <String, HabitStreakSnapshot>{
          'daily-1': const HabitStreakSnapshot(
            habitId: 'daily-1',
            currentStreak: 2,
            bestStreak: 2,
            totalCompletedDays: 2,
          ),
        },
      );
      final builder = StoreBackedNotificationContextBuilder(
        store: source,
        installIdProvider: installIdProvider,
        historyStore: historyStore,
        clock: clock,
      );
      final buildResult = await builder.build(
        trigger: NotificationTriggerReason.appBootstrap,
        expectedUserId: 'user-a',
      );
      final engine = NotificationSelectionEngine(
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[
            NotificationTemplateDescriptor(
              templateId: 'general.pending.typed_01',
              templateKey: 'generalMorningGentle01',
              localeNamespace: 'personalizedNotifications',
              category: NotificationTemplateCategory.pendingProgress,
              eligibility: NotificationTemplateEligibility(
                minPendingCount: 1,
                requiresCompletedDay: false,
                requiresStreak: false,
                requiresDisplayName: false,
                requiresInactivity: false,
              ),
              isFallbackCandidate: true,
              weight: 10,
              cooldown: const Duration(hours: 1),
              maxUsesPer7d: 3,
              compatibleKinds: const <NotificationKind>[
                NotificationKind.generalDayClosure,
              ],
            ),
          ],
        ),
        randomSource: FixedNotificationRandomSource(const <double>[0]),
      );

      final selection = await engine.selectTemplate(
        context: buildResult.selectionContext!,
        preferences: NotificationPreferences.defaults(),
      );

      expect(buildResult.isSuccess, isTrue);
      expect(selection.isSelected, isTrue);
      expect(
        selection.selected!.category,
        NotificationTemplateCategory.pendingProgress,
      );
    });
  });
}

class FakeNotificationInstallIdProvider
    implements NotificationInstallIdProvider {
  FakeNotificationInstallIdProvider(this.installId);

  final String installId;
  Future<void> Function()? onRead;

  @override
  Future<String> getOrCreateInstallId() async {
    await onRead?.call();
    return installId;
  }
}

class InMemoryNotificationHistoryStore implements NotificationHistoryStore {
  final Map<String, NotificationMessageHistorySnapshot> _values =
      <String, NotificationMessageHistorySnapshot>{};

  @override
  Future<void> clear(NotificationScope scope) async {
    _values.remove(scope.scopeKey);
  }

  @override
  Future<NotificationMessageHistorySnapshot?> load(
    NotificationScope scope,
  ) async {
    return _values[scope.scopeKey];
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationMessageHistorySnapshot history,
  ) async {
    _values[scope.scopeKey] = history;
  }
}

class FakeNotificationContextStateSource
    implements NotificationContextStateSource {
  FakeNotificationContextStateSource({
    required String? userId,
    required Map<String, dynamic>? state,
    this.streaksByHabitId = const <String, HabitStreakSnapshot>{},
  })  : _userId = userId,
        _activeLocalScopeUserId = userId,
        _state = state,
        _scopeEpoch = 1;

  Map<String, HabitStreakSnapshot> streaksByHabitId;

  String? _userId;
  String? _activeLocalScopeUserId;
  Map<String, dynamic>? _state;
  int _scopeEpoch;

  @override
  String? get activeLocalScopeUserId => _activeLocalScopeUserId;

  @override
  List<Map<String, dynamic>> get activeHabits {
    return _listMap(_userState['activeHabits']);
  }

  @override
  String? get displayName {
    final profile = _map(_userState['profile']);
    return (profile['displayName'] ?? profile['name'] ?? '').toString();
  }

  @override
  List<DiaryEntry> get diaryEntries {
    return _listMap(_userState['diaryEntries'])
        .map(DiaryEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Map<String, dynamic> get notificationMetadata {
    final settings = _map(_userState['settings']);
    final notifications = _map(settings['notifications']);
    return _map(notifications['metadata']);
  }

  @override
  String? get preferredLanguageCode {
    final settings = _map(_userState['settings']);
    return settings['languageCode']?.toString();
  }

  @override
  int get scopeEpoch => _scopeEpoch;

  @override
  Map<String, dynamic>? get state => _state;

  @override
  String? get userId => _userId;

  @override
  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  }) {
    return streaksByHabitId[habitId] ??
        HabitStreakSnapshot(
          habitId: habitId,
          currentStreak: 0,
          bestStreak: 0,
          totalCompletedDays: 0,
        );
  }

  void replaceState(Map<String, dynamic>? value) {
    _state = value;
  }

  void setScope({
    required String? userId,
    required Map<String, dynamic>? state,
  }) {
    _userId = userId;
    _activeLocalScopeUserId = userId;
    _state = state;
    _scopeEpoch += 1;
  }

  Map<String, dynamic> get _userState => _map(_state?['userState']);
}

Map<String, dynamic> _rootState({
  required String? userId,
  String displayName = 'Nora',
  String preferredLanguageCode = 'es',
  List<Map<String, dynamic>> activeHabits = const <Map<String, dynamic>>[],
  Map<String, dynamic>? history,
  Map<String, dynamic> notificationMetadata = const <String, dynamic>{},
  List<Map<String, dynamic>> diaryEntries = const <Map<String, dynamic>>[],
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      if (userId != null) 'userId': userId,
      'profile': <String, dynamic>{'displayName': displayName},
      'settings': <String, dynamic>{
        'languageCode': preferredLanguageCode,
        'notifications': <String, dynamic>{
          'enabled': true,
          'habitReminders': true,
          'metadata': notificationMetadata,
        },
      },
      'activeHabits': activeHabits,
      'history': history ??
          <String, dynamic>{
            'habitCompletions': <String, dynamic>{},
            'habitCountValues': <String, dynamic>{},
            'habitSkips': <String, dynamic>{},
          },
      'diaryEntries': diaryEntries,
    },
  };
}

Map<String, dynamic> _habit({
  required String id,
  required String name,
  String type = 'check',
  num target = 1,
  Map<String, dynamic> schedule = const <String, dynamic>{'type': 'daily'},
  bool archived = false,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'target': target,
    'schedule': schedule,
    'archived': archived,
    'doneToday': false,
    'skippedToday': false,
    'createdAt': '2026-08-01T00:00:00.000',
  };
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _listMap(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
      .toList(growable: false);
}
