import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/core/notifications/notification_permission_service.dart';
import 'package:rutio/features/onboarding/onboarding.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  test('ReminderDraft round-trips stable hour/minute and all states', () {
    for (final permission in ReminderPermissionState.values) {
      for (final scheduling in ReminderSchedulingState.values) {
        final enabled = scheduling != ReminderSchedulingState.disabled;
        final value = OnboardingReminderConfiguration(
          enabled: enabled,
          selectedTime: enabled
              ? const OnboardingReminderTime(hour: 9, minute: 35)
              : null,
          permissionState: permission,
          schedulingState: scheduling,
        );
        final decoded = OnboardingReminderDraftAdapter.decode(
          OnboardingReminderDraftAdapter.encode(value),
        );
        expect(decoded.enabled, enabled);
        expect(decoded.selectedTime, value.selectedTime);
        expect(decoded.permissionState, permission);
        expect(decoded.schedulingState, scheduling);
      }
    }
  });

  test('invalid time and incomplete decisions are rejected', () {
    expect(
      OnboardingReminderDraftAdapter.tryDecode({
        'enabled': true,
        'selectedTime': {'hour': 24, 'minute': 0},
        'permissionState': 'notRequested',
        'schedulingState': 'notRequested',
      }),
      isNull,
    );
    expect(
      OnboardingReminderConfigurationValidator.validate(
        const OnboardingReminderConfiguration(
          enabled: true,
          selectedTime: null,
          permissionState: ReminderPermissionState.notRequested,
          schedulingState: ReminderSchedulingState.notRequested,
        ),
      ).isValid,
      isFalse,
    );
  });

  test('permission adapter maps the real service result to onboarding states',
      () {
    expect(
      AppOnboardingReminderPermissionGateway.mapPermissionResult(
        const NotificationPermissionResult(
          status: NotificationPermissionStatus.authorized,
        ),
      ),
      ReminderPermissionState.authorized,
    );
    expect(
      AppOnboardingReminderPermissionGateway.mapPermissionResult(
        const NotificationPermissionResult(
          status: NotificationPermissionStatus.provisional,
        ),
      ),
      ReminderPermissionState.provisional,
    );
    expect(
      AppOnboardingReminderPermissionGateway.mapPermissionResult(
        const NotificationPermissionResult(
          status: NotificationPermissionStatus.denied,
        ),
      ),
      ReminderPermissionState.denied,
    );
    expect(
      AppOnboardingReminderPermissionGateway.mapPermissionResult(
        const NotificationPermissionResult(
          status: NotificationPermissionStatus.permanentlyDenied,
        ),
      ),
      ReminderPermissionState.restricted,
    );
  });

  test('Now Not persists disabled and never asks permission', () async {
    final store = _MemoryStore()..anonymous = _reminderDraft();
    final gateway = _FakePermissionGateway(ReminderPermissionState.authorized);
    final coordinator = _coordinator(store, gateway);
    await coordinator.resume();
    coordinator.continueDraft();

    expect(
      await coordinator.submitReminder(
        OnboardingReminderConfiguration.disabled(),
      ),
      isTrue,
    );
    expect(coordinator.effectiveStep, OnboardingStep.preview);
    expect(gateway.calls, 0);
    expect(
      OnboardingReminderDraftAdapter.decode(store.anonymous!.reminder!),
      const TypeMatcher<OnboardingReminderConfiguration>(),
    );
    final saved = OnboardingReminderDraftAdapter.decode(
      store.anonymous!.reminder!,
    );
    expect(saved.enabled, isFalse);
    expect(saved.permissionState, ReminderPermissionState.notRequested);
    expect(saved.schedulingState, ReminderSchedulingState.disabled);
  });

  test('authorized enable persists readyToSchedule without scheduling',
      () async {
    final store = _MemoryStore()..anonymous = _reminderDraft();
    final gateway = _FakePermissionGateway(ReminderPermissionState.authorized);
    final coordinator = _coordinator(store, gateway);
    await coordinator.resume();
    coordinator.continueDraft();

    expect(
      await coordinator.submitReminder(
        OnboardingReminderConfiguration.pending(
          selectedTime: const OnboardingReminderTime(hour: 7, minute: 5),
        ),
      ),
      isTrue,
    );
    final saved = OnboardingReminderDraftAdapter.decode(
      store.anonymous!.reminder!,
    );
    expect(coordinator.effectiveStep, OnboardingStep.preview);
    expect(gateway.calls, 1);
    expect(saved.permissionState, ReminderPermissionState.authorized);
    expect(saved.schedulingState, ReminderSchedulingState.readyToSchedule);
    expect(
        saved.selectedTime, const OnboardingReminderTime(hour: 7, minute: 5));
  });

  test('selected recommendation time is only an initial suggestion', () async {
    final store = _MemoryStore()..anonymous = _reminderDraft();
    final coordinator = _coordinator(
      store,
      _FakePermissionGateway(ReminderPermissionState.authorized),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    final initial = coordinator.reminderConfigurationForDraft();
    expect(initial?.selectedTime,
        const OnboardingReminderTime(hour: 8, minute: 0));
    expect(initial?.enabled, isFalse);
    expect(initial?.schedulingState, ReminderSchedulingState.notRequested);
    expect(store.anonymous?.reminder, isNull);
  });

  test('denied is non-blocking and persistence retry does not prompt twice',
      () async {
    final store = _MemoryStore()..anonymous = _reminderDraft();
    final gateway = _FakePermissionGateway(ReminderPermissionState.denied);
    final coordinator = _coordinator(store, gateway);
    await coordinator.resume();
    coordinator.continueDraft();
    final value = OnboardingReminderConfiguration.pending(
      selectedTime: const OnboardingReminderTime(hour: 18, minute: 20),
    );

    store.failWrites = true;
    expect(await coordinator.submitReminder(value), isFalse);
    expect(gateway.calls, 1);
    store.failWrites = false;
    expect(await coordinator.submitReminder(value), isTrue);
    expect(gateway.calls, 1);
    final saved = OnboardingReminderDraftAdapter.decode(
      store.anonymous!.reminder!,
    );
    expect(coordinator.effectiveStep, OnboardingStep.preview);
    expect(saved.permissionState, ReminderPermissionState.denied);
    expect(saved.schedulingState, ReminderSchedulingState.pendingRetry);
  });

  test('changing time after authorization does not request again', () async {
    final existing = OnboardingReminderDraftAdapter.encode(
      const OnboardingReminderConfiguration(
        enabled: true,
        selectedTime: OnboardingReminderTime(hour: 8, minute: 0),
        permissionState: ReminderPermissionState.authorized,
        schedulingState: ReminderSchedulingState.readyToSchedule,
      ),
    );
    final store = _MemoryStore()
      ..anonymous = _reminderDraft(reminder: existing);
    final gateway = _FakePermissionGateway(ReminderPermissionState.denied);
    final coordinator = _coordinator(store, gateway);
    await coordinator.resume();
    coordinator.continueDraft();

    expect(
      await coordinator.submitReminder(
        OnboardingReminderConfiguration.pending(
          selectedTime: const OnboardingReminderTime(hour: 9, minute: 10),
        ),
      ),
      isTrue,
    );
    expect(gateway.calls, 0);
    final saved = OnboardingReminderDraftAdapter.decode(
      store.anonymous!.reminder!,
    );
    expect(saved.permissionState, ReminderPermissionState.authorized);
    expect(saved.schedulingState, ReminderSchedulingState.readyToSchedule);
  });

  test('Back from Preview restores the confirmed reminder without prompting',
      () async {
    final store = _MemoryStore()..anonymous = _reminderDraft();
    final gateway = _FakePermissionGateway(ReminderPermissionState.authorized);
    final coordinator = _coordinator(store, gateway);
    await coordinator.resume();
    coordinator.continueDraft();
    await coordinator.submitReminder(
      OnboardingReminderConfiguration.pending(
        selectedTime: const OnboardingReminderTime(hour: 6, minute: 45),
      ),
    );

    expect(await coordinator.goBack(), isTrue);
    final restored = coordinator.reminderConfigurationForDraft();
    expect(coordinator.effectiveStep, OnboardingStep.reminder);
    expect(restored?.enabled, isTrue);
    expect(restored?.selectedTime,
        const OnboardingReminderTime(hour: 6, minute: 45));
    expect(restored?.permissionState, ReminderPermissionState.authorized);
    expect(gateway.calls, 1);
  });

  test('stale permission callback cannot modify a restarted flow', () async {
    final store = _MemoryStore()..anonymous = _reminderDraft();
    final gateway = _FakePermissionGateway.deferred();
    final coordinator = _coordinator(store, gateway);
    await coordinator.resume();
    coordinator.continueDraft();
    final request = coordinator.submitReminder(
      OnboardingReminderConfiguration.pending(
        selectedTime: const OnboardingReminderTime(hour: 10, minute: 0),
      ),
    );
    coordinator.invalidateAsyncOperations();
    gateway.complete(ReminderPermissionState.authorized);
    expect(await request, isFalse);
    expect(store.anonymous!.reminder, isNull);
  });

  testWidgets(
      'ReminderStep shows copy, suggested time, custom picker and Now Not',
      (tester) async {
    OnboardingReminderConfiguration? submitted;
    await tester.pumpWidget(_app(
      OnboardingReminderStep(
        initialConfiguration: OnboardingReminderConfiguration.pending(
          selectedTime: const OnboardingReminderTime(hour: 8, minute: 0),
        ),
        onDecisionChanged: (_) {},
        onSubmit: (value) => submitted = value,
      ),
    ));

    expect(
        find.text(
            'Podemos avisarte cuando llegue el momento. Podrás cambiarlo o desactivarlo más adelante desde Ajustes.'),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('onboardingReminderEnable')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('onboardingReminderNotNow')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboardingReminderEnable')));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('onboardingReminderTime')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboardingReminderTime')));
    await tester.pump();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    Navigator.of(tester.element(find.byType(CupertinoDatePicker))).pop();
    await tester.pump();
    tester
        .state<OnboardingReminderStepState>(find.byType(OnboardingReminderStep))
        .submit();
    expect(submitted?.enabled, isTrue);
    expect(submitted?.selectedTime,
        const OnboardingReminderTime(hour: 8, minute: 0));

    await tester.tap(find.byKey(const ValueKey('onboardingReminderNotNow')));
    expect(submitted?.enabled, isFalse);
  });
}

