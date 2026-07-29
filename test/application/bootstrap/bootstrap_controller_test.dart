import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/application/auth/auth_controller.dart';
import 'package:rutio/application/bootstrap/bootstrap_controller.dart';
import 'package:rutio/data/local/authoritative_bootstrap_cache_v2.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/data/repositories/profile_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/app_startup_gate.dart';
import 'package:rutio/screens/splash_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BootstrapController', () {
    test('unresolved session keeps bootstrap in preparation', () async {
      final fixture = _Fixture();
      await fixture.pump();

      expect(
        fixture.bootstrap.state.phase,
        BootstrapPhase.resolvingSession,
      );
      expect(fixture.profile.authoritativeLoadCalls, 0);
    });

    test('resolved guest routes to Welcome when local onboarding is not done',
        () async {
      final fixture = _Fixture(localOnboardingDone: false);
      fixture.resolveGuest();
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.welcome);
    });

    test('resolved guest routes to Auth when local onboarding is done',
        () async {
      final fixture = _Fixture(localOnboardingDone: true);
      fixture.resolveGuest();
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.authentication,
      );
    });

    test('authenticated pending profile routes to onboarding', () async {
      final fixture = _Fixture(profileStatus: OnboardingStatus.pending);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.onboarding,
      );
    });

    test('authenticated in_progress profile routes to onboarding', () async {
      final fixture = _Fixture(profileStatus: OnboardingStatus.inProgress);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.onboarding,
      );
    });

    test('authenticated completed profile routes to home', () async {
      final fixture = _Fixture(profileStatus: OnboardingStatus.completed);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('authoritative suspended profile routes to suspended screen',
        () async {
      final fixture = _Fixture(
        authoritativeDecision: AuthoritativeBootstrapDecision(
          userId: 'user-1',
          decision: AuthoritativeBootstrapDestination.accountSuspended,
          accountStatus: BootstrapAccountStatus.suspended,
          profileState: BootstrapProfileState.ready,
          onboardingStatus: null,
          completedOnboardingVersion: null,
          requiredOnboardingVersion: 1,
          onboardingEnforcement: BootstrapOnboardingEnforcement.advisory,
          onboardingCompletedAt: null,
          profileRevision: 3,
          policyRevision: 2,
        ),
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.accountSuspended,
      );
      expect(fixture.bootstrap.state.remoteProfile, isNull);
    });

    test('home is published before post-home work completes', () async {
      final postHomeCompleter = Completer<void>();
      BootstrapDestination? destinationAtPostHomeStart;
      late _Fixture fixture;
      fixture = _Fixture(
        profileStatus: OnboardingStatus.completed,
        enableBackgroundProfileSync: true,
        postHomeBootstrapTaskRunner: (_) async {
          destinationAtPostHomeStart = fixture.bootstrap.state.destination;
          await postHomeCompleter.future;
        },
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(destinationAtPostHomeStart, BootstrapDestination.home);

      postHomeCompleter.complete();
      await fixture.pump();
    });

    test('onboarding destination does not start post-home work', () async {
      var postHomeCalls = 0;
      final fixture = _Fixture(
        profileStatus: OnboardingStatus.pending,
        enableBackgroundProfileSync: true,
        postHomeBootstrapTaskRunner: (_) async {
          postHomeCalls += 1;
        },
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.onboarding,
      );
      expect(postHomeCalls, 0);
    });

    test('post-home errors do not move Home to failed', () async {
      final fixture = _Fixture(
        profileStatus: OnboardingStatus.completed,
        enableBackgroundProfileSync: true,
        postHomeBootstrapTaskRunner: (_) async {
          throw StateError('post-home failed');
        },
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.ready);
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(fixture.bootstrap.state.error, isNull);
    });

    test('completed account never emits onboarding while profile is loading',
        () async {
      final slow = Completer<BootstrapProfileDecisionLoadResult>();
      final fixture = _Fixture(profileCompleter: slow);
      final destinations = <BootstrapDestination?>[];
      fixture.bootstrap.addListener(() {
        destinations.add(fixture.bootstrap.state.destination);
      });

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
          fixture.bootstrap.state.phase, BootstrapPhase.loadingRemoteProfile);
      expect(fixture.bootstrap.state.destination, isNull);
      expect(destinations, isNot(contains(BootstrapDestination.onboarding)));

      slow.complete(_decisionResult('user-1', OnboardingStatus.completed));
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(destinations, isNot(contains(BootstrapDestination.onboarding)));
    });

    test('pending remote profile keeps preparation until fetch resolves',
        () async {
      final slow = Completer<BootstrapProfileDecisionLoadResult>();
      final fixture = _Fixture(profileCompleter: slow);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
          fixture.bootstrap.state.phase, BootstrapPhase.loadingRemoteProfile);
      expect(fixture.bootstrap.state.destination, isNull);

      slow.complete(_decisionResult('user-1', OnboardingStatus.pending));
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.onboarding,
      );
    });

    test('local onboardingDone does not decide authenticated route', () async {
      final fixture = _Fixture(
        localOnboardingDone: true,
        profileStatus: OnboardingStatus.pending,
      );
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.onboarding,
      );
    });

    test('missing profile fails closed', () async {
      final fixture = _Fixture(profileResult: _ProfileResult.missing);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);
      expect(fixture.bootstrap.state.destination, isNull);
      expect(
        fixture.bootstrap.state.error?.type,
        BootstrapErrorType.invalidRemoteResponse,
      );
    });

    test('network error is recoverable', () async {
      final fixture = _Fixture(profileResult: _ProfileResult.network);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);
      expect(fixture.bootstrap.state.error?.type, BootstrapErrorType.network);
      expect(fixture.bootstrap.state.error?.canRetry, isTrue);
    });

    test('retry starts only a new current run', () async {
      final fixture = _Fixture(profileResult: _ProfileResult.network);
      fixture.resolveUser('user-1');
      await fixture.pump();
      final failedRun = fixture.bootstrap.state.runId;

      fixture.profile.result = _ProfileResult.completed;
      await fixture.bootstrap.retry();

      expect(fixture.bootstrap.state.runId, greaterThan(failedRun));
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(fixture.profile.authoritativeLoadCalls, 2);
    });

    test('user change discards previous profile result', () async {
      final slow = Completer<BootstrapProfileDecisionLoadResult>();
      final fixture = _Fixture(profileCompleter: slow);
      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.profile.completer = null;
      fixture.profile.result = _ProfileResult.completed;
      fixture.resolveUser('user-2');
      await fixture.pump();
      slow.complete(_decisionResult('user-1', OnboardingStatus.completed));
      await fixture.pump();

      expect(fixture.bootstrap.state.user?.id, 'user-2');
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('stale pending profile does not affect completed user', () async {
      final slow = Completer<BootstrapProfileDecisionLoadResult>();
      final fixture = _Fixture(profileCompleter: slow);
      final destinations = <BootstrapDestination?>[];
      fixture.bootstrap.addListener(() {
        destinations.add(fixture.bootstrap.state.destination);
      });

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.profile.completer = null;
      fixture.profile.result = _ProfileResult.completed;
      fixture.resolveUser('user-2');
      await fixture.pump();
      slow.complete(_decisionResult('user-1', OnboardingStatus.pending));
      await fixture.pump();

      expect(fixture.bootstrap.state.user?.id, 'user-2');
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(destinations, isNot(contains(BootstrapDestination.onboarding)));
    });

    test('login after guest decision creates a new run', () async {
      final fixture = _Fixture(localOnboardingDone: true);
      fixture.resolveGuest();
      await fixture.pump();
      final guestRun = fixture.bootstrap.state.runId;
      expect(
        fixture.bootstrap.state.destination,
        BootstrapDestination.authentication,
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.runId, greaterThan(guestRun));
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('logout invalidates a prepared home bootstrap', () async {
      final fixture = _Fixture(profileStatus: OnboardingStatus.completed);
      fixture.resolveUser('user-1');
      await fixture.pump();
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);

      fixture.resolveGuest();
      await fixture.pump();

      expect(fixture.bootstrap.state.user, isNull);
      expect(fixture.bootstrap.state.destination,
          isNot(BootstrapDestination.home));
    });

    test('logout during profile load discards home', () async {
      final slow = Completer<BootstrapProfileDecisionLoadResult>();
      final fixture = _Fixture(profileCompleter: slow);
      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.resolveGuest();
      await fixture.pump();
      slow.complete(_decisionResult('user-1', OnboardingStatus.completed));
      await fixture.pump();

      expect(fixture.bootstrap.state.user, isNull);
      expect(
        fixture.bootstrap.state.destination,
        anyOf(
            BootstrapDestination.welcome, BootstrapDestination.authentication),
      );
    });

    test('temporary onboarding completion routes to home', () async {
      final fixture = _Fixture(profileStatus: OnboardingStatus.pending);
      fixture.resolveUser('user-1');
      await fixture.pump();

      await fixture.bootstrap.completeTemporaryOnboarding();

      expect(fixture.profile.completeCalls, 1);
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('destination=home waits for habits and cosmetics', () async {
      final habitsCompleter = Completer<EssentialHabitsBootstrapResult>();
      final cosmeticsCompleter = Completer<CosmeticsBootstrapResult>();
      final habits = _FakeEssentialHabitsPreparer(completer: habitsCompleter);
      final cosmetics =
          _FakeEssentialCosmeticsPreparer(completer: cosmeticsCompleter);
      final fixture = _Fixture(
        profileStatus: OnboardingStatus.completed,
        habitsPreparer: habits,
        cosmeticsPreparer: cosmetics,
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(habits.calls, 1);
      expect(cosmetics.calls, 1);
      expect(fixture.bootstrap.state.destination, isNull);
      expect(
        fixture.bootstrap.state.phase,
        BootstrapPhase.loadingEssentialCosmetics,
      );

      habitsCompleter.complete(_habitsReady('user-1'));
      await fixture.pump();
      expect(fixture.bootstrap.state.destination, isNull);

      cosmeticsCompleter.complete(_cosmeticsReady('user-1'));
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('independent habits and cosmetics run in parallel', () async {
      final habitsCompleter = Completer<EssentialHabitsBootstrapResult>();
      final cosmeticsCompleter = Completer<CosmeticsBootstrapResult>();
      final habits = _FakeEssentialHabitsPreparer(completer: habitsCompleter);
      final cosmetics =
          _FakeEssentialCosmeticsPreparer(completer: cosmeticsCompleter);
      final fixture = _Fixture(
        habitsPreparer: habits,
        cosmeticsPreparer: cosmetics,
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(habits.calls, 1);
      expect(cosmetics.calls, 1);
      expect(cosmetics.startedAt, isNotNull);
      expect(habitsCompleter.isCompleted, isFalse);

      habitsCompleter.complete(_habitsReady('user-1'));
      cosmeticsCompleter.complete(_cosmeticsReady('user-1'));
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('essential failure produces failed bootstrap', () async {
      final fixture = _Fixture(
        habitsPreparer: _FakeEssentialHabitsPreparer(
          status: EssentialHabitsBootstrapStatus.failed,
        ),
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);
      expect(
        fixture.bootstrap.state.error?.type,
        BootstrapErrorType.essentialHabits,
      );
      expect(fixture.bootstrap.state.destination, isNull);
    });

    test('essential cosmetics failure produces failed bootstrap', () async {
      final fixture = _Fixture(
        cosmeticsPreparer: _FakeEssentialCosmeticsPreparer(
          status: CosmeticsBootstrapStatus.failed,
        ),
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);
      expect(
        fixture.bootstrap.state.error?.type,
        BootstrapErrorType.essentialCosmetics,
      );
      expect(fixture.bootstrap.state.destination, isNull);
    });

    test('does not publish home before cosmetics resolvers are verified',
        () async {
      final fixture = _Fixture(
        cosmeticsPreparer: _FakeEssentialCosmeticsPreparer(
          resolversVerified: false,
        ),
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);
      expect(
        fixture.bootstrap.state.error?.type,
        BootstrapErrorType.essentialCosmetics,
      );
      expect(fixture.bootstrap.state.destination, isNull);
    });

    test('cosmetics result records an applied revision before home', () async {
      final cosmetics = _FakeEssentialCosmeticsPreparer(appliedRevision: 7);
      final fixture = _Fixture(cosmeticsPreparer: cosmetics);

      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(cosmetics.lastResult?.appliedRevision, 7);
      expect(cosmetics.lastResult?.resolversVerified, isTrue);
    });

    test('retry after essential failure creates a new run', () async {
      final habits = _FakeEssentialHabitsPreparer(
        status: EssentialHabitsBootstrapStatus.failed,
      );
      final fixture = _Fixture(habitsPreparer: habits);
      fixture.resolveUser('user-1');
      await fixture.pump();
      final failedRun = fixture.bootstrap.state.runId;

      habits.status = EssentialHabitsBootstrapStatus.readyFromRemote;
      await fixture.bootstrap.retry();

      expect(fixture.bootstrap.state.runId, greaterThan(failedRun));
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(habits.calls, 2);
    });

    test('double Continue calls perform one remote completion', () async {
      final fixture = _Fixture(profileStatus: OnboardingStatus.pending);
      fixture.resolveUser('user-1');
      await fixture.pump();
      final completer = Completer<RepositoryResult<RemoteProfile>>();
      fixture.profile.completeCompleter = completer;

      final first = fixture.bootstrap.completeTemporaryOnboarding();
      final second = fixture.bootstrap.completeTemporaryOnboarding();

      expect(fixture.profile.completeCalls, 1);
      completer.complete(
        RepositoryResult<RemoteProfile>.success(
          data: _profile('user-1', OnboardingStatus.completed),
        ),
      );
      await Future.wait(<Future<void>>[first, second]);
    });

    testWidgets('cold start /home keeps Splash before Home is ready',
        (tester) async {
      final fixture = _Fixture();

      await tester.pumpWidget(
        _localizedApp(
          routes: {
            '/home': (_) => ChangeNotifierProvider<BootstrapController>.value(
                  value: fixture.bootstrap,
                  child: const AppStartupGate(
                    authenticatedBuilder: _homeBuilder,
                  ),
                ),
          },
          initialRoute: '/home',
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('Home waits for cosmetics and appears without generic frame',
        (tester) async {
      final habitsCompleter = Completer<EssentialHabitsBootstrapResult>();
      final cosmeticsCompleter = Completer<CosmeticsBootstrapResult>();
      final habits = _FakeEssentialHabitsPreparer(completer: habitsCompleter);
      final cosmetics =
          _FakeEssentialCosmeticsPreparer(completer: cosmeticsCompleter);
      final fixture = _Fixture(
        habitsPreparer: habits,
        cosmeticsPreparer: cosmetics,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<BootstrapController>.value(
          value: fixture.bootstrap,
          child: _localizedApp(
            home: AppStartupGate(
              authenticatedBuilder: _personalizedHomeBuilder,
            ),
          ),
        ),
      );
      fixture.resolveUser('user-1');
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Generic Home'), findsNothing);
      expect(find.text('Personalized Home'), findsNothing);

      habitsCompleter.complete(_habitsReady('user-1'));
      await tester.pump();

      expect(habits.calls, 1);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Generic Home'), findsNothing);
      expect(find.text('Personalized Home'), findsNothing);

      cosmeticsCompleter.complete(_cosmeticsReady('user-1'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Generic Home'), findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Personalized Home'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1999));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Personalized Home'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Personalized Home'), findsOneWidget);
    });

    testWidgets(
        'restored cold start ignores redundant initialSession before first Home',
        (tester) async {
      final habitsCompleter = Completer<EssentialHabitsBootstrapResult>();
      final cosmeticsCompleter = Completer<CosmeticsBootstrapResult>();
      final habits = _FakeEssentialHabitsPreparer(completer: habitsCompleter);
      final cosmetics =
          _FakeEssentialCosmeticsPreparer(completer: cosmeticsCompleter);
      final fixture = _Fixture(
        restoredUserId: 'user-1',
        habitsPreparer: habits,
        cosmeticsPreparer: cosmetics,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<BootstrapController>.value(
          value: fixture.bootstrap,
          child: _localizedApp(
            home: AppStartupGate(
              authenticatedBuilder: _personalizedHomeBuilder,
            ),
          ),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      fixture.resolveUser('user-1');
      await tester.pump();

      expect(fixture.bootstrap.state.mode, BootstrapRunMode.coldStart);
      expect(find.byType(SplashScreen), findsOneWidget);

      habitsCompleter.complete(_habitsReady('user-1'));
      cosmeticsCompleter.complete(_cosmeticsReady('user-1'));
      await tester.pump();

      final runIdBeforeRedundantEvent = fixture.bootstrap.state.runId;
      fixture.resolveUser('user-1');
      await tester.pump();
      await tester.pump();

      expect(fixture.bootstrap.state.runId, runIdBeforeRedundantEvent);
      expect(cosmetics.calls, 1);
      expect(fixture.bootstrap.state.cosmeticsReadyToken?.appliedRevision, 1);
      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Generic Home'), findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Personalized Home'), findsNothing);

      await tester.pump(const Duration(milliseconds: 2000));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Personalized Home'), findsOneWidget);
    });

    testWidgets('manual login shows preparing while cosmetics are pending',
        (tester) async {
      final cosmeticsCompleter = Completer<CosmeticsBootstrapResult>();
      final cosmetics =
          _FakeEssentialCosmeticsPreparer(completer: cosmeticsCompleter);
      final fixture = _Fixture(
        profileResult: _ProfileResult.network,
        cosmeticsPreparer: cosmetics,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<BootstrapController>.value(
          value: fixture.bootstrap,
          child: _localizedApp(
            home: AppStartupGate(
              authenticatedBuilder: _personalizedHomeBuilder,
            ),
          ),
        ),
      );
      fixture.resolveUser('user-1');
      await tester.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);

      fixture.profile.result = _ProfileResult.completed;
      unawaited(fixture.bootstrap.retry());
      await tester.pump();

      expect(fixture.bootstrap.state.mode, BootstrapRunMode.inAppBootstrap);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.textContaining('Preparando tu espacio'), findsOneWidget);
      expect(find.text('Personalized Home'), findsNothing);

      cosmeticsCompleter.complete(_cosmeticsReady('user-1'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Personalized Home'), findsOneWidget);
    });

    testWidgets('direct /shop waits for essential bootstrap before content',
        (tester) async {
      final habitsCompleter = Completer<EssentialHabitsBootstrapResult>();
      final cosmeticsCompleter = Completer<CosmeticsBootstrapResult>();
      final habits = _FakeEssentialHabitsPreparer(completer: habitsCompleter);
      final cosmetics =
          _FakeEssentialCosmeticsPreparer(completer: cosmeticsCompleter);
      final fixture = _Fixture(
        habitsPreparer: habits,
        cosmeticsPreparer: cosmetics,
      );

      await tester.pumpWidget(
        _localizedApp(
          routes: {
            '/shop': (_) => ChangeNotifierProvider<BootstrapController>.value(
                  value: fixture.bootstrap,
                  child: const AppStartupGate(
                    authenticatedBuilder: _shopBuilder,
                  ),
                ),
          },
          initialRoute: '/shop',
        ),
      );
      fixture.resolveUser('user-1');
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Shop'), findsNothing);

      habitsCompleter.complete(_habitsReady('user-1'));
      cosmeticsCompleter.complete(_cosmeticsReady('user-1'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Preparando tu espacio'), findsNothing);
      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('special authoritative destinations render a dedicated screen',
        (tester) async {
      const cases = <BootstrapDestination, String>{
        BootstrapDestination.profileUninitialized: 'Perfil no inicializado',
        BootstrapDestination.profileDeleted: 'Perfil eliminado',
        BootstrapDestination.accountSuspended: 'Cuenta suspendida',
        BootstrapDestination.accountPendingDeletion: 'Cuenta en borrado',
        BootstrapDestination.invalidProfile: 'Perfil incoherente',
      };

      for (final entry in cases.entries) {
        await tester.pumpWidget(
          _localizedApp(
            home: BootstrapAuthorityStateScreen(destination: entry.key),
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(BootstrapAuthorityStateScreen), findsOneWidget);
      }
    });

    testWidgets('special destinations expose the expected actions',
        (tester) async {
      final cases = <BootstrapDestination, List<String>>{
        BootstrapDestination.accountSuspended: <String>['Cerrar sesion'],
        BootstrapDestination.accountPendingDeletion: <String>['Cerrar sesion'],
        BootstrapDestination.profileDeleted: <String>['Cerrar sesion'],
        BootstrapDestination.profileUninitialized: <String>[
          'Reintentar',
          'Cerrar sesion',
        ],
        BootstrapDestination.invalidProfile: <String>[
          'Reintentar',
          'Cerrar sesion',
        ],
      };

      for (final entry in cases.entries) {
        final fixture = _Fixture();
        await tester.pumpWidget(
          _authorityApp(
            fixture.bootstrap,
            fixture.auth,
            BootstrapAuthorityStateScreen(destination: entry.key),
          ),
        );

        expect(find.text(_authorityTitle(entry.key)), findsOneWidget);
        expect(find.text('Home'), findsNothing);
        expect(find.text('Reintentar'),
            entry.value.contains('Reintentar') ? findsOneWidget : findsNothing);
        expect(find.text('Cerrar sesion'), findsOneWidget);
      }
    });

    testWidgets('logout uses the real auth flow exactly once', (tester) async {
      final harness = _AuthorityHarness(
        initialDestination: BootstrapDestination.accountSuspended,
        loggedOutDestination: BootstrapDestination.welcome,
      );
      harness.auth.signOutCompleter = Completer<void>();

      await tester.pumpWidget(
        _authorityApp(
          harness.bootstrap,
          harness.auth,
          const BootstrapAuthorityStateScreen(
            destination: BootstrapDestination.accountSuspended,
          ),
        ),
      );

      final logoutButton = find.byType(CupertinoButton);
      await tester.tap(logoutButton);
      await tester.pump();
      await tester.tap(logoutButton);
      await tester.pump();

      expect(harness.auth.signOutCalls, 1);

      harness.auth.signOutCompleter!.complete();
      await tester.pump();
      await tester.pump();

      expect(harness.bootstrap.state.destination, BootstrapDestination.welcome);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('retry starts one new run and blocks double taps',
        (tester) async {
      final harness = _AuthorityHarness(
        initialDestination: BootstrapDestination.profileUninitialized,
      );
      harness.bootstrap.retryCompleter = Completer<void>();

      await tester.pumpWidget(
        _authorityApp(
          harness.bootstrap,
          harness.auth,
          const BootstrapAuthorityStateScreen(
            destination: BootstrapDestination.profileUninitialized,
          ),
        ),
      );

      final buttons = find.byType(CupertinoButton);
      await tester.tap(buttons.first);
      await tester.tap(buttons.first);
      await tester.pump();

      expect(harness.bootstrap.retryCalls, 1);
      expect(
          harness.bootstrap.state.phase, BootstrapPhase.loadingRemoteProfile);
      expect(
        harness.bootstrap.state.mode,
        BootstrapRunMode.inAppBootstrap,
      );

      harness.bootstrap.retryCompleter!.complete();
      await tester.pump();
      await tester.pump();

      expect(harness.bootstrap.state.destination, BootstrapDestination.home);
      expect(harness.bootstrap.state.runId, greaterThan(1));
    });
  });
}

Widget _localizedApp({
  Widget? home,
  Map<String, WidgetBuilder>? routes,
  String? initialRoute,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
    routes: routes ?? const <String, WidgetBuilder>{},
    initialRoute: initialRoute,
  );
}

Widget _homeBuilder(BuildContext context) => const Text('Home');

Widget _personalizedHomeBuilder(BuildContext context) =>
    const Text('Personalized Home');

Widget _shopBuilder(BuildContext context) => const Text('Shop');

Widget _authorityApp(
  BootstrapController bootstrap,
  AuthController auth,
  Widget child,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<BootstrapController>.value(value: bootstrap),
    ],
    child: _localizedApp(home: child),
  );
}

String _authorityTitle(BootstrapDestination destination) {
  switch (destination) {
    case BootstrapDestination.profileUninitialized:
      return 'Perfil no inicializado';
    case BootstrapDestination.profileDeleted:
      return 'Perfil eliminado';
    case BootstrapDestination.accountSuspended:
      return 'Cuenta suspendida';
    case BootstrapDestination.accountPendingDeletion:
      return 'Cuenta en borrado';
    case BootstrapDestination.invalidProfile:
      return 'Perfil incoherente';
    case BootstrapDestination.welcome:
    case BootstrapDestination.authentication:
    case BootstrapDestination.onboarding:
    case BootstrapDestination.home:
      return 'Estado no aplicable';
  }
}

class _AuthorityHarness {
  _AuthorityHarness({
    required this.initialDestination,
    this.loggedOutDestination = BootstrapDestination.welcome,
  }) {
    auth = _FakeAuthorityAuthController();
    bootstrap = _FakeAuthorityBootstrapController(
      initialDestination: initialDestination,
      loggedOutDestination: loggedOutDestination,
      authController: auth,
    );
    auth.onSignedOut = () => bootstrap.markLoggedOut();
  }

  final BootstrapDestination initialDestination;
  final BootstrapDestination loggedOutDestination;
  late final _FakeAuthorityAuthController auth;
  late final _FakeAuthorityBootstrapController bootstrap;
}

class _FakeAuthorityAuthController extends AuthController {
  _FakeAuthorityAuthController()
      : super(
          AuthRepository(
            authStateChangesProvider: () => const Stream<AuthState>.empty(),
            currentUserProvider: () => null,
          ),
          userStateStore: _FakeUserStateStore(localOnboardingDone: false),
          globalWalletController: _FakeGlobalWalletController(),
          profileRepository: null,
          enableBackgroundProfileSync: false,
        );

  Completer<void>? signOutCompleter;
  int signOutCalls = 0;
  VoidCallback? onSignedOut;
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    final pending = signOutCompleter;
    if (pending != null) {
      await pending.future;
    }
    _currentUser = null;
    onSignedOut?.call();
  }
}

class _FakeAuthorityBootstrapController extends BootstrapController {
  _FakeAuthorityBootstrapController({
    required BootstrapDestination initialDestination,
    required this.loggedOutDestination,
    required super.authController,
  })  : _state = BootstrapState(
          phase: BootstrapPhase.ready,
          runId: 1,
          mode: BootstrapRunMode.coldStart,
          destination: initialDestination,
        ),
      super(
          userStateStore: _FakeUserStateStore(localOnboardingDone: false),
          profileRepository: _NoopAuthorityBootstrapProfileRepository(),
          authoritativeBootstrapCache: InMemoryAuthoritativeBootstrapCacheV2(),
          authoritativeBootstrapEnvironmentId: 'test-supabase-url',
          essentialHabitsPreparer: _FakeEssentialHabitsPreparer(),
          essentialCosmeticsPreparer: const NoopBootstrapCosmeticsPreparer(),
          essentialAssetPreloader: _FakeEssentialAssetPreloader(),
        );

  final BootstrapDestination loggedOutDestination;
  BootstrapState _state;
  Completer<void>? retryCompleter;
  int retryCalls = 0;

  @override
  BootstrapState get state => _state;

  @override
  Future<void> start() async {}

  @override
  Future<void> retry() async {
    retryCalls += 1;
    _state = _state.copyWith(
      runId: _state.runId + 1,
      mode: BootstrapRunMode.inAppBootstrap,
      phase: BootstrapPhase.loadingRemoteProfile,
      clearDestination: true,
      clearError: true,
      clearRemoteProfile: true,
    );
    notifyListeners();

    final pending = retryCompleter;
    if (pending != null) {
      await pending.future;
    }

    _state = _state.copyWith(
      phase: BootstrapPhase.ready,
      destination: BootstrapDestination.home,
    );
    notifyListeners();
  }

  void markLoggedOut() {
    _state = _state.copyWith(
      runId: _state.runId + 1,
      mode: BootstrapRunMode.inAppBootstrap,
      phase: BootstrapPhase.ready,
      destination: loggedOutDestination,
      clearError: true,
      clearRemoteProfile: true,
      clearCosmeticsReadyToken: true,
    );
    notifyListeners();
  }
}

class _NoopAuthorityBootstrapProfileRepository
    implements BootstrapProfileRepository {
  @override
  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) async {
    return const AuthoritativeBootstrapDecisionLoadResult(
      decision: null,
      error: AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
        message: 'noop',
      ),
      totalDuration: Duration.zero,
      inflightWaitDuration: Duration.zero,
      remoteQueryDuration: Duration.zero,
      mapDuration: Duration.zero,
      remoteCallCount: 0,
      payloadColumnCount: 0,
    );
  }

  @override
  Future<BootstrapProfileDecisionLoadResult> fetchBootstrapProfileDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) async {
    return const BootstrapProfileDecisionLoadResult(
      result: RepositoryResult<BootstrapProfileDecision?>.success(data: null),
      totalDuration: Duration.zero,
      inflightWaitDuration: Duration.zero,
      remoteQueryDuration: Duration.zero,
      mapDuration: Duration.zero,
      remoteCallCount: 0,
      payloadColumnCount: 0,
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  }) async {
    return const RepositoryResult<RemoteProfile>.failure(
      RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'noop',
      ),
    );
  }

  @override
  Future<void> storeBootstrapProfileDecisionFromRemoteProfileInMemory({
    required RemoteProfile profile,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    String? expectedUserId,
  }) async {}
}

BootstrapProfileDecisionLoadResult _decisionResult(
  String userId,
  OnboardingStatus status,
) {
  return BootstrapProfileDecisionLoadResult(
    result: RepositoryResult<BootstrapProfileDecision?>.success(
      data: BootstrapProfileDecision(
        userId: userId,
        onboardingStatus: status,
        onboardingVersion: 1,
        onboardingCompletedAt: status == OnboardingStatus.completed
            ? DateTime.utc(2026, 7, 28)
            : null,
      ),
    ),
    totalDuration: Duration.zero,
    inflightWaitDuration: Duration.zero,
    remoteQueryDuration: Duration.zero,
    mapDuration: Duration.zero,
    remoteCallCount: 1,
    payloadColumnCount: 4,
  );
}

EssentialHabitsBootstrapResult _habitsReady(String userId) {
  return EssentialHabitsBootstrapResult(
    status: EssentialHabitsBootstrapStatus.readyFromRemote,
    userId: userId,
    source: 'remote',
    scopeEpoch: 1,
    requestId: 1,
    duration: Duration.zero,
  );
}

CosmeticsBootstrapResult _cosmeticsReady(String userId) {
  return CosmeticsBootstrapResult(
    status: CosmeticsBootstrapStatus.readyFromRemote,
    userId: userId,
    source: 'remote',
    requestId: 1,
    duration: Duration.zero,
  );
}

class _Fixture {
  _Fixture({
    String? restoredUserId,
    bool localOnboardingDone = false,
    OnboardingStatus profileStatus = OnboardingStatus.completed,
    AuthoritativeBootstrapDecision? authoritativeDecision,
    _ProfileResult profileResult = _ProfileResult.fromStatus,
    Completer<BootstrapProfileDecisionLoadResult>? profileCompleter,
    _FakeEssentialHabitsPreparer? habitsPreparer,
    _FakeEssentialCosmeticsPreparer? cosmeticsPreparer,
    _FakeEssentialAssetPreloader? assetPreloader,
    bool enableBackgroundProfileSync = false,
    PostHomeBootstrapTaskRunner? postHomeBootstrapTaskRunner,
    Completer<void>? signOutCompleter,
  })  : authStream = StreamController<AuthState>.broadcast(sync: true),
        userStore = _FakeUserStateStore(
          localOnboardingDone: localOnboardingDone,
        ),
        wallet = _FakeGlobalWalletController(),
        profile = _FakeProfileRepository(
          status: profileStatus,
          authoritativeDecision: authoritativeDecision,
          result: profileResult,
          completer: profileCompleter,
        ) {
    authRepository = _FakeAuthRepository(
      authStateChangesProvider: () => authStream.stream,
      currentUserProvider: () => currentUser,
      signOutCompleter: signOutCompleter,
    );
    if (restoredUserId != null) {
      currentUser = _user(restoredUserId);
      profile.currentFetchUserId = restoredUserId;
    }
    auth = AuthController(
      authRepository,
      userStateStore: userStore,
      globalWalletController: wallet,
      profileRepository: null,
      enableBackgroundProfileSync: enableBackgroundProfileSync,
      postHomeBootstrapTaskRunner: postHomeBootstrapTaskRunner,
    );
    bootstrap = BootstrapController(
      authController: auth,
      userStateStore: userStore,
      profileRepository: profile,
      authoritativeBootstrapCache: InMemoryAuthoritativeBootstrapCacheV2(),
      authoritativeBootstrapEnvironmentId: 'test-supabase-url',
      essentialHabitsPreparer: habitsPreparer ?? _FakeEssentialHabitsPreparer(),
      essentialCosmeticsPreparer:
          cosmeticsPreparer ?? _FakeEssentialCosmeticsPreparer(),
      essentialAssetPreloader: assetPreloader ?? _FakeEssentialAssetPreloader(),
    );
    addTearDown(() async {
      bootstrap.dispose();
      auth.dispose();
      await authStream.close();
    });
  }

  final StreamController<AuthState> authStream;
  final _FakeUserStateStore userStore;
  final _FakeGlobalWalletController wallet;
  late final _FakeAuthRepository authRepository;
  final _FakeProfileRepository profile;
  late final AuthController auth;
  late final BootstrapController bootstrap;
  User? currentUser;

  void resolveGuest() {
    currentUser = null;
    authStream.add(AuthState(AuthChangeEvent.initialSession, null));
  }

  void resolveUser(String id) {
    currentUser = _user(id);
    profile.currentFetchUserId = id;
    authStream.add(
      AuthState(AuthChangeEvent.initialSession, _session(_user(id))),
    );
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  int get signOutCalls => authRepository.signOutCalls;
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    required super.authStateChangesProvider,
    required super.currentUserProvider,
    this.signOutCompleter,
  });

  final Completer<void>? signOutCompleter;
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    final pending = signOutCompleter;
    if (pending != null) {
      await pending.future;
    }
  }
}

enum _ProfileResult {
  fromStatus,
  completed,
  missing,
  network,
}

class _FakeProfileRepository implements BootstrapProfileRepository {
  _FakeProfileRepository({
    required this.status,
    required this.result,
    this.completer,
    this.authoritativeDecision,
  });

  OnboardingStatus status;
  _ProfileResult result;
  Completer<BootstrapProfileDecisionLoadResult>? completer;
  Completer<RepositoryResult<RemoteProfile>>? completeCompleter;
  AuthoritativeBootstrapDecision? authoritativeDecision;
  int fetchCalls = 0;
  int authoritativeLoadCalls = 0;
  int completeCalls = 0;

  String currentFetchUserId = 'user-1';

  @override
  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) {
    authoritativeLoadCalls += 1;
    final pending = completer;
    if (pending != null) {
      return pending.future.then(_authoritativeFromBootstrapResult);
    }
    final explicit = authoritativeDecision;
    if (explicit != null) {
      return Future.value(
        _authoritativeResultFromDecision(
          explicit,
        ),
      );
    }
    switch (result) {
      case _ProfileResult.fromStatus:
        return Future.value(
          _authoritativeResult(
            decision: _authoritativeDecisionForStatus(status),
            userId: currentFetchUserId,
          ),
        );
      case _ProfileResult.completed:
        return Future.value(
          _authoritativeResult(
            decision: AuthoritativeBootstrapDestination.home,
            userId: currentFetchUserId,
          ),
        );
      case _ProfileResult.missing:
        return Future.value(
          const AuthoritativeBootstrapDecisionLoadResult(
            decision: null,
            error: AuthoritativeBootstrapDecisionReadException(
              code: AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
              message: 'empty',
            ),
            totalDuration: Duration.zero,
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: Duration.zero,
            mapDuration: Duration.zero,
            remoteCallCount: 1,
            payloadColumnCount: 11,
          ),
        );
      case _ProfileResult.network:
        return Future.value(
          const AuthoritativeBootstrapDecisionLoadResult(
            decision: null,
            error: AuthoritativeBootstrapDecisionReadException(
              code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
              message: 'network',
            ),
            totalDuration: Duration.zero,
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: Duration.zero,
            mapDuration: Duration.zero,
            remoteCallCount: 1,
            payloadColumnCount: 11,
          ),
        );
    }
  }

  @override
  Future<BootstrapProfileDecisionLoadResult> fetchBootstrapProfileDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) {
    fetchCalls += 1;
    final pending = completer;
    if (pending != null) return pending.future;
    switch (result) {
      case _ProfileResult.fromStatus:
        return Future.value(_decisionResult(currentFetchUserId, status));
      case _ProfileResult.completed:
        return Future.value(
          _decisionResult(currentFetchUserId, OnboardingStatus.completed),
        );
      case _ProfileResult.missing:
        return Future.value(
          const BootstrapProfileDecisionLoadResult(
            result: RepositoryResult<BootstrapProfileDecision?>.success(
              data: null,
            ),
            totalDuration: Duration.zero,
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: Duration.zero,
            mapDuration: Duration.zero,
            remoteCallCount: 1,
            payloadColumnCount: 4,
          ),
        );
      case _ProfileResult.network:
        return Future.value(
          const BootstrapProfileDecisionLoadResult(
            result: RepositoryResult<BootstrapProfileDecision?>.failure(
              RepositoryError(
                code: RepositoryErrorCode.network,
                message: 'network',
              ),
            ),
            totalDuration: Duration.zero,
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: Duration.zero,
            mapDuration: Duration.zero,
            remoteCallCount: 1,
            payloadColumnCount: 4,
          ),
        );
    }
  }

  @override
  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  }) {
    completeCalls += 1;
    final pending = completeCompleter;
    if (pending != null) return pending.future;
    return Future.value(
      RepositoryResult<RemoteProfile>.success(
        data: _profile(currentFetchUserId, OnboardingStatus.completed),
      ),
    );
  }

  @override
  Future<void> storeBootstrapProfileDecisionFromRemoteProfileInMemory({
    required RemoteProfile profile,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    String? expectedUserId,
  }) async {}

  AuthoritativeBootstrapDecisionLoadResult _authoritativeFromBootstrapResult(
    BootstrapProfileDecisionLoadResult result,
  ) {
    final profileResult = result.result;
    if (!profileResult.isSuccess || profileResult.data == null) {
      return AuthoritativeBootstrapDecisionLoadResult(
        decision: null,
        error: const AuthoritativeBootstrapDecisionReadException(
          code: AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
          message: 'empty',
        ),
        totalDuration: result.totalDuration,
        inflightWaitDuration: result.inflightWaitDuration,
        remoteQueryDuration: result.remoteQueryDuration,
        mapDuration: result.mapDuration,
        remoteCallCount: result.remoteCallCount,
        payloadColumnCount: 11,
      );
    }
    final profile = profileResult.data!;
    final decision = profile.onboardingStatus == OnboardingStatus.completed
        ? AuthoritativeBootstrapDestination.home
        : AuthoritativeBootstrapDestination.onboarding;
    return _authoritativeResult(
      decision: decision,
      userId: profile.userId,
      onboardingStatus: profile.onboardingStatus,
      completedOnboardingVersion: profile.onboardingVersion,
      onboardingCompletedAt: profile.onboardingCompletedAt,
      totalDuration: result.totalDuration,
      inflightWaitDuration: result.inflightWaitDuration,
      remoteQueryDuration: result.remoteQueryDuration,
      mapDuration: result.mapDuration,
      remoteCallCount: result.remoteCallCount,
      payloadColumnCount: 11,
    );
  }

  AuthoritativeBootstrapDecisionLoadResult _authoritativeResultFromDecision(
    AuthoritativeBootstrapDecision decision,
  ) {
    return AuthoritativeBootstrapDecisionLoadResult(
      decision: decision,
      totalDuration: const Duration(milliseconds: 3),
      inflightWaitDuration: Duration.zero,
      remoteQueryDuration: const Duration(milliseconds: 2),
      mapDuration: const Duration(milliseconds: 1),
      remoteCallCount: 1,
      payloadColumnCount: 11,
    );
  }

  AuthoritativeBootstrapDecisionLoadResult _authoritativeResult({
    required AuthoritativeBootstrapDestination decision,
    required String userId,
    OnboardingStatus? onboardingStatus,
    int? completedOnboardingVersion,
    DateTime? onboardingCompletedAt,
    Duration totalDuration = const Duration(milliseconds: 3),
    Duration inflightWaitDuration = Duration.zero,
    Duration remoteQueryDuration = const Duration(milliseconds: 2),
    Duration mapDuration = const Duration(milliseconds: 1),
    int remoteCallCount = 1,
    int payloadColumnCount = 11,
  }) {
    return AuthoritativeBootstrapDecisionLoadResult(
      decision: AuthoritativeBootstrapDecision(
        userId: userId,
        decision: decision,
        accountStatus: switch (decision) {
          AuthoritativeBootstrapDestination.accountSuspended =>
            BootstrapAccountStatus.suspended,
          AuthoritativeBootstrapDestination.accountPendingDeletion =>
            BootstrapAccountStatus.pendingDeletion,
          _ => BootstrapAccountStatus.active,
        },
        profileState: switch (decision) {
          AuthoritativeBootstrapDestination.profileUninitialized =>
            BootstrapProfileState.uninitialized,
          AuthoritativeBootstrapDestination.profileDeleted =>
            BootstrapProfileState.deleted,
          _ => BootstrapProfileState.ready,
        },
        onboardingStatus: onboardingStatus ??
            switch (decision) {
              AuthoritativeBootstrapDestination.home =>
                OnboardingStatus.completed,
              AuthoritativeBootstrapDestination.onboarding =>
                OnboardingStatus.pending,
              _ => null,
            },
        completedOnboardingVersion: completedOnboardingVersion ??
            switch (decision) {
              AuthoritativeBootstrapDestination.home => 1,
              _ => null,
            },
        requiredOnboardingVersion: 1,
        onboardingEnforcement: switch (decision) {
          AuthoritativeBootstrapDestination.home ||
          AuthoritativeBootstrapDestination.onboarding =>
            BootstrapOnboardingEnforcement.required,
          _ => BootstrapOnboardingEnforcement.advisory,
        },
        onboardingCompletedAt: onboardingCompletedAt ??
            switch (decision) {
              AuthoritativeBootstrapDestination.home =>
                DateTime.utc(2026, 7, 28),
              _ => null,
            },
        profileRevision: 3,
        policyRevision: 2,
      ),
      totalDuration: totalDuration,
      inflightWaitDuration: inflightWaitDuration,
      remoteQueryDuration: remoteQueryDuration,
      mapDuration: mapDuration,
      remoteCallCount: remoteCallCount,
      payloadColumnCount: payloadColumnCount,
    );
  }

  AuthoritativeBootstrapDestination _authoritativeDecisionForStatus(
    OnboardingStatus onboardingStatus,
  ) {
    switch (onboardingStatus) {
      case OnboardingStatus.pending:
      case OnboardingStatus.inProgress:
        return AuthoritativeBootstrapDestination.onboarding;
      case OnboardingStatus.completed:
        return AuthoritativeBootstrapDestination.home;
    }
  }
}

class _FakeUserStateStore extends UserStateStore {
  _FakeUserStateStore({
    required bool localOnboardingDone,
  })  : _localOnboardingDone = localOnboardingDone,
        super(
          UserStateRepository(storage: UserStateStorage()),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  final bool _localOnboardingDone;
  String? _scopeUserId;
  Map<String, dynamic>? _fakeState;

  @override
  Map<String, dynamic>? get state => _fakeState;

  @override
  bool get isLoading => false;

  @override
  String? get activeLocalScopeUserId => _scopeUserId;

  @override
  bool get onboardingDone => _localOnboardingDone;

  @override
  String? get userId => _scopeUserId;

  @override
  Future<void> switchLocalScope({
    String? userId,
    bool forceReload = false,
  }) async {
    _scopeUserId = userId;
    _fakeState = <String, dynamic>{
      'userState': <String, dynamic>{
        if (userId != null) 'userId': userId,
        'meta': <String, dynamic>{'onboardingDone': _localOnboardingDone},
      },
    };
  }

  @override
  Future<void> load() async {
    _fakeState ??= <String, dynamic>{
      'userState': <String, dynamic>{
        if (_scopeUserId != null) 'userId': _scopeUserId,
        'meta': <String, dynamic>{'onboardingDone': _localOnboardingDone},
      },
    };
  }

  @override
  void restoreGamificationOverlaysAfterLogout() {}

  @override
  void suppressGamificationOverlaysDuringLogout() {}
}

class _FakeGlobalWalletController extends GlobalWalletController {
  _FakeGlobalWalletController()
      : super(
          repository: _NoopCloudWalletRepository(),
          cache: _NoopWalletCache(),
          enabled: true,
        );

  @override
  Future<GlobalWalletState> syncSession({
    String? userId,
    bool force = false,
  }) async {
    return GlobalWalletState.unauthenticated();
  }

  @override
  Future<GlobalWalletState> clearSession() async {
    return GlobalWalletState.unauthenticated();
  }
}

class _FakeEssentialHabitsPreparer implements BootstrapEssentialHabitsPreparer {
  _FakeEssentialHabitsPreparer({
    this.completer,
    this.status = EssentialHabitsBootstrapStatus.readyFromRemote,
  });

  Completer<EssentialHabitsBootstrapResult>? completer;
  EssentialHabitsBootstrapStatus status;
  int calls = 0;
  DateTime? startedAt;

  @override
  Future<EssentialHabitsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) {
    calls += 1;
    startedAt = DateTime.now();
    final pending = completer;
    if (pending != null) return pending.future;
    return Future<EssentialHabitsBootstrapResult>.value(
      EssentialHabitsBootstrapResult(
        status: status,
        userId: userId,
        source: status == EssentialHabitsBootstrapStatus.confirmedEmpty
            ? 'confirmed_empty'
            : 'remote',
        scopeEpoch: 1,
        requestId: calls,
        duration: Duration.zero,
      ),
    );
  }
}

class _FakeEssentialCosmeticsPreparer
    implements BootstrapEssentialCosmeticsPreparer {
  _FakeEssentialCosmeticsPreparer({
    this.completer,
    this.status = CosmeticsBootstrapStatus.readyFromRemote,
    this.resolversVerified = true,
    this.appliedRevision = 1,
  });

  Completer<CosmeticsBootstrapResult>? completer;
  CosmeticsBootstrapStatus status;
  bool resolversVerified;
  int appliedRevision;
  bool tokenValid = true;
  int calls = 0;
  DateTime? startedAt;
  CosmeticsBootstrapResult? lastResult;

  @override
  Future<CosmeticsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) {
    calls += 1;
    startedAt = DateTime.now();
    final pending = completer;
    if (pending != null) return pending.future;
    final result = CosmeticsBootstrapResult(
      status: status,
      userId: userId,
      source: status == CosmeticsBootstrapStatus.confirmedEmpty
          ? 'confirmed_empty'
          : 'remote',
      requestId: calls,
      duration: Duration.zero,
      appliedRevision: appliedRevision,
      resolversVerified: resolversVerified,
      readyToken: createReadyToken(userId: userId),
    );
    lastResult = result;
    return Future<CosmeticsBootstrapResult>.value(result);
  }

  @override
  CosmeticsReadyToken? createReadyToken({required String userId}) {
    if (!resolversVerified) return null;
    return CosmeticsReadyToken(
      controllerIdentity: 1,
      userId: userId,
      scope: userId,
      appliedRevision: appliedRevision,
      equippedWallpaperId: 'wallpaper_mist_blue',
      equippedHabitCardId: 'habit_card_soft_sage',
      equippedUserCardId: 'user_card_full_moon',
      wallpaperResolved: true,
      habitCardResolved: true,
      userCardResolved: true,
    );
  }

  @override
  bool validateReadyToken(CosmeticsReadyToken token) => tokenValid;
}

class _FakeEssentialAssetPreloader implements BootstrapEssentialAssetPreloader {
  int calls = 0;
  Object? error;

  @override
  Future<void> preload(Iterable<ShopAsset> assets) async {
    calls += 1;
    final failure = error;
    if (failure != null) throw failure;
  }
}

class _NoopCloudWalletRepository implements CloudWalletRepository {
  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() async {
    return const WalletReadResult<CloudWalletSnapshot>.failure(
      failure: WalletFailure(
        code: WalletFailureCode.unknown,
        message: 'noop',
      ),
    );
  }
}

class _NoopWalletCache implements WalletCache {
  @override
  Future<void> clearForUser(String userId) async {}

  @override
  Future<WalletCacheEntry?> read(String userId) async => null;

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async => null;
}

RemoteProfile _profile(String id, OnboardingStatus status) {
  return RemoteProfile(
    id: id,
    onboardingStatus: status,
    onboardingVersion: 1,
    onboardingCompletedAt:
        status == OnboardingStatus.completed ? DateTime.utc(2026, 7, 27) : null,
  );
}

Session _session(User user) {
  return Session(
    accessToken: 'access-token',
    tokenType: 'bearer',
    user: user,
  );
}

User _user(String id) {
  return User(
    id: id,
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-07-27T00:00:00Z',
  );
}
