import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'application/auth/auth_controller.dart';
import 'application/bootstrap/bootstrap_controller.dart';
import 'core/supabase/rutio_supabase_client.dart';
import 'services/notification_runtime.dart';
import 'services/notification_service.dart';
import 'devtools/demo_seed/demo_seed_models.dart';
import 'devtools/demo_seed/demo_seed_runner.dart';
import 'devtools/rutio_runtime_profile.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/user_state_repository.dart';
import 'data/local/user_state_storage.dart';
import 'data/local/asset_json_loader.dart';
import 'features/notifications/application/notification_context_builder.dart';
import 'features/notifications/application/notification_os_reconciliation_coordinator.dart';
import 'features/notifications/application/personalized_notification_orchestrator.dart';
import 'features/notifications/application/personalized_notification_plan_builder.dart';
import 'features/notifications/application/personalized_notification_settings_controller.dart';
import 'features/notifications/data/local/local_notification_template_catalog.dart';
import 'features/notifications/data/local/notification_platform_id_repository.dart';
import 'features/notifications/data/local/shared_preferences_notification_history_store.dart';
import 'features/notifications/data/local/shared_preferences_notification_install_id_provider.dart';
import 'features/notifications/data/local/shared_preferences_notification_preferences_store.dart';
import 'features/notifications/data/local/shared_preferences_notification_schedule_store.dart';
import 'features/notifications/data/native/flutter_local_notifications_native_gateway.dart';
import 'features/notifications/data/native/native_notification_schedule_executor.dart';
import 'features/feedback/presentation/screens/feedback_home_screen.dart';
import 'features/feedback/presentation/screens/feedback_form_screen.dart';
import 'features/feedback/presentation/screens/feedback_success_screen.dart';
import 'features/feedback/presentation/screens/feedback_detail_screen.dart';
import 'features/feedback/presentation/screens/my_feedback_screen.dart';
import 'features/feedback/domain/feedback_category.dart';
import 'features/feedback/domain/feedback_report.dart';
import 'features/feedback/domain/feedback_status.dart';
import 'features/shop/application/shop_cosmetics_controller.dart';
import 'features/shop/data/cloud/shop_cloud_runtime_config.dart';
import 'features/global_wallet/application/global_wallet_controller.dart';
import 'features/achievements/presentation/screens/achievements_screen.dart';
import 'features/achievements/presentation/widgets/achievement_unlock_overlay_host.dart';
import 'stores/user_state_store.dart';

import 'utils/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/l10n.dart';

import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/root_gate.dart';
import 'screens/shop_screen.dart';

import 'screens/diary/diary_screen.dart';
import 'screens/diary_v2/diary_v2_screen.dart';
import 'screens/habit_archived_screen.dart';
import 'screens/todo/todo_screen.dart';
import 'features/statistics/presentation/v3/screens/statistics_v3_screen.dart';

import 'screens/app_startup_gate.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';

void _startupLog(String message) {
  if (kDebugMode) debugPrint(message);
}

