import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/achievements/application/achievement_catalog.dart';
import '../../features/achievements/application/achievement_progress_service.dart';
import '../../features/achievements/domain/models/achievement.dart';
import '../../features/achievements/domain/models/achievement_progress.dart';
import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/achievements/presentation/widgets/featured_achievement_picker_sheet.dart';
import '../../features/achievements/presentation/widgets/featured_achievements_section.dart';
import '../../l10n/l10n.dart';
import '../../services/notification_preferences.dart';
import '../../services/notification_service.dart';
import '../../stores/user_state_store.dart';
import '../../utils/family_theme.dart';
import '../diary/diary_screen.dart';
import '../edit_profile/edit_profile_screen.dart';
import '../habit_archived_screen.dart';
import '../habit_monthly_screen.dart';
import '../habit_stats_overview_screen.dart';
import '../habit_weekly_screen.dart';
import '../home/home_screen.dart';
import 'models/family_color_ref.dart';
import 'notification_settings_screen.dart';
import 'settings_screen.dart';
import 'utils/profile_levels_from_history.dart';
import 'widgets/family_radar_section.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_option_tile.dart';
import 'widgets/section_card.dart';
import 'widgets/switch_row.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/app_header/app_header.dart';

void _navReplace(BuildContext context, Widget screen) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

class ProfileScreen extends StatefulWidget {
  static const route = '/profile';

  final String? userName;
  final String? subtitle;
  final String? email;
  final ImageProvider? avatarImage;
  final List<dynamic>? habits;
  final Map<String, Color>? familyColors;
  final Color Function(FamilyColorRef ref)? familyColorResolver;
  final String Function(FamilyColorRef ref)? titleResolver;
  final VoidCallback? onEditProfile;
  final bool openEditProfileOnLoad;

