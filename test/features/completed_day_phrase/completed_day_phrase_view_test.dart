import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/completed_day_phrase/completed_day_phrase.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget harness(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('author is omitted when null and shown when present',
      (tester) async {
    await tester.pumpWidget(harness(
      const Column(
        children: [
          CompletedDayPhraseView(text: 'A phrase', author: null),
          CompletedDayPhraseView(text: 'Another phrase', author: 'Rutio'),
        ],
      ),
    ));

    expect(find.text('A phrase'), findsOneWidget);
    expect(find.text('Another phrase'), findsOneWidget);
    expect(find.text('Rutio'), findsOneWidget);
  });

  testWidgets('long text uses intrinsic layout without a fixed height',
      (tester) async {
    await tester.pumpWidget(harness(
      const CompletedDayPhraseView(
        text:
            'A long phrase that should wrap naturally and remain safe inside the Home layout without clipping.',
      ),
    ));

    final text = tester.widget<Text>(find.textContaining('A long phrase'));
    expect(text.maxLines, 2);
    expect(tester.getSize(find.byType(CompletedDayPhraseView)).height,
        greaterThan(0));
  });

  testWidgets('hidden host leaves no residual content', (tester) async {
    final controller = CompletedDayPhraseController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(
      CompletedDayPhraseHost(
        controller: controller,
        eligibility: const CompletedDayEligibility(
          isReady: true,
          isLocalToday: true,
          scheduledHabitCount: 0,
          completedHabitCount: 0,
          pendingHabitCount: 0,
          skippedHabitCount: 0,
        ),
        input: CompletedDayPhraseInput(
          userId: 'user-a',
          localDate: DateTime(2026, 9, 4),
          locale: 'es',
          name: null,
          streak: 0,
          streakLabel: '0 días',
        ),
      ),
    ));

    expect(find.byType(CompletedDayPhraseView), findsNothing);
    expect(tester.getSize(find.byType(CompletedDayPhraseHost)).height, 0);
  });

  testWidgets(
      'completed day uses the phrase view instead of the legacy pending empty state',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = CompletedDayPhraseController(
      service: CompletedDayPhraseService(
        catalogSource: _SinglePhraseCatalogSource(),
        historyStore: SharedPreferencesCompletedDayPhraseStore(),
      ),
    );
    addTearDown(controller.dispose);

    final eligibility = const CompletedDayEligibility(
      isReady: true,
      isLocalToday: true,
      scheduledHabitCount: 1,
      completedHabitCount: 1,
      pendingHabitCount: 0,
      skippedHabitCount: 0,
    );
    final habit = <String, dynamic>{
      'id': 'habit-1',
      'doneToday': true,
      'skippedToday': false,
    };
    final homeData = HomeViewData(
      visibleHabits: <Map<String, dynamic>>[habit],
      viewHabits: <Map<String, dynamic>>[habit],
      pendingHabits: const <Map<String, dynamic>>[],
      completedHabits: <Map<String, dynamic>>[habit],
      skippedHabits: const <Map<String, dynamic>>[],
      doneCount: 1,
      totalCount: 1,
      dayLabel: 'Hoy',
      xpTotal: 0,
      level: 1,
      xpInLevel: 0,
      xpToNext: 100,
      xpProgress: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CompletedDayPhraseHost(
                  controller: controller,
                  eligibility: eligibility,
                  input: CompletedDayPhraseInput(
                    userId: 'user-a',
                    localDate: DateTime(2026, 9, 4),
                    locale: 'es-ES',
                    name: null,
                    streak: 1,
                    streakLabel: '1 día',
                  ),
                ),
              ),
              HomeScrollableContentSliver(
                homeData: homeData,
                selectedFilter: HomeHabitStatusFilter.pending,
                completedDayEligibility: eligibility,
                completionTransitions: const <HomeHabitCompletionTransition>[],
                habitCardBuilder: (_, __, {bool compact = false}) =>
                    const SizedBox(),
                completionTransitionBuilder: (_, __) => const SizedBox(),
                onCompletionTransitionDismissed: ({
                  required String habitId,
                  required String transitionId,
                }) {},
                onPendingReorder: (_, __) async {},
                onOpenAddHabit: () {},
                bottomPadding: 0,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CompletedDayPhraseView), findsOneWidget);
    expect(find.text('No tienes hábitos pendientes.'), findsNothing);
  });

  testWidgets('filter changes hide and restore the same daily phrase',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = CompletedDayPhraseController(
      service: CompletedDayPhraseService(
        catalogSource: _SinglePhraseCatalogSource(),
        historyStore: SharedPreferencesCompletedDayPhraseStore(),
      ),
    );
    addTearDown(controller.dispose);

    const eligibility = CompletedDayEligibility(
      isReady: true,
      isLocalToday: true,
      scheduledHabitCount: 1,
      completedHabitCount: 1,
      pendingHabitCount: 0,
      skippedHabitCount: 0,
    );
    final filter = ValueNotifier(HomeHabitStatusFilter.pending);
    addTearDown(filter.dispose);
    final input = CompletedDayPhraseInput(
      userId: 'user-a',
      localDate: DateTime(2026, 9, 4),
      locale: 'es-ES',
      name: null,
      streak: 1,
      streakLabel: '1 día',
    );
    final homeData = _completedHomeData();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<HomeHabitStatusFilter>(
            valueListenable: filter,
            builder: (context, selectedFilter, _) {
              return CustomScrollView(
                slivers: [
                  if (shouldShowCompletedDayPhrase(
                    selectedFilter: selectedFilter,
                    isCompletedDay: eligibility.isCompletedDay,
                  ))
                    SliverToBoxAdapter(
                      child: CompletedDayPhraseHost(
                        controller: controller,
                        eligibility: eligibility,
                        input: input,
                      ),
                    ),
                  HomeScrollableContentSliver(
                    homeData: homeData,
                    selectedFilter: selectedFilter,
                    completedDayEligibility: eligibility,
                    completionTransitions: const <HomeHabitCompletionTransition>[],
                    habitCardBuilder: (_, __, {bool compact = false}) =>
                        const SizedBox(),
                    completionTransitionBuilder: (_, __) => const SizedBox(),
                    onCompletionTransitionDismissed: ({
                      required String habitId,
                      required String transitionId,
                    }) {},
                    onPendingReorder: (_, __) async {},
                    onOpenAddHabit: () {},
                    bottomPadding: 0,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CompletedDayPhraseView), findsOneWidget);
    final selectedId = controller.state.phrase!.phrase.id;

    filter.value = HomeHabitStatusFilter.completed;
    await tester.pump();
    expect(find.byType(CompletedDayPhraseHost), findsNothing);
    expect(find.byType(CompletedDayPhraseView), findsNothing);

    filter.value = HomeHabitStatusFilter.pending;
    await tester.pump();
    expect(find.byType(CompletedDayPhraseView), findsOneWidget);
    expect(controller.state.phrase!.phrase.id, selectedId);

    filter.value = HomeHabitStatusFilter.skipped;
    await tester.pump();
    expect(find.byType(CompletedDayPhraseHost), findsNothing);
    expect(find.byType(CompletedDayPhraseView), findsNothing);

    filter.value = HomeHabitStatusFilter.pending;
    await tester.pump();
    expect(find.byType(CompletedDayPhraseView), findsOneWidget);
    expect(controller.state.phrase!.phrase.id, selectedId);
  });
}

HomeViewData _completedHomeData() {
  final habit = <String, dynamic>{
    'id': 'habit-1',
    'doneToday': true,
    'skippedToday': false,
  };
  return HomeViewData(
    visibleHabits: <Map<String, dynamic>>[habit],
    viewHabits: <Map<String, dynamic>>[habit],
    pendingHabits: const <Map<String, dynamic>>[],
    completedHabits: <Map<String, dynamic>>[habit],
    skippedHabits: const <Map<String, dynamic>>[],
    doneCount: 1,
    totalCount: 1,
    dayLabel: 'Hoy',
    xpTotal: 0,
    level: 1,
    xpInLevel: 0,
    xpToNext: 100,
    xpProgress: 0,
  );
}

class _SinglePhraseCatalogSource implements PhraseCatalogSource {
  @override
  Future<PhraseCatalog> load(String locale) async {
    return const PhraseCatalog(
      schemaVersion: 1,
      catalogVersion: 'test-v1',
      locale: 'es',
      phrases: <MotivationalPhrase>[
        MotivationalPhrase(
          id: 'completed-day-test',
          category: PhraseCategory.motivation,
          tone: PhraseTone.balanced,
          sourceType: PhraseSourceType.original,
          author: null,
          template: 'Cierre del día',
          requiredTokens: <String>[],
          weight: 1,
          enabled: true,
          contentVersion: 1,
        ),
      ],
    );
  }
}
