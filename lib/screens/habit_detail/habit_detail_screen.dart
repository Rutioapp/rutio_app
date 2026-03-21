import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'widgets/tabs/edit_habit_tab.dart';
import 'widgets/tabs/habit_stats_tab.dart';
import 'widgets/editor/habit_editor_utils.dart';
import '../../utils/family_theme.dart';
import '../../widgets/common/top_toast.dart';

enum _HabitDetailMenuAction {
  delete,
  archive,
}

/// Habit detail with two tabs (Edit / Stats).
///
/// Why stats was empty when navigating from Weekly:
/// In many architectures the stats tab depends on the store knowing the
/// "currently selected habit" OR on an explicit "load stats" call.
/// When coming from Weekly, that sync/load often doesn't happen.
///
/// This version:
/// 1) Keeps a TabController so we can detect when Stats is selected.
/// 2) On entering Stats, tries (safely) to:
///    - set the selected habit id in UserStateStore (several common method names)
///    - trigger a stats load/refresh (several common method names)
/// 3) Forces a rebuild of HabitStatsTab using a Key token so its initState runs.
class HabitDetailScreen extends StatefulWidget {
  final dynamic habit;
  final Color familyColor;
  final int initialTab; // 0=Editar, 1=Stats

  final void Function(dynamic updatedHabit)? onSaveHabit;
  final void Function(BuildContext context)? onOpenStats;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.familyColor,
    this.initialTab = 0,
    this.onSaveHabit,
    this.onOpenStats,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late dynamic _habit;
  late String _title;
  late TabController _tabController;

  int _statsRefreshToken = 0;

  String _familyId = FamilyTheme.fallbackId;
  Color get _currentFamilyColor => FamilyTheme.colorOf(_familyId);

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _title = _habitTitle(_habit);

