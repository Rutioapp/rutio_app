import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/onboarding/onboarding.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_MemoryStore> pumpScreen(
    WidgetTester tester, {
    OnboardingDraft? draft,
    Locale locale = const Locale('es'),
    double textScaleFactor = 1,
    Size size = const Size(390, 844),
    bool failWrites = false,
  }) async {
    final store = _MemoryStore()..anonymous = draft;
    store.failWrites = failWrites;
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<OnboardingCoordinator>.value(
            value: coordinator,
            child: const OnboardingV1Screen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    return store;
  }

  Future<_MemoryStore> pumpPace(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    Size size = const Size(390, 844),
    double textScaleFactor = 1,
    bool failPaceWrites = false,
  }) async {
    final store = await pumpScreen(
      tester,
      locale: locale,
      size: size,
      textScaleFactor: textScaleFactor,
      draft: _draft(firstName: 'Ana'),
    );
    final spanish = locale.languageCode == 'es';
    final resume =
        spanish ? 'Continuar donde lo dejé' : 'Continue where I left off';
    final continueLabel = spanish ? 'Continuar' : 'Continue';
    final goal = spanish ? 'Cuidar mi cuerpo' : 'Take care of my body';
    if (size.height < 600) {
      await tester.scrollUntilVisible(
        find.text(resume),
        180,
        scrollable: find.byType(Scrollable),
      );
    }
    await tester.tap(find.text(resume));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(continueLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    if (size.height < 600) {
      await tester.scrollUntilVisible(
        find.text(goal),
        180,
        scrollable: find.byType(Scrollable),
      );
    }
    await tester.tap(find.text(goal));
    await tester.pump();
    await tester.tap(find.text(continueLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    store.failWrites = failPaceWrites;
    return store;
  }

  testWidgets('Welcome without a draft shows Prepare and existing account',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Preparar mi Rutio'), findsOneWidget);
    expect(find.text('Ya tengo una cuenta'), findsOneWidget);
    expect(find.text('Continuar donde lo dejé'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Welcome with a draft offers Continue where I left off',
      (tester) async {
    await pumpScreen(tester, draft: _draft(firstName: 'Ana'));

    expect(find.text('Continuar donde lo dejé'), findsOneWidget);
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Objetivos'), findsWidgets);
  });

  testWidgets('Restart requires confirmation and returns to the first step',
      (tester) async {
    await pumpScreen(tester, draft: _draft(firstName: 'Ana'));

    await tester.tap(find.text('Empezar de nuevo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¿Empezar de nuevo?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Empezar de nuevo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
  });

  testWidgets('Name step shows its real copy, input and Continue CTA',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Preparar mi Rutio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    expect(
      find.text('Así podremos hacer Rutio un poco más tuyo.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('Name step rejects empty, whitespace and overlong input inline',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Preparar mi Rutio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final continueButton = find.text('Continuar');
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Escribe tu nombre para continuar.'), findsOneWidget);
    expect(find.text('Objetivos'), findsNothing);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Escribe tu nombre para continuar.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a' * 31);
    await tester.tap(continueButton);
    await tester.pump();
    expect(
      find.text('El nombre puede tener como máximo 30 caracteres.'),
      findsOneWidget,
    );
    expect(find.text('Objetivos'), findsNothing);
  });

  testWidgets('Name step trims valid Unicode and advances on Continue',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Preparar mi Rutio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), '  Vicenç  ');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Objetivos'), findsWidgets);
  });

  testWidgets('Name field Done action uses the same submit intent',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Preparar mi Rutio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Objetivos'), findsWidgets);
  });

  testWidgets('Name step preloads confirmed value and Back preserves it',
      (tester) async {
    await pumpScreen(tester, draft: _draft(firstName: 'Ana'));
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Ana');

    await tester.enterText(find.byType(TextField), 'Vicenç');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Volver'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final returnedField = tester.widget<TextField>(find.byType(TextField));
    expect(returnedField.controller?.text, 'Vicenç');
  });

  testWidgets('small screen and text scaling keep the shell scrollable',
      (tester) async {
    await pumpScreen(
      tester,
      draft: _draft(firstName: 'Ana'),
      size: const Size(280, 420),
      textScaleFactor: 1.6,
    );
    await tester.scrollUntilVisible(
      find.text('Continuar donde lo dejé'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Goals renders exactly six localized options and disables CTA',
      (tester) async {
    await pumpScreen(tester, draft: _draft(firstName: 'Ana'));
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('¿Qué te gustaría mejorar?'), findsOneWidget);
    expect(find.text('Puedes elegir hasta 3 objetivos.'), findsOneWidget);
    for (final label in const [
      'Cuidar mi cuerpo',
      'Tener más calma',
      'Organizar mejor mis días',
      'Aprender y crecer',
      'Cuidar mis relaciones',
      'Crear más disciplina',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Continuar'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Goals supports selecting, deselecting and the maximum of 3',
      (tester) async {
    await pumpScreen(tester, draft: _draft(firstName: 'Ana'));
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final labels = [
      'Cuidar mi cuerpo',
      'Tener más calma',
      'Organizar mejor mis días',
      'Aprender y crecer',
    ];
    await tester.tap(find.text(labels[0]));
    await tester.pump();
    await tester.tap(find.text(labels[1]));
    await tester.pump();
    await tester.tap(find.text(labels[2]));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(find.bySemanticsLabel(labels[3]), findsOneWidget);
    final fourthSemantics =
        tester.getSemantics(find.bySemanticsLabel(labels[3]));
    expect(
      fourthSemantics.flagsCollection.isEnabled,
      ui.Tristate.isFalse,
    );

    await tester.tap(find.text(labels[0]));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(labels[3]))
          .flagsCollection
          .isEnabled,
      ui.Tristate.isTrue,
    );
  });

  testWidgets('Goals Continue persists selection and Back restores it',
      (tester) async {
    await pumpScreen(tester, draft: _draft(firstName: 'Ana'));
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Cuidar mi cuerpo'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ritmo'), findsWidgets);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Goals exposes English labels through l10n', (tester) async {
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      draft: _draft(firstName: 'Ana'),
    );
    await tester.tap(find.text('Continue where I left off'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('What would you like to improve?'), findsOneWidget);
    expect(find.text('Take care of my body'), findsOneWidget);
    expect(find.text('Build more discipline'), findsOneWidget);
  });

  testWidgets('Goals selection survives high text scaling on a small screen',
      (tester) async {
    await pumpScreen(
      tester,
      draft: _draft(firstName: 'Ana'),
      size: const Size(280, 420),
      textScaleFactor: 1.6,
    );
    await tester.scrollUntilVisible(
      find.text('Continuar donde lo dejé'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Goals persistence error keeps selection available for retry',
      (tester) async {
    final store = await pumpScreen(
      tester,
      draft: _draft(firstName: 'Ana'),
    );
    await tester.tap(find.text('Continuar donde lo dejé'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    store.failWrites = true;
    await tester.tap(find.text('Cuidar mi cuerpo'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
          'No hemos podido guardar este paso. Tu último estado sigue a salvo.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Ritmo'), findsNothing);

    store.failWrites = false;
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ritmo'), findsWidgets);
  });

  testWidgets('Pace renders three options and disables CTA initially',
      (tester) async {
    await pumpPace(tester);

    expect(find.text('¿Cómo quieres empezar?'), findsOneWidget);
    expect(find.text('Poco a poco'), findsOneWidget);
    expect(find.text('Quiero empezar con algo muy sencillo.'), findsOneWidget);
    expect(find.text('Equilibrado'), findsOneWidget);
    expect(find.text('Quiero avanzar sin exigirme demasiado.'), findsOneWidget);
    expect(find.text('Con energía'), findsOneWidget);
    expect(find.text('Estoy preparado para un reto mayor.'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Pace is single selection and changes its selected card',
      (tester) async {
    await pumpPace(tester);

    await tester.tap(find.text('Poco a poco'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Equilibrado'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Pace Continue persists and Back restores confirmed choice',
      (tester) async {
    await pumpPace(tester);

    await tester.tap(find.text('Con energía'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Recomendaciones'), findsWidgets);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Con energía'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Pace persistence error preserves local choice for retry',
      (tester) async {
    final store = await pumpPace(tester, failPaceWrites: true);

    await tester.tap(find.text('Poco a poco'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
          'No hemos podido guardar este paso. Tu último estado sigue a salvo.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Recomendaciones'), findsNothing);

    store.failWrites = false;
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Recomendaciones'), findsWidgets);
  });

  testWidgets('Pace exposes English labels and fits small scaled screens',
      (tester) async {
    await pumpPace(
      tester,
      locale: const Locale('en'),
      size: const Size(280, 420),
      textScaleFactor: 1.6,
    );

    expect(find.text('How would you like to start?'), findsOneWidget);
    expect(find.text('Little by little'), findsOneWidget);
    expect(find.text('I want to start with something very simple.'),
        findsOneWidget);
    expect(find.text('With energy'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recommendations renders cards, refresh and custom route',
      (tester) async {
    final store = await pumpPace(tester);
    await tester.tap(find.text('Equilibrado'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Un buen punto de partida'), findsOneWidget);
    expect(find.text('Hacer ejercicio'), findsOneWidget);
    expect(find.text('Ver otras opciones'), findsOneWidget);
    expect(find.text('Crear un hábito desde cero'), findsOneWidget);

    await tester.tap(find.text('Hacer ejercicio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.anonymous?.currentStep, OnboardingStep.habit);
    expect(
        store.anonymous?.selectedRecommendationId, 'onboarding_v1_move_body');
    expect(store.anonymous?.habit, isNull);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.text('Crear un hábito desde cero'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Crear un hábito desde cero'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.anonymous?.currentStep, OnboardingStep.habit);
    expect(store.anonymous?.selectedRecommendationId, isNull);
    expect(store.anonymous?.habit, isNull);
  });
}

OnboardingDraft _draft({String? firstName}) {
  return OnboardingDraft(
    draftId: '11111111-1111-4111-8111-111111111111',
    onboardingOperationId: '22222222-2222-4222-8222-222222222222',
    draftSchemaVersion: 1,
    onboardingVersion: 1,
    catalogVersion: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    currentStep: OnboardingStep.name,
    firstName: firstName,
  );
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
