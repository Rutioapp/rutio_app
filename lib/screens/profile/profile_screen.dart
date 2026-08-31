import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../features/achievements/application/achievement_catalog.dart';
import '../../features/achievements/application/achievement_progress_service.dart';
import '../../features/achievements/domain/models/achievement.dart';
import '../../features/achievements/domain/models/achievement_progress.dart';
import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/achievements/presentation/widgets/featured_achievement_picker_sheet.dart';
import '../../features/achievements/presentation/widgets/featured_achievements_section.dart';
import '../../features/gamification/domain/level_progression.dart';
import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import '../../utils/family_theme.dart';
import '../diary_v2/diary_v2_screen.dart';
import '../edit_profile/edit_profile_screen.dart';
import '../habit_archived_screen.dart';
import '../habit_monthly_screen.dart';
import '../habit_weekly_screen.dart';
import '../home/home_screen.dart';
import 'models/family_color_ref.dart';
import 'settings_screen.dart';
import 'utils/profile_levels_from_history.dart';
import 'widgets/profile_goal_card.dart';
import 'widgets/profile_pillar_habits_section.dart';
import 'widgets/profile_stats_summary_card.dart';
import 'widgets/profile_progress_card.dart';
import 'widgets/family_radar_section.dart';
import 'widgets/profile_header.dart';
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

  final Map<String, Color>? familyColors;
  final Color Function(FamilyColorRef ref)? familyColorResolver;
  final VoidCallback? onEditProfile;
  final bool openEditProfileOnLoad;

  const ProfileScreen({
    super.key,
    this.familyColors,
    this.familyColorResolver,
    this.onEditProfile,
    this.openEditProfileOnLoad = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _didOpenInitialEdit = false;

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

  void _openStatistics() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const StatisticsV3Screen()),
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

  Future<void> _handlePillarHabitsTap() async {
    final store = context.read<UserStateStore>();
    await showPillarHabitPickerSheet(
      context,
      store: store,
      selectedIds: store.pillarHabitIds,
      onSave: (selectedIds) async {
        await store.setPillarHabitIds(selectedIds);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final root = store.state;
    final userState = (root?['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final avatarUrl = (store.avatarUrl ?? '').trim();

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

    const accent = AppColors.earth;
    const bg = AppColors.cream;

    final name = (store.displayName ?? '').trim().isNotEmpty
        ? store.displayName!.trim()
        : l10n.profileDefaultName;
    final note = (store.bioText ?? '').trim();
    final goal = (store.goalText ?? '').trim();

    final progression =
        (userState['progression'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final xp = ((progression['xp'] as num?) ?? 0).toInt();
    final levelProgression = LevelProgression.fromTotalXp(xp);
    final weeklyConsistencyPct = buildStatisticsV3WeeklyConsistencyPct(
      store: store,
      l10n: l10n,
    );
    final pillarHabits = buildProfilePillarHabitCards(store);
    final streakSnapshot = store.globalHabitStreakSnapshot;
    final currentStreakDays = streakSnapshot.currentStreak;
    final bestStreakDays = streakSnapshot.bestStreak;
    final activeDaysCount = store.activeDaysCount;

    final habitsDyn = (userState['activeHabits'] as List?) ??
        (userState['habits'] as List?) ??
        (root?['activeHabits'] as List?) ??
        (root?['habits'] as List?) ??
        const <dynamic>[];

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

    final achievementData = _ProfileAchievementsData.fromStore(store);

    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'profile',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoDiary: () => _navReplace(context, const DiaryV2Screen()),
        onGoDiaryV2: () => Navigator.of(context).pushReplacementNamed('/diary'),
        onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
        onGoStats: () => _navReplace(context, const StatisticsV3Screen()),
        onGoShop: () => Navigator.pushNamed(context, '/shop'),
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
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          ProfileHeader(
            accent: accent,
            name: name,
            note: note.isNotEmpty ? note : null,
            goal: goal.isNotEmpty ? goal : null,
            avatarImage: resolvedAvatar,
            onEdit: _openEditProfile,
          ),
          const SizedBox(height: 14),
          ProfileProgressCard(
            accent: accent,
            progression: levelProgression,
          ),
          const SizedBox(height: 14),
          ProfileStatsSummaryCard(
            title: l10n.statisticsV3SummaryCardTitle,
            currentStreakDays: currentStreakDays,
            bestStreakDays: bestStreakDays,
            weeklyConsistencyPct: weeklyConsistencyPct,
            activeDaysLabel: l10n.statisticsV3ConsistencyActiveDays,
            activeDaysCount: activeDaysCount,
            onTap: _openStatistics,
          ),
          const SizedBox(height: 14),
          ProfileGoalCard(
            accent: accent,
            goalText: goal.isNotEmpty ? goal : null,
            weeklyConsistencyPct: weeklyConsistencyPct,
            onEdit: _openEditProfile,
          ),
          const SizedBox(height: 14),
          ProfilePillarHabitsSection(
            accent: accent,
            pillarHabits: pillarHabits,
            onTap: _handlePillarHabitsTap,
          ),
          const SizedBox(height: 14),
          FamilyRadarSection(
            accent: accent,
            familyLevels: familyLevels,
            familyColors: widget.familyColors ?? FamilyTheme.colors,
            familyColorResolver: widget.familyColorResolver,
            onTap: _openStatistics,
          ),
          const SizedBox(height: 14),
          FeaturedAchievementsSection(
            featuredAchievements: achievementData.featuredItems,
            onTap: _handleFeaturedAchievementsTap,
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