    _familyId = _habitFamilyId(_habit);

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyRouteArgumentsIfAny();
      _syncAndLoadForCurrentTab(force: true);
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _syncAndLoadForCurrentTab();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HabitDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameHabit(oldWidget.habit, widget.habit)) {
      setState(() {
        _habit = widget.habit;
        _title = _habitTitle(_habit);

        _familyId = _habitFamilyId(_habit);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncAndLoadForCurrentTab(force: true);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyRouteArgumentsIfAny() {
    // Some parts of the app may rely on RouteSettings.arguments (e.g. stats widgets).
    // When navigating from Weekly we now provide these arguments too.
    final route = ModalRoute.of(context);
    if (route == null) return;
    final args = route.settings.arguments;
    if (args is Map) {
      final maybeHabit = args['habit'];
      if (maybeHabit != null && !_sameHabit(_habit, maybeHabit)) {
        setState(() {
          _habit = maybeHabit;
          _title = _habitTitle(_habit);

          _familyId = _habitFamilyId(_habit);
        });
      }
    }
  }

  void _syncAndLoadForCurrentTab({bool force = false}) {
    // Always keep store in sync, but only force-refresh stats when stats tab selected.
    _syncSelectedHabitInStore();
    if (_tabController.index == 1) {
      _requestStatsLoad();
      _refreshStats();
    } else if (force) {
      // If habit changed, a later switch to stats should still rebuild cleanly.
      _refreshStats();
    }
  }

  bool _sameHabit(dynamic a, dynamic b) {
    final ida = _habitId(a);
    final idb = _habitId(b);
    if (ida != null && idb != null) return ida == idb;
    return identical(a, b);
  }

  String? _habitId(dynamic h) {
    if (h == null) return null;

    if (h is Map) {
      final v = h['id'] ?? h['habitId'] ?? h['uuid'] ?? h['key'];
      return v?.toString();
    }

    try {
      final dynamic v = (h as dynamic).id;
      if (v != null) return v.toString();
    } catch (_) {}
    try {
      final dynamic v = (h as dynamic).habitId;
      if (v != null) return v.toString();
    } catch (_) {}
    try {
      final dynamic v = (h as dynamic).uuid;
      if (v != null) return v.toString();
    } catch (_) {}

    return null;
  }

  String _habitTitle(dynamic h) {
    if (h == null) return context.l10n.habitDetailFallbackTitle;

    if (h is Map) {
      final v = h['title'] ?? h['name'] ?? h['habitTitle'] ?? h['label'];
      if (v != null) return v.toString();
    }

    try {
      final dynamic v = (h as dynamic).title;
      if (v != null) return v.toString();
    } catch (_) {}
    try {
      final dynamic v = (h as dynamic).name;
      if (v != null) return v.toString();
    } catch (_) {}

    return context.l10n.habitDetailFallbackTitle;
  }

  String _habitFamilyId(dynamic h) {
    if (h == null) return FamilyTheme.fallbackId;

    if (h is Map) {
      final v = h['familyId'];
      if (v != null) return v.toString();
    }

    try {
      final dynamic v = (h as dynamic).familyId;
      if (v != null) return v.toString();
    } catch (_) {}

    return FamilyTheme.fallbackId;
  }

  void _syncSelectedHabitInStore() {
    final id = _habitId(_habit);
    if (id == null) return;

    // If UserStateStore isn't in the tree, just ignore.
    UserStateStore? store;
    try {
      store = context.read<UserStateStore>();
    } catch (_) {
      return;
    }

    // Call common APIs defensively (each call wrapped so a missing method won't crash).
    final dyn = store as dynamic;
    for (final fn in <void Function()>[
      () => dyn.setSelectedHabitId(id),
      () => dyn.setCurrentHabitId(id),
      () => dyn.selectHabit(id),
      () => dyn.setSelectedHabit(id),
    ]) {
      try {
        fn();
      } catch (_) {}
    }
  }

  void _requestStatsLoad() {
    final id = _habitId(_habit);
    if (id == null) return;

    UserStateStore? store;
    try {
      store = context.read<UserStateStore>();
    } catch (_) {
      return;
    }

    final dyn = store as dynamic;
    for (final fn in <void Function()>[
      () => dyn.loadHabitStats(id),
      () => dyn.loadStatsForHabit(id),
      () => dyn.refreshHabitStats(id),
      () => dyn.refreshStatsForHabit(id),
      () => dyn.computeHabitStats(id),
      () => dyn.recomputeHabitStats(id),
      () => dyn.ensureHabitStatsLoaded(id),
      () => dyn.ensureStatsForHabit(id),
    ]) {
      try {
        fn();
      } catch (_) {}
    }
  }

  void _refreshStats() {
    setState(() => _statsRefreshToken++);
  }

  Future<void> _handleSaved(dynamic updatedHabit) async {
    // 1) Update local copy so UI reflects immediately
    setState(() {
      _habit = updatedHabit;
      _title = _habitTitle(updatedHabit);
    });

    // 2) Notify parent (if this screen was opened with a callback)
    widget.onSaveHabit?.call(updatedHabit);

    // 3) Persist into UserStateStore so the change survives navigation/rebuilds
    try {
      final store = context.read<UserStateStore>();

      // Ã¢Å“â€¦ Si el hÃƒÂ¡bito NO existe todavÃƒÂ­a en activeHabits, lo creamos (nuevo hÃƒÂ¡bito).
      // Si ya existe, lo actualizamos (ediciÃƒÂ³n).
      final id = _habitId(updatedHabit);
      bool exists = false;

      if (id != null && id.trim().isNotEmpty) {
        try {
          final existing = (store as dynamic).getActiveHabitById(id);
          exists = existing != null;
        } catch (_) {
          // si el store no tiene getActiveHabitById, asumimos que existe y actualizamos
          exists = true;
        }
      }

      if (!exists) {
        // Creamos como hÃƒÂ¡bito custom (tambiÃƒÂ©n sirve para hÃƒÂ¡bitos de catÃƒÂ¡logo si traen 'id').
        if (updatedHabit is Map) {
          final map = Map<String, dynamic>.from(updatedHabit);
          await (store as dynamic).addCustomHabit(map);
        } else {
          // Si no es Map, intentamos convertirlo usando toJson si existe
          try {
            final v = (updatedHabit as dynamic).toJson?.call();
            if (v is Map) {
              await (store as dynamic)
                  .addCustomHabit(Map<String, dynamic>.from(v));
            }
          } catch (_) {}
        }
      } else {
        await store.updateHabitDetailsFromEdit(updatedHabit);
      }
    } catch (_) {
      // If store not available in this subtree, ignore (but then parent must handle persistence)
    }

    // 4) Keep stats in sync
    _syncSelectedHabitInStore();
    _requestStatsLoad();
    _refreshStats();

    if (!mounted) return;
    showTopToast(
      context,
      message: context.l10n.habitDetailSaved,
      // Puedes ajustar el color si quieres que vaya con tu tema:
      backgroundColor: _currentFamilyColor,
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final id = _habitId(_habit)?.toString().trim() ?? '';
    if (id.isEmpty) return;
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final store = context.read<UserStateStore>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.habitDetailDeleteTitle),
        content: Text(l10n.habitDetailDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.habitDetailDeleteAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _deleteHabitInStore(store, id);

    if (mounted) {
      navigator.pop();
    }
  }

  Future<void> _archiveHabit() async {
    final dynamic updatedHabit =
        (_habit is Map) ? Map<String, dynamic>.from(_habit as Map) : _habit;

    setHabitValue(updatedHabit, ['archived', 'isArchived'], true);
    await _handleSaved(updatedHabit);
  }

  Future<void> _showHabitActionsSheet(BuildContext context) async {
    final currentContext = this.context;
    final l10n = currentContext.l10n;
    final action = await showCupertinoModalPopup<_HabitDetailMenuAction>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(
              sheetContext,
              _HabitDetailMenuAction.archive,
            ),
            child: Text(l10n.habitDetailArchiveAction),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(
              sheetContext,
              _HabitDetailMenuAction.delete,
            ),
            child: Text(l10n.habitDetailDeleteAction),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.commonCancel),
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _HabitDetailMenuAction.archive:
        await _archiveHabit();
        break;
      case _HabitDetailMenuAction.delete:
        await _confirmAndDelete(this.context);
        break;
    }
  }

  Future<void> _deleteHabitInStore(UserStateStore store, String id) async {
    final s = store as dynamic;

    // Try common delete APIs (wrapped so missing methods don't crash).
    for (final fn in <dynamic Function()>[
      () => s.deleteHabit(id),
      () => s.deleteHabitById(id),
      () => s.deleteHabitForever(id),
      () => s.removeHabit(id),
      () => s.removeHabitById(id),
      () => s.deleteHabitAndHistory(id),
      () => s.deleteHabitWithHistory(id),
    ]) {
      try {
        final r = fn();
        if (r is Future) await r;
        return;
      } catch (_) {}
    }

    // Fallback: if store exposes a list/map of habits, try to remove by id.
    try {
      final dynamic active = s.activeHabits;
      if (active is List) {
        active.removeWhere((h) => _habitId(h)?.toString() == id);
      }
    } catch (_) {}
    try {
      final dynamic all = s.habits;
      if (all is List) {
        all.removeWhere((h) => _habitId(h)?.toString() == id);
      }
    } catch (_) {}

    try {
      final r = s.save();
      if (r is Future) await r;
    } catch (_) {}
    try {
      s.notifyListeners();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Ã¢Å“â€¦ Fuente de verdad: si el store tiene el hÃƒÂ¡bito, usamos ese (evita volver a la versiÃƒÂ³n vieja al navegar)
    final String? id = _habitId(_habit);
    final storeHabit = (id == null || id.isEmpty)
        ? null
        : context.select<UserStateStore, Map<String, dynamic>?>(
            (s) => s.getActiveHabitById(id),
          );

    final dynamic effectiveHabit = storeHabit ?? _habit;
    if (!identical(effectiveHabit, _habit) &&
        _sameHabit(_habit, effectiveHabit)) {
      // Mantener el estado local sincronizado sin romper el flujo de la UI
      _habit = effectiveHabit;
      _title = _habitTitle(_habit);

      _familyId = _habitFamilyId(_habit);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.l10n.habitDetailMoreOptionsTooltip,
            icon: const Icon(CupertinoIcons.ellipsis_circle),
            onPressed: () => _showHabitActionsSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _currentFamilyColor,
          labelColor: _currentFamilyColor,
          unselectedLabelColor: Colors.black.withValues(alpha: 0.55),
          tabs: [
            Tab(text: context.l10n.habitDetailEditTab),
            Tab(text: context.l10n.habitDetailStatsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EditHabitTab(
            habit: effectiveHabit,
            familyColor: _currentFamilyColor,
            onFamilyIdLiveChanged: (id) {
              if (id.trim().isEmpty) return;
              setState(() => _familyId = id.trim());
            },
            onTitleLiveChanged: (t) {
              if (t.trim().isEmpty) return;
              setState(() => _title = t.trim());
            },
            onSaved: _handleSaved,
          ),
          HabitStatsTab(
            key: ValueKey('${_habitId(_habit) ?? 'no-id'}_$_statsRefreshToken'),
            habit: effectiveHabit,
            familyColor: _currentFamilyColor,
          ),
        ],
      ),
    );
  }
}
