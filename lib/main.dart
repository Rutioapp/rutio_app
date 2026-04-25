import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/gen/app_localizations.dart';

import 'application/auth/auth_controller.dart';
import 'core/supabase/rutio_supabase_client.dart';
import 'services/notification_runtime.dart';
import 'services/notification_service.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/user_state_repository.dart';
import 'data/local/user_state_storage.dart';
import 'data/local/asset_json_loader.dart';
import 'features/achievements/presentation/screens/achievements_screen.dart';
import 'features/achievements/presentation/widgets/achievement_unlock_overlay_host.dart';
import 'stores/user_state_store.dart';

import 'utils/app_theme.dart';

import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/root_gate.dart';

import 'screens/diary/diary_screen.dart';
import 'screens/habit_archived_screen.dart';
import 'screens/habit_stats_overview_screen.dart';
import 'screens/todo/todo_screen.dart';

import 'screens/app_startup_gate.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RutioSupabaseClient.initialize();
  try {
    await NotificationService.instance.init();
  } catch (error, stackTrace) {
    debugPrint('[main] Notification init failed: $error');
    debugPrintStack(
      label: '[main]',
      stackTrace: stackTrace,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        ChangeNotifierProvider<UserStateStore>(
          create: (context) => UserStateStore(
            context.read<UserStateRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            context.read<AuthRepository>(),
            userStateStore: context.read<UserStateStore>(),
            profileRepository: context.read<ProfileRepository>(),
          ),
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
              AuthGate.route: (_) => const AuthGate(
                    authenticatedBuilder: _authenticatedRootBuilder,
                  ),
              '/root': (_) => const AuthGate(
                    authenticatedBuilder: _authenticatedRootBuilder,
                  ),
              '/home': (_) => const AuthGate(
                    authenticatedBuilder: _authenticatedHomeBuilder,
                  ),
              TodoScreen.route: (_) => const TodoScreen(),
              ProfileScreen.route: (_) => const ProfileScreen(),
              AchievementsScreen.route: (_) => const AchievementsScreen(),
              '/diary': (_) => DiaryScreen(),
              '/archived': (_) => ArchivedHabitsScreen(),
              '/stats': (_) => HabitStatsOverviewHost(),
            },
          ),
        ),
      ),
    );
  }
}

Widget _authenticatedRootBuilder(BuildContext context) => const RootGate();

Widget _authenticatedHomeBuilder(BuildContext context) => const HomeScreen();
