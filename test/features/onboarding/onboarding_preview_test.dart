import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/presentation/habit_schedule_label_resolver.dart';
import 'package:rutio/features/onboarding/onboarding.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  test('schedule label resolver keeps every schedule type distinct', () async {
    const resolver = HabitScheduleLabelResolver();
    final es = await AppLocalizations.delegate.load(const Locale('es'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(resolver.resolve(es, HabitSchedule.daily()), 'Todos los días');
    expect(
      resolver.resolve(
        es,
        HabitSchedule.timesPerWeek(timesPerWeek: 1),
      ),
      '1 vez por semana',
    );
    expect(
      resolver.resolve(
        es,
        HabitSchedule.timesPerWeek(timesPerWeek: 3),
      ),
      '3 veces por semana',
    );
    expect(
      resolver.resolve(es, HabitSchedule.weekly(weekdays: [1, 3, 5])),
      'Lun · Mié · Vie',
    );
    expect(
      resolver.resolve(
        en,
        HabitSchedule.timesPerWeek(timesPerWeek: 3),
      ),
      '3 times per week',
    );
  });

  testWidgets('Preview renders the complete read-only summary in Spanish',
      (tester) async {
    final edits = <OnboardingStep>[];
    var saved = false;
    await tester.pumpWidget(
      _app(
        OnboardingPreviewStep(
          goalCodes: const {'care_body', 'find_calm'},
          pace: OnboardingPace.balanced,
          habit: _countHabit(),
          reminder: _enabledReminder(),
          onEdit: edits.add,
          onSave: () => saved = true,
        ),
      ),
    );

    expect(find.text('Objetivos'), findsOneWidget);
    expect(find.text('Cuidar mi cuerpo · Tener más calma'), findsOneWidget);
    expect(find.text('Equilibrado'), findsOneWidget);
    expect(find.text('Leer'), findsWidgets);
    expect(find.text('Mente · Contador · Lun · Mié · Vie'), findsOneWidget);
    expect(find.text('Objetivo: 10 minutos'), findsOneWidget);
    expect(find.text('7:05 · activado'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingPreviewHabitCard')),
        findsOneWidget);
    expect(find.text('Guardar mi Rutio'), findsOneWidget);

    for (final key in [
      'onboardingPreviewEditGoals',
      'onboardingPreviewEditPace',
      'onboardingPreviewEditHabit',
      'onboardingPreviewEditReminder',
      'onboardingPreviewSave',
    ]) {
      final finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
    }
    expect(
      edits,
      [
        OnboardingStep.goals,
        OnboardingStep.pace,
        OnboardingStep.habit,
        OnboardingStep.reminder,
      ],
    );
    expect(saved, isTrue);
  });

  testWidgets('Preview localizes English, supports no reminder and scales',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: OnboardingPreviewStep(
            goalCodes: const {'learn_grow'},
            pace: OnboardingPace.gentle,
            habit: _countHabit().copyWith(
              schedule: HabitSchedule.daily(),
            ),
            reminder: OnboardingReminderConfiguration.disabled(),
            onEdit: (_) {},
            onSave: () {},
          ),
        ),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Learn and grow'), findsOneWidget);
    expect(find.text('Little by little'), findsOneWidget);
    expect(find.text('Mind · Counter · Every day'), findsOneWidget);
    expect(find.text('No reminder'), findsOneWidget);
    expect(find.text('Save my Rutio'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingPreviewHabitCard')),
        findsOneWidget);
  });

  testWidgets('Preview formats flexible weekly targets in Spanish and English',
      (tester) async {
    await tester.pumpWidget(
      _app(
        OnboardingPreviewStep(
          goalCodes: const {'care_body'},
          pace: OnboardingPace.balanced,
          habit: OnboardingHabitConfiguration(
            name: 'Caminar',
            emoji: '👟',
            primaryFamilyCode: 'body',
            kind: HabitKind.check,
            schedule: HabitSchedule.timesPerWeek(timesPerWeek: 3),
          ),
          reminder: OnboardingReminderConfiguration.disabled(),
          onEdit: (_) {},
          onSave: () {},
        ),
      ),
    );

    expect(find.text('3 veces por semana'), findsOneWidget);
    expect(find.text('Todos los días'), findsNothing);

    await tester.pumpWidget(
      _app(
        OnboardingPreviewStep(
          goalCodes: const {'care_body'},
          pace: OnboardingPace.balanced,
          habit: OnboardingHabitConfiguration(
            name: 'Caminar',
            emoji: '👟',
            primaryFamilyCode: 'body',
            kind: HabitKind.check,
            schedule: HabitSchedule.timesPerWeek(timesPerWeek: 1),
          ),
          reminder: OnboardingReminderConfiguration.disabled(),
          onEdit: (_) {},
          onSave: () {},
        ),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('1 time per week'), findsOneWidget);
    expect(find.text('Every day'), findsNothing);
  });

  testWidgets(
      'Preview keeps check habits target-free and surfaces pending permission',
      (tester) async {
    await tester.pumpWidget(
      _app(
        OnboardingPreviewStep(
          goalCodes: const {'care_body'},
          pace: OnboardingPace.energized,
          habit: OnboardingHabitConfiguration(
            name: 'Respirar',
            emoji: '🌬️',
            primaryFamilyCode: 'emotional',
            kind: HabitKind.check,
            schedule: HabitSchedule.daily(),
          ),
          reminder: const OnboardingReminderConfiguration(
            enabled: true,
            selectedTime: OnboardingReminderTime(hour: 18, minute: 20),
            permissionState: ReminderPermissionState.denied,
            schedulingState: ReminderSchedulingState.pendingRetry,
          ),
          onEdit: (_) {},
          onSave: () {},
        ),
      ),
    );

    expect(find.textContaining('· Check ·'), findsOneWidget);
    expect(find.text('Mente · Check · Todos los días'), findsNothing);
    expect(find.text('Emocional · Check · Todos los días'), findsOneWidget);
    expect(find.text('Preparado para activarlo desde Ajustes'), findsOneWidget);
    expect(find.textContaining('Objetivo:'), findsNothing);
  });

  test('Preview guard requires every preceding decision', () async {
    final store = _MemoryStore()..anonymous = _previewDraft(incomplete: true);
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();

    expect(coordinator.effectiveStep, OnboardingStep.reminder);
    expect(await coordinator.continueFromPreview(), isFalse);
  });

  test('Preview also resumes for a resolved custom-habit route', () async {
    final store = _MemoryStore()
      ..anonymous = _previewDraft().copyWith(selectedRecommendationId: null);
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();

    expect(coordinator.effectiveStep, OnboardingStep.preview);
    expect(await coordinator.continueFromPreview(), isTrue);
  });

  test('Preview edits return directly and retain draft identity and habit',
      () async {
    final store = _MemoryStore()..anonymous = _previewDraft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    final original = store.anonymous!;
    final originalHabit = original.habit;

    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.goToStepForEditing(OnboardingStep.goals), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(await coordinator.submitGoals({'care_body'}), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.preview);
    expect(store.anonymous!.habit, originalHabit);

    expect(await coordinator.goToStepForEditing(OnboardingStep.pace), isTrue);
    expect(await coordinator.submitPace(OnboardingPace.gentle), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.preview);

    final habit = coordinator.habitConfigurationForDraft()!;
    expect(await coordinator.goToStepForEditing(OnboardingStep.habit), isTrue);
    expect(await coordinator.submitHabit(habit.copyWith(name: 'Leer')), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.preview);

    final reminder = coordinator.reminderConfigurationForDraft()!;
    expect(
        await coordinator.goToStepForEditing(OnboardingStep.reminder), isTrue);
    expect(await coordinator.submitReminder(reminder), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.preview);

    expect(store.anonymous!.draftId, original.draftId);
    expect(
        store.anonymous!.onboardingOperationId, original.onboardingOperationId);
    expect(store.anonymous!.catalogVersion, original.catalogVersion);
  });

  test('Save my Rutio advances only to Auth without external side effects',
      () async {
    final store = _MemoryStore()..anonymous = _previewDraft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.continueFromPreview(), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.auth);
    expect(store.anonymous!.currentStep, OnboardingStep.auth);
    expect(store.userWrites, 0);
  });
}