  const ProfileScreen({
    super.key,
    this.userName,
    this.subtitle,
    this.email,
    this.avatarImage,
    this.habits,
    this.familyColors,
    this.familyColorResolver,
    this.titleResolver,
    this.onEditProfile,
    this.openEditProfileOnLoad = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _didOpenInitialEdit = false;
  static const int _notificationCategoryTotal = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.openEditProfileOnLoad || _didOpenInitialEdit) return;

    _didOpenInitialEdit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openEditProfile();
    });
  }

  void _openEditProfile() {
    final onEditProfile = widget.onEditProfile;
    if (onEditProfile != null) {
      onEditProfile();
      return;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openNotificationSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _openAchievementsScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  Future<void> _handleFeaturedAchievementsTap() async {
    final store = context.read<UserStateStore>();
    final data = _ProfileAchievementsData.fromStore(store);

    if (data.unlockedItems.isEmpty) {
      _openAchievementsScreen();
      return;
    }

    await showFeaturedAchievementPickerSheet(
      context,
      unlockedAchievements: data.unlockedItems,
      selectedIds: data.featuredIds,
      onSave: (selectedIds) async {
        await store.setFeaturedAchievementIds(selectedIds);
      },
    );
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    final store = context.read<UserStateStore>();
    final preferences = NotificationPreferences(store);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    if (enabled) {
      final result = await NotificationService.instance.requestPermissionFlow();
      if (!result.isAuthorized) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.notificationPermissionMessage(result.status)),
            action: result.shouldOpenSettings
                ? SnackBarAction(
                    label: l10n.commonOpenSettings,
                    onPressed: NotificationService.instance.openSettings,
                  )
                : null,
          ),
        );
        return;
      }
    }

    await preferences.setMasterEnabled(enabled);
    await NotificationService.instance.syncPhaseOne(store: store);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final root = store.state;
    final userState = (root?['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final profile = (userState['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final avatarUrl = (profile['avatarUrl'] ?? '').toString().trim();

    ImageProvider? resolvedAvatar;
    if (avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        resolvedAvatar = NetworkImage(avatarUrl);
      } else {
        final path = avatarUrl.startsWith('file://')
            ? avatarUrl.substring(7)
            : avatarUrl;
        resolvedAvatar = FileImage(File(path));
      }
    }
    resolvedAvatar ??= widget.avatarImage;

    const accent = Color(0xFF6C5CE7);
    const bg = Color(0xFFF7F6FF);

    final name = (widget.userName?.trim().isNotEmpty ?? false)
        ? widget.userName!.trim()
        : l10n.profileDefaultName;
    final subtitle = (widget.subtitle?.trim().isNotEmpty ?? false)
        ? widget.subtitle!.trim()
        : l10n.profileDefaultSubtitle;
    final email = widget.email;

    final habitsDyn = (userState['activeHabits'] as List?) ??
        (userState['habits'] as List?) ??
        (root?['activeHabits'] as List?) ??
        (root?['habits'] as List?) ??
        (widget.habits ?? const <dynamic>[]);

    final activeHabits = habitsDyn
        .whereType<Map>()
        .map((habit) => habit.cast<String, dynamic>())
        .toList(growable: false);

    final familyLevels = buildFamilyLevelsFromHistory(
      userState: userState,
      activeHabits: activeHabits,
      familyTitleResolver: l10n.familyName,
      extraFamilyIds:
          List<String>.from(widget.familyColors?.keys ?? const <String>[]),
    );

    final notificationPreferences = NotificationPreferences(store).snapshot;
    final enabledCategories = <bool>[
      notificationPreferences.habitRemindersEnabled,
      notificationPreferences.dayClosureEnabled,
      notificationPreferences.streakRiskEnabled,
      notificationPreferences.streakCelebrationEnabled,
      notificationPreferences.inactivityReengagementEnabled,
    ].where((value) => value).length;
    final achievementData = _ProfileAchievementsData.fromStore(store);

    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'profile',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pushNamed(context, '/todo'),
        onGoDiary: () => _navReplace(context, const DiaryScreen()),
        onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
        onGoStats: () => _navReplace(context, const HabitStatsOverviewHost()),
        onGoProfile: () => _navReplace(context, const ProfileScreen()),
      ),
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: bg,
        leadingWidth: AppDrawerAppBarLeading.leadingWidth,
        leading: Builder(
          builder: (ctx) => AppDrawerAppBarLeading(
            onTap: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(l10n.profileTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          ProfileHeader(
            accent: accent,
            name: name,
            subtitle: subtitle,
            email: email,
            avatarImage: resolvedAvatar,
            onEdit: _openEditProfile,
          ),
          const SizedBox(height: 14),
          FamilyRadarSection(
            accent: accent,
            familyLevels: familyLevels,
            familyColors: widget.familyColors ?? FamilyTheme.colors,
            familyColorResolver: widget.familyColorResolver,
          ),
          const SizedBox(height: 14),
          FeaturedAchievementsSection(
            featuredAchievements: achievementData.featuredItems,
            onTap: _handleFeaturedAchievementsTap,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.profileNotificationsTitle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: [
                SwitchRow(
                  title: l10n.profileEnableNotificationsTitle,
                  subtitle: l10n.profileEnableNotificationsSubtitle,
                  value: notificationPreferences.notificationsEnabled,
                  onChanged: _setNotificationsEnabled,
                ),
                const SizedBox(height: 12),
                ProfileOptionTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.profileNotificationSettingsTitle,
                  subtitle: l10n.profileNotificationCategoriesActive(
                    enabledCategories,
                    _notificationCategoryTotal,
                  ),
                  onTap: _openNotificationSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.profileAccountSectionTitle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: [
                ProfileOptionTile(
                  icon: Icons.settings_outlined,
                  title: context.l10n.profileSettingsTitle,
                  subtitle: context.l10n.profileSettingsSubtitle,
                  onTap: _openSettings,
                ),
                const SizedBox(height: 12),
                ProfileOptionTile(
                  icon: CupertinoIcons.rosette,
                  title: l10n.profileAchievementsTitle,
                  subtitle: l10n.profileAchievementsSubtitle,
                  onTap: _openAchievementsScreen,
                  iconColor: const Color(0xFFB48842),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAchievementsData {
  const _ProfileAchievementsData({
    required this.featuredItems,
    required this.unlockedItems,
    required this.featuredIds,
  });

  final List<AchievementProgress> featuredItems;
  final List<AchievementProgress> unlockedItems;
  final List<String> featuredIds;

  factory _ProfileAchievementsData.fromStore(UserStateStore store) {
    final achievements = AchievementCatalog.buildAchievements(
      unlockedRecords: store.unlockedAchievementRecords,
    );
    final progressItems = AchievementProgressService.resolve(
      achievements: achievements,
      snapshotsBySourceId: store.achievementMetricSnapshots,
      unlockedById: store.unlockedAchievementsById,
    );
    final unlockedItems = progressItems
        .where((item) => item.status == AchievementStatus.unlocked)
        .toList(growable: false);
    final featuredIds = store.featuredAchievementIds;
    final featuredItems = featuredIds
        .map(
          (id) => unlockedItems.where((item) => item.achievement.id == id),
        )
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList(growable: false);

    return _ProfileAchievementsData(
      featuredItems: featuredItems,
      unlockedItems: unlockedItems,
      featuredIds: featuredIds,
    );
  }
}