Future<void> main() async {
  _startupLog('[STARTUP] 01 main() entered');
  _startupLog('[STARTUP] 02 before WidgetsFlutterBinding.ensureInitialized()');
  WidgetsFlutterBinding.ensureInitialized();
  _startupLog('[STARTUP] 03 after WidgetsFlutterBinding.ensureInitialized()');
  final shopCloudConfig = ShopCloudRuntimeConfig.compiled(
    isRelease: kReleaseMode,
  );
  debugPrint(
    '[shop_cloud_config] '
    'runtime_mode=${shopCloudConfig.runtimeMode.name} '
    'fully_cloud=${shopCloudConfig.isFullyCloud} '
    'fully_legacy=${shopCloudConfig.isFullyLegacy} '
    'invalid_mixed=${shopCloudConfig.isMixed} '
    'flags=${shopCloudConfig.flags}',
  );
  shopCloudConfig.validateForStartup(isRelease: kReleaseMode);
  _startupLog('[STARTUP] 04 before RutioSupabaseClient.initialize()');
  await RutioSupabaseClient.initialize();
  _startupLog('[STARTUP] 05 after RutioSupabaseClient.initialize()');

  final userStateStorage = UserStateStorage();
  final userStateRepository = UserStateRepository(storage: userStateStorage);
  _startupLog('[STARTUP] 06 before DemoSeedRunner.prepare()');
  await DemoSeedRunner(
    repository: userStateRepository,
    storage: userStateStorage,
  ).prepare();
  _startupLog('[STARTUP] 07 after DemoSeedRunner.prepare()');

  try {
    _startupLog('[STARTUP] 08 before NotificationService.init()');
    await NotificationService.instance.init();
    _startupLog('[STARTUP] 09 after NotificationService.init()');
  } catch (error, stackTrace) {
    debugPrint('[main] Notification init failed: $error');
    debugPrintStack(
      label: '[main]',
      stackTrace: stackTrace,
    );
  }
  _startupLog('[STARTUP] 10 before runApp()');
  runApp(MyApp(shopRuntimeConfig: shopCloudConfig));
  _startupLog('[STARTUP] 11 after runApp()');
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.shopRuntimeConfig,
  });

  final ShopCloudRuntimeConfig shopRuntimeConfig;

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    _startupLog('[STARTUP] 12 MyApp.build() entered');
    _startupLog('[STARTUP] 13 composing NotificationRuntime wrapper');
    final runtime = NotificationRuntime(
      child: Consumer<UserStateStore>(
        builder: (context, store, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Rutio',
          theme: AppTheme.theme,
          locale: store.preferredLocale,
          navigatorKey: _navigatorKey,
          builder: (context, child) => AchievementUnlockOverlayHost(
            navigatorKey: _navigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppStartupGate(),
          routes: {
            '/splash': (_) => const AppStartupGate(),
            '/welcome': (_) => const WelcomeScreen(),
            '/auth': (_) => const SignInScreen(),
            '/auth-signup': (_) => const SignUpScreen(),
            SignInScreen.route: (_) => const SignInScreen(),
            SignUpScreen.route: (_) => const SignUpScreen(),
            AuthGate.route: (_) => const AppStartupGate(
                  authenticatedBuilder: _authenticatedRootBuilder,
                ),
            '/root': (_) => const AppStartupGate(
                  authenticatedBuilder: _authenticatedRootBuilder,
                ),
            '/home': (_) => const AppStartupGate(
                  authenticatedBuilder: _authenticatedHomeBuilder,
                ),
            TodoScreen.route: (_) => const TodoScreen(),
            ProfileScreen.route: (_) => const ProfileScreen(),
            AchievementsScreen.route: (_) => const AchievementsScreen(),
            '/diary': (_) => const DiaryV2Screen(),
            '/diary-legacy': (_) => const DiaryScreen(),
            DiaryV2Screen.route: (_) => const DiaryV2Screen(),
            '/archived': (_) => ArchivedHabitsScreen(),
            '/stats': (_) => const StatisticsV3Screen(),
            StatisticsV3Screen.route: (_) => const StatisticsV3Screen(),
            FeedbackHomeScreen.route: (_) => const FeedbackHomeScreen(),
            FeedbackFormScreen.route: (_) => const FeedbackFormScreen(),
            FeedbackSuccessScreen.route: (context) =>
                FeedbackSuccessScreen(report: _feedbackRouteReport(context)),
            MyFeedbackScreen.route: (context) => MyFeedbackScreen(
                submittedReport: _feedbackRouteReport(context)),
            FeedbackDetailScreen.route: (context) => FeedbackDetailScreen(
                  report: _feedbackRouteReport(context) ??
                      FeedbackReport(
                        id: 'feedback-fallback-detail',
                        category: FeedbackCategory.bug,
                        description: context.l10n.feedbackPlaceholderBody,
                        contactAllowed: false,
                        status: FeedbackStatus.submitted,
                        createdAt: DateTime(2026, 8, 29, 12, 0),
                      ),
                ),
            '/shop': (_) => const AppStartupGate(
                  authenticatedBuilder: _authenticatedShopBuilder,
                ),
          },
        ),
      ),
    );
    _startupLog('[STARTUP] 14 NotificationRuntime wrapper composed');
    return MultiProvider(
      providers: [
        Provider<ShopCloudRuntimeConfig>.value(value: shopRuntimeConfig),
        Provider<UserStateStorage>(create: (_) => UserStateStorage()),
        Provider<AssetJsonLoader>(create: (_) => AssetJsonLoader()),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<ProfileRepository>(create: (_) => ProfileRepository()),
        ProxyProvider2<UserStateStorage, AssetJsonLoader, UserStateRepository>(
          update: (_, storage, assets, __) => UserStateRepository(
            storage: storage,
            assets: assets,
          ),
        ),
        ChangeNotifierProvider<GlobalWalletController>(
          create: (_) => GlobalWalletController(),
        ),
        ChangeNotifierProvider<UserStateStore>(
          create: (context) {
            final userStateRepository = context.read<UserStateRepository>();
            final initialUserId = RutioRuntimeProfile.isDemo
                ? DemoSeedScope.userId
                : RutioSupabaseClient.instance.auth.currentUser?.id;
            userStateRepository.setActiveUserScope(initialUserId);

            return UserStateStore(
              userStateRepository,
              globalWalletController: context.read<GlobalWalletController>(),
              profileRepository: context.read<ProfileRepository>(),
            )..load();
          },
        ),
        Provider<PersonalizedNotificationOrchestrator>(
          create: (context) {
            final userStateStore = context.read<UserStateStore>();
            final scheduleStore = SharedPreferencesNotificationScheduleStore();
            final historyStore = SharedPreferencesNotificationHistoryStore();
            final installIdProvider =
                SharedPreferencesNotificationInstallIdProvider();
            final gateway = FlutterLocalNotificationsNativeGateway();
            final executor = NativeNotificationScheduleExecutor(
              gateway: gateway,
              isScopeActive: () async {
                final activeUserId =
                    userStateStore.activeLocalScopeUserId?.trim();
                final storeUserId = userStateStore.userId?.trim();
                return activeUserId != null &&
                    activeUserId.isNotEmpty &&
                    activeUserId == storeUserId;
              },
            );
            final orchestrator = PersonalizedNotificationOrchestrator(
              userStateStore: userStateStore,
              installIdProvider: installIdProvider,
              preferencesResolver:
                  StoreBackedPersonalizedNotificationPreferencesResolver(
                store: SharedPreferencesNotificationPreferencesStore(),
                userStateStore: userStateStore,
              ),
              scheduleStore: scheduleStore,
              scheduleExecutor: executor,
              planBuilder: PersonalizedNotificationPlanBuilder(
                contextBuilder: StoreBackedNotificationContextBuilder(
                  store: UserStateStoreNotificationContextSource(
                    userStateStore,
                  ),
                  installIdProvider: installIdProvider,
                  historyStore: historyStore,
                ),
                templateCatalog: LocalNotificationTemplateCatalog(
                  assetJsonLoader: context.read<AssetJsonLoader>(),
                ),
                platformIdProvider: NotificationPlatformIdRepository(
                  scheduleStore: scheduleStore,
                ),
              ),
              coordinator: NotificationOsReconciliationCoordinator(
                scheduleStore: scheduleStore,
                historyStore: historyStore,
                executor: executor,
              ),
            );
            userStateStore.setNotificationMutationObserver(orchestrator);
            return orchestrator;
          },
        ),
        ChangeNotifierProvider<PersonalizedNotificationSettingsController>(
          create: (context) => PersonalizedNotificationSettingsController(
            userStateStore: context.read<UserStateStore>(),
            preferencesStore: SharedPreferencesNotificationPreferencesStore(),
            orchestrator: context.read<PersonalizedNotificationOrchestrator>(),
            installIdProvider: SharedPreferencesNotificationInstallIdProvider(),
          ),
        ),
        ChangeNotifierProvider<ShopCosmeticsController>(
          create: (context) => ShopCosmeticsController(
            userStateStore: context.read<UserStateStore>(),
            globalWalletController: context.read<GlobalWalletController>(),
            cloudEnabled:
                context.read<ShopCloudRuntimeConfig>().cloudCosmeticsEnabled,
          ),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            context.read<AuthRepository>(),
            userStateStore: context.read<UserStateStore>(),
            profileRepository: context.read<ProfileRepository>(),
            globalWalletController: context.read<GlobalWalletController>(),
            personalizedNotificationOrchestrator:
                context.read<PersonalizedNotificationOrchestrator>(),
          ),
        ),
        ChangeNotifierProxyProvider4<AuthController, UserStateStore,
            ProfileRepository, ShopCosmeticsController, BootstrapController>(
          create: (context) => BootstrapController(
            authController: context.read<AuthController>(),
            userStateStore: context.read<UserStateStore>(),
            profileRepository: ProfileBootstrapRepository(
              context.read<ProfileRepository>(),
            ),
            essentialCosmeticsPreparer: ShopBootstrapEssentialCosmeticsPreparer(
              context.read<ShopCosmeticsController>(),
            ),
            onHomeReady: (_) => context
                .read<PersonalizedNotificationOrchestrator>()
                .reconcileForBootstrapReady(),
          ),
          update: (_, __, ___, ____, _____, controller) => controller!,
        ),
      ],
      child: runtime,
    );
  }
}

Widget _authenticatedRootBuilder(BuildContext context) => const RootGate();

Widget _authenticatedHomeBuilder(BuildContext context) => const HomeScreen();

Widget _authenticatedShopBuilder(BuildContext context) => const ShopScreen();

FeedbackReport? _feedbackRouteReport(BuildContext context) {
  final arguments = ModalRoute.of(context)?.settings.arguments;
  if (arguments is FeedbackReport) {
    return arguments;
  }
  return null;
}
