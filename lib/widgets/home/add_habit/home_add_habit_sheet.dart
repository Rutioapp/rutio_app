import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/family_theme.dart';

import 'package:rutio/screens/home/services/home_catalog_service.dart';
import 'package:rutio/screens/home/ui/create_habit_screen.dart';
import 'package:rutio/widgets/common/top_toast.dart';

import 'home_add_habit_families_row.dart';
import 'habit_pills_list.dart';
import 'habit_target_config_sheet.dart';

/// Launcher del bottom sheet (usado por Home FAB / botón "+").
Future<void> showHomeAddHabitSheet(BuildContext context) {
  final rootContext = context;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // IOS-FIRST IMPROVEMENT START
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    // IOS-FIRST IMPROVEMENT END
    builder: (_) => HomeAddHabitSheet(rootContext: rootContext),
  );
}

/// Bottom sheet to add a habit from catalog or create a custom one.
class HomeAddHabitSheet extends StatefulWidget {
  const HomeAddHabitSheet({super.key, required this.rootContext});

  final BuildContext rootContext;

  @override
  State<HomeAddHabitSheet> createState() => _HomeAddHabitSheetState();
}

class _HomeAddHabitSheetState extends State<HomeAddHabitSheet> {
  final _service = HomeCatalogService();
  late final Future<Map<String, dynamic>> _catalogFuture;

  final ScrollController _familyScroll = ScrollController();
  final Map<String, GlobalKey> _familyKeys = <String, GlobalKey>{};

  String _selectedFamilyId = FamilyTheme.fallbackId;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _service.loadCatalog();
  }

  @override
  void dispose() {
    _familyScroll.dispose();
    super.dispose();
  }

  bool _needsTarget(String type) {
    final t = type.toLowerCase();
    return t == 'count' || t == 'counter' || t == 'count_or_check';
  }

  Future<HabitTargetConfigResult?> _askTargetAndSchedule(
    BuildContext context,
    Map<String, dynamic> h,
  ) {
    return showHabitTargetConfigSheet(context: context, habitDef: h);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _catalogFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 340,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError || snap.data == null) {
                return SizedBox(
                  height: 340,
                  child:
                      Center(child: Text(context.l10n.homeAddHabitLoadError)),
                );
              }

              final catalog = snap.data!;

              final families = (catalog['families'] as List? ?? const [])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();

              final familyIdSet = families
                  .map((f) => (f['id'] ?? '').toString())
                  .where((id) => id.isNotEmpty)
                  .toSet();

              for (final id in familyIdSet) {
                _familyKeys.putIfAbsent(id, () => GlobalKey());
              }

              final ordered =
                  FamilyTheme.order.where(familyIdSet.contains).toList();
              final remaining = familyIdSet.difference(ordered.toSet()).toList()
                ..sort();
              final orderedFamilyIds = <String>[...ordered, ...remaining];

              if (!familyIdSet.contains(_selectedFamilyId)) {
                _selectedFamilyId = orderedFamilyIds.isNotEmpty
                    ? orderedFamilyIds.first
                    : FamilyTheme.fallbackId;
              }

              Map<String, dynamic>? selectedFamily;
              for (final f in families) {
                if ((f['id'] ?? '').toString() == _selectedFamilyId) {
                  selectedFamily = f;
                  break;
                }
              }

              final habits = (selectedFamily?['habits'] as List? ?? const [])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
              final rootState = context.watch<UserStateStore>().state;
              final userState =
                  (rootState != null && rootState['userState'] is Map)
                      ? (rootState['userState'] as Map).cast<String, dynamic>()
                      : <String, dynamic>{};
              final activeHabits =
                  (userState['activeHabits'] as List? ?? const [])
                      .whereType<Map>()
                      .map((e) => e.cast<String, dynamic>())
                      .toList();
              final activeIds = activeHabits
                  .map((h) => (h['id'] ?? '').toString())
                  .where((s) => s.isNotEmpty)
                  .toSet();

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeAddHabitFamiliesRow(
                      familyIds: orderedFamilyIds,
                      selectedId: _selectedFamilyId,
                      controller: _familyScroll,
                      itemKeys: _familyKeys,
                      onSelected: (id) {
                        setState(() => _selectedFamilyId = id);

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final key = _familyKeys[id];
                          final chipCtx = key?.currentContext;
                          if (chipCtx != null) {
                            Scrollable.ensureVisible(
                              chipCtx,
                              alignment: 0.5,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Builder(
                          builder: (ctx2) {
                            final familyColor =
                                FamilyTheme.colorOf(_selectedFamilyId);
                            return HabitPillsList(
                              habits: habits,
                              color: familyColor,
                              disabledIds: activeIds,
                              onHabitTap: (h, name, type) async {
                                final store = context.read<UserStateStore>();
                                final selectedFamilyId = _selectedFamilyId;
                                num? target;
                                String scheduleType = 'daily';
                                String? scheduledDate;
                                List<int>? weekdays;
                                Map<String, dynamic> habitDefToAdd = h;

                                if (_needsTarget(type)) {
                                  final res =
                                      await _askTargetAndSchedule(context, h);
                                  if (res == null) return;

                                  scheduleType = res.scheduleType;
                                  scheduledDate = res.scheduledDate;
                                  weekdays = res.weekdays;

                                  if (type.toLowerCase() == 'count_or_check') {
                                    habitDefToAdd = <String, dynamic>{
                                      ...h,
                                      'type': res.type
                                    };
                                  }

                                  target = res.target;
                                }

                                await store.addHabitFromCatalog(
                                  habitDef: habitDefToAdd,
                                  familyId: selectedFamilyId,
                                  target: target,
                                  scheduleType: scheduleType,
                                  scheduledDate: scheduledDate,
                                  weekdays: weekdays,
                                );

                                if (!mounted || !widget.rootContext.mounted) {
                                  return;
                                }

                                final l10n = context.l10n;
                                final localizedName = l10n.catalogHabitName(
                                  (habitDefToAdd['id'] ?? h['id'] ?? '')
                                      .toString(),
                                  target: target,
                                  preferTemplate: target != null,
                                  fallback: (habitDefToAdd['name'] ??
                                          habitDefToAdd['title'] ??
                                          h['name'] ??
                                          l10n.homeFallbackHabitTitle)
                                      .toString(),
                                );
                                showTopToast(
                                  widget.rootContext,
                                  message:
                                      l10n.homeAddHabitCreated(localizedName),
                                );
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label:
                              Text(context.l10n.homeAddHabitCreateFromScratch),
                          onPressed: () async {
                            final selectedFamilyId = _selectedFamilyId;
                            final created =
                                await Navigator.of(context).push<bool>(
                              CupertinoPageRoute(
                                builder: (_) => CreateHabitScreen(
                                  initialFamilyId: selectedFamilyId,
                                ),
                              ),
                            );

                            if (created != true ||
                                !mounted ||
                                !widget.rootContext.mounted) {
                              return;
                            }

                            showTopToast(
                              widget.rootContext,
                              message: context.l10n.homeAddHabitCreatedGeneric,
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