OnboardingCoordinator _coordinator(
  _MemoryStore store,
  OnboardingReminderPermissionGateway gateway,
) {
  return OnboardingCoordinator(
    draftService: OnboardingDraftService(store: store),
    reminderPermissionGateway: gateway,
  );
}

OnboardingDraft _reminderDraft({Map<String, dynamic>? reminder}) {
  return OnboardingDraft(
    draftId: '11111111-1111-4111-8111-111111111111',
    onboardingOperationId: '22222222-2222-4222-8222-222222222222',
    draftSchemaVersion: 1,
    onboardingVersion: 1,
    catalogVersion: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    currentStep: OnboardingStep.reminder,
    firstName: 'Ana',
    goalCodes: {'care_body'},
    pace: OnboardingPace.balanced,
    selectedRecommendationId: 'onboarding_v1_move_body',
    habit: const {
      'name': 'Caminar',
      'emoji': '👟',
      'type': 'check',
      'schedule': {'type': 'daily'},
      'reminderEnabled': false,
    },
    reminder: reminder,
  );
}

class _FakePermissionGateway implements OnboardingReminderPermissionGateway {
  _FakePermissionGateway(this.result) : _completer = null;

  _FakePermissionGateway.deferred()
      : result = ReminderPermissionState.authorized,
        _completer = Completer<ReminderPermissionState>();

