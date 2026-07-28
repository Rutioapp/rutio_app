import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/gen/app_localizations.dart';

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
import 'features/shop/application/shop_cosmetics_controller.dart';
import 'features/shop/data/cloud/shop_cloud_runtime_config.dart';
import 'features/global_wallet/application/global_wallet_controller.dart';
import 'features/achievements/presentation/screens/achievements_screen.dart';
import 'features/achievements/presentation/widgets/achievement_unlock_overlay_host.dart';
import 'stores/user_state_store.dart';

import 'utils/app_theme.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  await RutioSupabaseClient.initialize();

  final userStateStorage = UserStateStorage();
  final userStateRepository = UserStateRepository(storage: userStateStorage);
  await DemoSeedRunner(
    repository: userStateRepository,
    storage: userStateStorage,
  ).prepare();

  try {
    await NotificationService.instance.init();
  } catch (error, stackTrace) {
    debugPrint('[main] Notification init failed: $error');
    debugPrintStack(
      label: '[main]',
      stackTrace: stackTrace,
    );
  }
  runApp(MyApp(shopRuntimeConfig: shopCloudConfig));
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
          ),
          update: (_, __, ___, ____, _____, controller) => controller!,
        ),
      ],
      child: NotificationRuntime(
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
              '/shop': (_) => const AppStartupGate(
                    authenticatedBuilder: _authenticatedShopBuilder,
                  ),
            },
          ),
        ),
      ),
    );
  }
}

Widget _authenticatedRootBuilder(BuildContext context) => const RootGate();

Widget _authenticatedHomeBuilder(BuildContext context) => const HomeScreen();

Widget _authenticatedShopBuilder(BuildContext context) => const ShopScreen();
