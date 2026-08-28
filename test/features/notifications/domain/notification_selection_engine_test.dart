import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/asset_json_loader.dart';
import 'package:rutio/features/notifications/data/local/local_notification_template_catalog.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NotificationScope buildScope() {
    return NotificationScope(
      userId: 'user-1',
      scopeEpoch: 1,
      installId: 'install-1',
      locale: 'es',
    );
  }

  NotificationSelectionContext buildContext({
    DateTime? now,
    NotificationContextTimeOfDay? timeOfDay,
    String? displayName,
    double? progressRatio,
    int? pendingCount,
    int? completedCount,
    int? totalCount,
    int? streak,
    int? inactivityDays,
    String? habitName,
    NotificationMessageHistorySnapshot? history,
  }) {
    return NotificationSelectionContext(
      scope: buildScope(),
      now: now ?? DateTime(2026, 8, 28, 9, 0),
      timezoneId: 'Europe/Madrid',
      timeOfDay: timeOfDay,
      displayName: displayName,
      progressRatio: progressRatio,
      pendingCount: pendingCount,
      completedCount: completedCount,
      totalCount: totalCount,
      streak: streak,
      inactivityDays: inactivityDays,
      habitName: habitName,
      weekdayLabel: 'viernes',
      timeOfDayLabel: '20:30',
      recentMessageHistory: history,
    );
  }

  NotificationDeliveryRecord buildDelivery({
    required String templateId,
    required NotificationKind kind,
    required DateTime scheduledAt,
  }) {
    return NotificationDeliveryRecord(
      notificationKey: 'key:$templateId:${scheduledAt.millisecondsSinceEpoch}',
      userId: 'user-1',
      templateId: templateId,
      kind: kind,
      scheduledAt: scheduledAt,
    );
  }

  NotificationMessageHistorySnapshot buildHistory({
    List<NotificationDeliveryRecord> deliveries =
        const <NotificationDeliveryRecord>[],
    Map<String, DateTime> lastByTemplate = const <String, DateTime>{},
    Map<String, DateTime> lastByCategory = const <String, DateTime>{},
    Map<String, DateTime> lastByKind = const <String, DateTime>{},
  }) {
    return NotificationMessageHistorySnapshot(
      recentDeliveries: deliveries,
      lastSelectedAtByTemplateId: lastByTemplate,
      lastSelectedAtByCategoryTag: lastByCategory,
      lastSelectedAtByKind: lastByKind,
    );
  }

  NotificationTemplateDescriptor buildTemplate({
    required String templateId,
    required NotificationTemplateCategory category,
    required NotificationKind kind,
    int weight = 10,
    bool isFallbackCandidate = false,
    NotificationTemplateEligibility? eligibility,
    List<NotificationTemplateVariable> declaredVariables =
        const <NotificationTemplateVariable>[],
    List<NotificationTemplateVariable> requiredVariables =
        const <NotificationTemplateVariable>[],
  }) {
    return NotificationTemplateDescriptor(
      templateId: templateId,
      templateKey: 'generalMorningGentle01',
      localeNamespace: 'personalizedNotifications',
      category: category,
      eligibility: eligibility,
      isFallbackCandidate: isFallbackCandidate,
      variantTags: const <String>['test'],
      declaredVariables: declaredVariables,
      requiredVariables: requiredVariables,
      weight: weight,
      cooldown: const Duration(hours: 48),
      maxUsesPer7d: 3,
      compatibleKinds: <NotificationKind>[kind],
    );
  }

  group('NotificationSelectionEngine', () {
    final localCatalog = LocalNotificationTemplateCatalog(
      assetJsonLoader: AssetJsonLoader(),
    );

    test('selected result returns explicit metadata and never null', () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          timeOfDay: NotificationContextTimeOfDay.morning,
          progressRatio: 0.0,
          pendingCount: 0,
          completedCount: 0,
          totalCount: 1,
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected, isNotNull);
      expect(result.suppressionReason, isNull);
      expect(result.selected!.template.templateId, isNotEmpty);
      expect(result.selected!.kind, result.selected!.opportunity.kind);
    });

    test('suppresses when personalized notifications are disabled', () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(),
        preferences: NotificationPreferences.defaults().copyWith(
          generalNotificationsEnabled: false,
        ),
      );

      expect(result.isSelected, isFalse);
      expect(
        result.suppressionReason,
        NotificationSelectionSuppressionReason.personalizedDisabled,
      );
    });

    test('suppresses during quiet hours', () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(now: DateTime(2026, 8, 28, 23, 30)),
        preferences: NotificationPreferences.defaults().copyWith(
          quietHoursStart: const NotificationClockTime(hour: 23, minute: 0),
          quietHoursEnd: const NotificationClockTime(hour: 7, minute: 0),
        ),
      );

      expect(result.isSelected, isFalse);
      expect(
        result.suppressionReason,
        NotificationSelectionSuppressionReason.quietHours,
      );
    });

    test('completed day wins over generic motivation when progress is 100%',
        () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          now: DateTime(2026, 8, 28, 20, 30),
          timeOfDay: NotificationContextTimeOfDay.evening,
          progressRatio: 1.0,
          pendingCount: 0,
          completedCount: 4,
          totalCount: 4,
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(
          result.selected!.category, NotificationTemplateCategory.completedDay);
      expect(result.selected!.reason,
          NotificationSelectionReason.completedDayPriority);
    });

    test('comeback wins over morning fallback after inactivity', () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          timeOfDay: NotificationContextTimeOfDay.morning,
          inactivityDays: 5,
          displayName: 'Nora',
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected!.category, NotificationTemplateCategory.comeback);
      expect(result.selected!.kind, NotificationKind.generalInactivity);
    });

    test('strong progress beats generic encouragement when progress is high',
        () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          progressRatio: 0.8,
          pendingCount: 1,
          completedCount: 4,
          totalCount: 5,
          habitName: 'Leer',
        ),
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.active,
        ),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected!.category,
          NotificationTemplateCategory.strongProgress);
      expect(result.selected!.kind, NotificationKind.generalProgressNudge);
    });

    test('streak templates beat generic categories when streak is relevant',
        () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          streak: 7,
          displayName: 'Nora',
          progressRatio: 0.4,
          completedCount: 2,
          totalCount: 5,
          pendingCount: 3,
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected!.category, NotificationTemplateCategory.streak);
      expect(result.selected!.kind, NotificationKind.generalStreakRisk);
    });

    test('last template is excluded and a different candidate is selected',
        () async {
      final now = DateTime(2026, 8, 28, 19, 0);
      final history = buildHistory(
        deliveries: <NotificationDeliveryRecord>[
          buildDelivery(
            templateId: 'general.streak.encouragement_01',
            kind: NotificationKind.generalStreakRisk,
            scheduledAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        lastByTemplate: <String, DateTime>{
          'general.streak.encouragement_01':
              now.subtract(const Duration(hours: 1)),
        },
      );

      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          now: now,
          streak: 5,
          progressRatio: 0.4,
          completedCount: 2,
          totalCount: 4,
          pendingCount: 2,
          history: history,
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected!.template.templateId,
          isNot('general.streak.encouragement_01'));
    });

    test('category cooldown relaxes when it is the only viable candidate',
        () async {
      final template = buildTemplate(
        templateId: 'general.morning.only_01',
        category: NotificationTemplateCategory.morning,
        kind: NotificationKind.generalProgressNudge,
        isFallbackCandidate: true,
        eligibility: NotificationTemplateEligibility(
          allowedTimesOfDay: const <NotificationContextTimeOfDay>[
            NotificationContextTimeOfDay.morning,
          ],
          requiresCompletedDay: false,
          requiresStreak: false,
          requiresDisplayName: false,
          requiresInactivity: false,
        ),
      );
      final engine = NotificationSelectionEngine(
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[template],
        ),
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );
      final now = DateTime(2026, 8, 28, 8, 0);

      final result = await engine.selectTemplate(
        context: buildContext(
          now: now,
          timeOfDay: NotificationContextTimeOfDay.morning,
          history: buildHistory(
            lastByCategory: <String, DateTime>{
              NotificationTemplateCategory.morning.wireName:
                  now.subtract(const Duration(hours: 2)),
            },
          ),
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.diagnostics.usedRelaxedCategoryCooldown, isTrue);
    });

    test(
        'emergency fallback can reuse the last fallback template when everything else is blocked',
        () async {
      final template = buildTemplate(
        templateId: 'general.encouragement.only_01',
        category: NotificationTemplateCategory.encouragement,
        kind: NotificationKind.generalProgressNudge,
        isFallbackCandidate: true,
      );
      final now = DateTime(2026, 8, 28, 14, 0);
      final history = buildHistory(
        deliveries: <NotificationDeliveryRecord>[
          buildDelivery(
            templateId: 'general.encouragement.only_01',
            kind: NotificationKind.generalProgressNudge,
            scheduledAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        lastByTemplate: <String, DateTime>{
          'general.encouragement.only_01':
              now.subtract(const Duration(hours: 1)),
        },
        lastByCategory: <String, DateTime>{
          NotificationTemplateCategory.encouragement.wireName:
              now.subtract(const Duration(hours: 1)),
        },
      );
      final engine = NotificationSelectionEngine(
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[template],
        ),
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          now: now,
          timeOfDay: NotificationContextTimeOfDay.afternoon,
          history: history,
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected!.template.templateId,
          'general.encouragement.only_01');
      expect(result.diagnostics.usedEmergencyLastTemplateFallback, isTrue);
    });

    test(
        'suppresses with frequencyLimitReached when only candidate exceeded max uses',
        () async {
      final template = NotificationTemplateDescriptor(
        templateId: 'general.encouragement.capped_01',
        templateKey: 'generalMorningGentle01',
        localeNamespace: 'personalizedNotifications',
        category: NotificationTemplateCategory.encouragement,
        eligibility: NotificationTemplateEligibility.none(),
        isFallbackCandidate: true,
        weight: 10,
        cooldown: const Duration(hours: 1),
        maxUsesPer7d: 1,
        compatibleKinds: const <NotificationKind>[
          NotificationKind.generalProgressNudge,
        ],
      );
      final now = DateTime(2026, 8, 28, 15, 0);
      final history = buildHistory(
        deliveries: <NotificationDeliveryRecord>[
          buildDelivery(
            templateId: 'general.encouragement.capped_01',
            kind: NotificationKind.generalProgressNudge,
            scheduledAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      );
      final engine = NotificationSelectionEngine(
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[template],
        ),
        randomSource: FixedNotificationRandomSource(<double>[0.0]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(now: now, history: history),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isFalse);
      expect(
        result.suppressionReason,
        NotificationSelectionSuppressionReason.frequencyLimitReached,
      );
    });

    test('selection is reproducible with the same seed', () async {
      final firstEngine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: SeededNotificationRandomSource(42),
      );
      final secondEngine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: SeededNotificationRandomSource(42),
      );
      final context = buildContext(
        progressRatio: 0.35,
        pendingCount: 2,
        completedCount: 1,
        totalCount: 3,
        timeOfDay: NotificationContextTimeOfDay.morning,
      );

      final first = await firstEngine.selectTemplate(
        context: context,
        preferences: NotificationPreferences.defaults(),
      );
      final second = await secondEngine.selectTemplate(
        context: context,
        preferences: NotificationPreferences.defaults(),
      );

      expect(first.selected!.template.templateId,
          second.selected!.template.templateId);
    });

    test(
        'selected template always belongs to the catalog and respects required variables',
        () async {
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.12]),
      );
      final catalogTemplates = await localCatalog.listAll();
      final catalogIds =
          catalogTemplates.map((template) => template.templateId).toSet();

      final result = await engine.selectTemplate(
        context: buildContext(
          displayName: 'Nora',
          progressRatio: 0.5,
          pendingCount: 2,
          completedCount: 2,
          totalCount: 4,
          streak: 6,
          inactivityDays: 4,
          habitName: 'Leer',
          timeOfDay: NotificationContextTimeOfDay.evening,
        ),
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.active,
        ),
      );

      expect(result.isSelected, isTrue);
      expect(catalogIds.contains(result.selected!.template.templateId), isTrue);
      for (final variable in result.selected!.template.requiredVariables) {
        expect(
          result.selected!.renderContext.hasValueFor(variable),
          isTrue,
          reason: variable.wireName,
        );
      }
      expect(
        result.selected!.template.supports(result.selected!.kind),
        isTrue,
      );
    });

    test(
        'does not crash with 30 history entries and still returns an eligible template',
        () async {
      final now = DateTime(2026, 8, 28, 18, 30);
      final deliveries = List<NotificationDeliveryRecord>.generate(30, (index) {
        return buildDelivery(
          templateId: index.isEven
              ? 'general.encouragement.neutral_01'
              : 'general.motivation.gentle_01',
          kind: NotificationKind.generalProgressNudge,
          scheduledAt: now.subtract(Duration(hours: index + 2)),
        );
      });
      final history = buildHistory(
        deliveries: deliveries,
        lastByTemplate: <String, DateTime>{
          'general.encouragement.neutral_01':
              now.subtract(const Duration(hours: 2)),
          'general.motivation.gentle_01':
              now.subtract(const Duration(hours: 3)),
        },
        lastByCategory: <String, DateTime>{
          NotificationTemplateCategory.encouragement.wireName:
              now.subtract(const Duration(hours: 2)),
          NotificationTemplateCategory.gentleMotivation.wireName:
              now.subtract(const Duration(hours: 3)),
        },
      );
      final engine = NotificationSelectionEngine(
        templateCatalog: localCatalog,
        randomSource: FixedNotificationRandomSource(<double>[0.5]),
      );

      final result = await engine.selectTemplate(
        context: buildContext(
          now: now,
          timeOfDay: NotificationContextTimeOfDay.evening,
          displayName: 'Nora',
          progressRatio: 0.75,
          pendingCount: 1,
          completedCount: 3,
          totalCount: 4,
          streak: 5,
          habitName: 'Leer',
          history: history,
        ),
        preferences: NotificationPreferences.defaults(),
      );

      expect(result.isSelected, isTrue);
      expect(result.selected!.effectiveWeight, greaterThan(0));
    });
  });
}
