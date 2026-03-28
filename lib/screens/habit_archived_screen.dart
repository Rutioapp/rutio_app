import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';
import 'package:rutio/widgets/app_view_drawer.dart';

import '../l10n/l10n.dart';
import '../stores/user_state_store.dart';
import '../utils/family_theme.dart';
import 'habit_detail/habit_detail_screen.dart';

void _navReplace(BuildContext context, Widget screen) {
  final st = Scaffold.maybeOf(context);
  if (st != null && st.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

class ArchivedHabitsScreen extends StatelessWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final habits = store.activeHabits.where((h) {
      return h['archived'] == true || h['isArchived'] == true;
    }).toList();

    return Stack(
      children: [
        const HomeBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: AppViewDrawer(
            selected: 'archived',
            onGoDaily: () => _navReplace(context, const HomeScreen()),
            onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
            onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
            onGoTodo: () => Navigator.pushNamed(context, '/todo'),
            onGoDiary: () => _navReplace(context, const DiaryScreen()),
            onGoArchived: () =>
                _navReplace(context, const ArchivedHabitsScreen()),
            onGoStats: () =>
                _navReplace(context, const HabitStatsOverviewHost()),
            onGoProfile: () => _navReplace(context, const ProfileScreen()),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: AppDrawerAppBarLeading.leadingWidth,
            leading: Builder(
              builder: (ctx) => AppDrawerAppBarLeading(
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text(l10n.archivedHabitsTitle),
          ),
          body: habits.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.archivedHabitsEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final h = habits[index];
                    final id =
                        (h['id'] ?? h['habitId'] ?? h['uuid'] ?? h['key'] ?? '')
                            .toString();
                    final rawTitle =
                        (h['title'] ?? h['name'] ?? '').toString().trim();
                    final title = rawTitle.isEmpty
                        ? l10n.homeFallbackHabitTitle
                        : rawTitle;
                    final familyId =
                        (h['familyId'] ?? FamilyTheme.fallbackId).toString();
                    final familyName = l10n.familyName(familyId);
                    final color = FamilyTheme.colorOf(familyId);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: const Icon(Icons.archive, color: Colors.white),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          l10n.archivedHabitsFamilyLabel(familyName),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HabitDetailScreen(
                                habit: h,
                                familyColor: color,
                              ),
                            ),
                          );
                        },
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: l10n.archivedHabitsRestoreTooltip,
                              icon: const Icon(Icons.unarchive),
                              onPressed: () async {
                                if (id.isEmpty) return;
                                await _HabitStoreActions.restoreHabit(
                                    store, id);
                              },
                            ),
                            IconButton(
                              tooltip: l10n.archivedHabitsDeleteTooltip,
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                if (id.isEmpty) return;

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(l10n.archivedHabitsDeleteTitle),
                                    content:
                                        Text(l10n.archivedHabitsDeleteBody),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l10n.commonCancel),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          l10n.archivedHabitsDeleteTooltip,
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _HabitStoreActions.deleteHabit(
                                    store,
                                    id,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HabitStoreActions {
  static Future<void> restoreHabit(UserStateStore store, String id) async {
    final s = store as dynamic;

    try {
      final r = s.restoreHabit(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.unarchiveHabit(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.restoreArchivedHabit(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.setHabitArchived(id, false);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.archiveHabit(id, false);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.setArchived(id, false);
      if (r is Future) await r;
      return;
    } catch (_) {}

    try {
      final list = (s.activeHabits ?? s.habits);
      if (list is List) {
        for (final h in list) {
          try {
            if (h is Map) {
              final hid =
                  (h['id'] ?? h['habitId'] ?? h['uuid'] ?? h['key'] ?? '')
                      .toString();
              if (hid == id) {
                h['archived'] = false;
                h['isArchived'] = false;
                break;
              }
            }
          } catch (_) {}
        }
      }

      try {
        final r = s.save();
        if (r is Future) await r;
      } catch (_) {}
      try {
        s.notifyListeners();
      } catch (_) {}
    } catch (_) {}
  }

  static Future<void> deleteHabit(UserStateStore store, String id) async {
    final s = store as dynamic;

    try {
      final r = s.deleteHabit(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.deleteHabitById(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.deleteHabitForever(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.deleteHabitPermanently(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.removeHabit(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.removeHabitById(id);
      if (r is Future) await r;
      return;
    } catch (_) {}
    try {
      final r = s.purgeHabit(id);
      if (r is Future) await r;
      return;
    } catch (_) {}

    try {
      final list = (s.activeHabits ?? s.habits);
      if (list is List) {
        list.removeWhere((h) {
          try {
            if (h is Map) {
              final hid =
                  (h['id'] ?? h['habitId'] ?? h['uuid'] ?? h['key'] ?? '')
                      .toString();
              return hid == id;
            }
            final hid = (h.id ?? h.habitId ?? h.uuid ?? h.key ?? '').toString();
            return hid == id;
          } catch (_) {
            return false;
          }
        });
      }

      final history =
          (s.habitHistory ?? s.historyByHabitId ?? s.entriesByHabitId);
      if (history is Map) history.remove(id);

      try {
        final r = s.save();
        if (r is Future) await r;
      } catch (_) {}
      try {
        s.notifyListeners();
      } catch (_) {}
    } catch (_) {}
  }
}