OnboardingHabitConfiguration _countHabit() => OnboardingHabitConfiguration(
      name: 'Leer',
      emoji: '📖',
      primaryFamilyCode: 'mind',
      kind: HabitKind.count,
      targetValue: 10,
      unit: 'minutos',
      schedule: HabitSchedule.weekly(weekdays: [1, 3, 5]),
    );

OnboardingReminderConfiguration _enabledReminder() =>
    const OnboardingReminderConfiguration(
      enabled: true,
      selectedTime: OnboardingReminderTime(hour: 7, minute: 5),
      permissionState: ReminderPermissionState.authorized,
      schedulingState: ReminderSchedulingState.readyToSchedule,
    );

OnboardingDraft _previewDraft({bool incomplete = false}) {
  return OnboardingDraft(
    draftId: '11111111-1111-4111-8111-111111111111',
    onboardingOperationId: '22222222-2222-4222-8222-222222222222',
    draftSchemaVersion: 1,
    onboardingVersion: 1,
    catalogVersion: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    currentStep: OnboardingStep.preview,
    firstName: 'Ana',
    goalCodes: const {'care_body'},
    pace: OnboardingPace.balanced,
    selectedRecommendationId: 'onboarding_v1_move_body',
    habit: OnboardingHabitDraftAdapter.encode(
      OnboardingHabitConfiguration(
        name: 'Caminar',
        emoji: '👟',
        primaryFamilyCode: 'body',
        kind: HabitKind.check,
        schedule: HabitSchedule.daily(),
      ),
    ),
    reminder: incomplete
        ? null
        : OnboardingReminderDraftAdapter.encode(_enabledReminder()),
  );
}

class _MemoryStore implements OnboardingDraftStore {
  OnboardingDraft? anonymous;
  int userWrites = 0;

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
  Future<void> saveAnonymousDraft(OnboardingDraft draft) async =>
      anonymous = draft;

  @override
  Future<void> saveForUser(String userId, OnboardingDraft draft) async {
    userWrites += 1;
  }
}

Widget _app(Widget child, {Locale locale = const Locale('es')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
