import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/application/auth/auth_controller.dart';
import 'package:rutio/application/bootstrap/bootstrap_controller.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/auth_repository.dart';
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
      expect(fixture.profile.fetchCalls, 0);
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

    test('completed account never emits onboarding while profile is loading',
        () async {
      final slow = Completer<RepositoryResult<RemoteProfile?>>();
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

      slow.complete(
        RepositoryResult<RemoteProfile?>.success(
          data: _profile('user-1', OnboardingStatus.completed),
        ),
      );
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(destinations, isNot(contains(BootstrapDestination.onboarding)));
    });

    test('pending remote profile keeps preparation until fetch resolves',
        () async {
      final slow = Completer<RepositoryResult<RemoteProfile?>>();
      final fixture = _Fixture(profileCompleter: slow);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(
          fixture.bootstrap.state.phase, BootstrapPhase.loadingRemoteProfile);
      expect(fixture.bootstrap.state.destination, isNull);

      slow.complete(
        RepositoryResult<RemoteProfile?>.success(
          data: _profile('user-1', OnboardingStatus.pending),
        ),
      );
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

    test('missing profile does not route to home', () async {
      final fixture = _Fixture(profileResult: _ProfileResult.missing);
      fixture.resolveUser('user-1');
      await fixture.pump();

      expect(fixture.bootstrap.state.phase, BootstrapPhase.failed);
      expect(fixture.bootstrap.state.destination, isNull);
      expect(
        fixture.bootstrap.state.error?.type,
        BootstrapErrorType.profileNotFound,
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
      expect(fixture.profile.fetchCalls, 2);
    });

    test('user change discards previous profile result', () async {
      final slow = Completer<RepositoryResult<RemoteProfile?>>();
      final fixture = _Fixture(profileCompleter: slow);
      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.profile.completer = null;
      fixture.profile.result = _ProfileResult.completed;
      fixture.resolveUser('user-2');
      await fixture.pump();
      slow.complete(
        RepositoryResult<RemoteProfile?>.success(
          data: _profile('user-1', OnboardingStatus.completed),
        ),
      );
      await fixture.pump();

      expect(fixture.bootstrap.state.user?.id, 'user-2');
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('stale pending profile does not affect completed user', () async {
      final slow = Completer<RepositoryResult<RemoteProfile?>>();
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
      slow.complete(
        RepositoryResult<RemoteProfile?>.success(
          data: _profile('user-1', OnboardingStatus.pending),
        ),
      );
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
      final slow = Completer<RepositoryResult<RemoteProfile?>>();
      final fixture = _Fixture(profileCompleter: slow);
      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.resolveGuest();
      await fixture.pump();
      slow.complete(
        RepositoryResult<RemoteProfile?>.success(
          data: _profile('user-1', OnboardingStatus.completed),
        ),
      );
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
    _ProfileResult profileResult = _ProfileResult.fromStatus,
    Completer<RepositoryResult<RemoteProfile?>>? profileCompleter,
    _FakeEssentialHabitsPreparer? habitsPreparer,
    _FakeEssentialCosmeticsPreparer? cosmeticsPreparer,
    _FakeEssentialAssetPreloader? assetPreloader,
  })  : authStream = StreamController<AuthState>.broadcast(sync: true),
        userStore = _FakeUserStateStore(
          localOnboardingDone: localOnboardingDone,
        ),
        wallet = _FakeGlobalWalletController(),
        profile = _FakeProfileRepository(
          status: profileStatus,
          result: profileResult,
          completer: profileCompleter,
        ) {
    if (restoredUserId != null) {
      currentUser = _user(restoredUserId);
      profile.currentFetchUserId = restoredUserId;
    }
    auth = AuthController(
      AuthRepository(
        authStateChangesProvider: () => authStream.stream,
        currentUserProvider: () => currentUser,
      ),
      userStateStore: userStore,
      globalWalletController: wallet,
      profileRepository: null,
      enableBackgroundProfileSync: false,
    );
    bootstrap = BootstrapController(
      authController: auth,
      userStateStore: userStore,
      profileRepository: profile,
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
  });

  OnboardingStatus status;
  _ProfileResult result;
  Completer<RepositoryResult<RemoteProfile?>>? completer;
  Completer<RepositoryResult<RemoteProfile>>? completeCompleter;
  int fetchCalls = 0;
  int completeCalls = 0;

  @override
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() {
    fetchCalls += 1;
    final pending = completer;
    if (pending != null) return pending.future;
    switch (result) {
      case _ProfileResult.fromStatus:
        return Future.value(
          RepositoryResult<RemoteProfile?>.success(
            data: _profile(currentFetchUserId, status),
          ),
        );
      case _ProfileResult.completed:
        return Future.value(
          RepositoryResult<RemoteProfile?>.success(
            data: _profile(currentFetchUserId, OnboardingStatus.completed),
          ),
        );
      case _ProfileResult.missing:
        return Future.value(
          const RepositoryResult<RemoteProfile?>.success(data: null),
        );
      case _ProfileResult.network:
        return Future.value(
          const RepositoryResult<RemoteProfile?>.failure(
            RepositoryError(
              code: RepositoryErrorCode.network,
              message: 'network',
            ),
          ),
        );
    }
  }

  String currentFetchUserId = 'user-1';

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