  final ReminderPermissionState result;
  final Completer<ReminderPermissionState>? _completer;
  int calls = 0;

  @override
  Future<ReminderPermissionState> requestPermission() {
    calls++;
    return _completer?.future ?? Future.value(result);
  }

  void complete(ReminderPermissionState value) => _completer!.complete(value);
}

class _MemoryStore implements OnboardingDraftStore {
  OnboardingDraft? anonymous;
  bool failWrites = false;

  @override
  Future<void> deleteAnonymousDraft() async => anonymous = null;
  @override
  Future<void> deleteForUser(String userId) async {}
  @override
  Future<bool> hasAnonymousDraft() async => anonymous != null;
  @override
  Future<OnboardingDraft?> loadAnonymousDraft() async => anonymous;
  @override
  Future<OnboardingDraftLoadResult> loadAnonymousDraftResult() async =>
      anonymous == null
          ? const OnboardingDraftLoadResult.missing()
          : OnboardingDraftLoadResult(
              status: OnboardingDraftLoadStatus.valid,
              draft: anonymous,
            );
  @override
  Future<OnboardingDraft?> loadForUser(String userId) async => null;
  @override
  Future<void> saveAnonymousDraft(OnboardingDraft draft) async {
    if (failWrites) throw StateError('write failed');
    anonymous = draft;
  }

  @override
  Future<void> saveForUser(String userId, OnboardingDraft draft) async {}
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
