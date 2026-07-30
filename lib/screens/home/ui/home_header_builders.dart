part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenHeaderBuilders on _HomeScreenState {
  Future<void> _showHabitStatusFilterMenu(
    HomeViewData homeData,
    BuildContext anchorContext,
  ) async {
    final selectedFilter = await showHomeHabitStatusFilterMenu(
      context: context,
      anchorContext: anchorContext,
      selectedFilter: _habitStatusFilter,
      pendingCount: homeData.pendingHabits.length,
      completedCount: homeData.completedHabits.length,
      skippedCount: homeData.skippedHabits.length,
    );
    if (selectedFilter == null) return;

    _selectHabitStatusFilter(selectedFilter);
  }

  Widget _statsHeader({
    required BuildContext context,
    required String username,
    required int level,
    required double xpProgress,
    required int coins,
    required String? avatarUrl,
  }) {
    final double xpValue = xpProgress.clamp(0.0, 1.0).toDouble();
    final double width = MediaQuery.of(context).size.width;
    final bool compact = width < 390;

    // IOS-FIRST IMPROVEMENT START
    return AppHeader(
      height: compact ? 56 : 60,
      padding: EdgeInsets.zero,
      left: AppDrawerButton(
        onTap: () => _openViewMenu(context),
      ),
      center: const SizedBox.shrink(),
      right: SizedBox(
        width: compact ? 222 : 248,
        child: Align(
          alignment: Alignment.centerRight,
          child: UserIdentityRow(
            username: username,
            level: level,
            coins: coins,
            xpProgress: xpValue,
            avatarUrl: avatarUrl,
            onTap: () async {
              await IosFeedback.lightImpact();
              if (!context.mounted) return;
              _openProfileFromHome(
                context,
                openEditProfileOnLoad: true,
                useCupertinoRoute: true,
              );
            },
          ),
        ),
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }

  Widget _weekStrip() {
    final double w = MediaQuery.of(context).size.width;
    final bool veryCompact = w < 360;
    final bool compact = w < 420;

    final double height = veryCompact ? 82 : (compact ? 76 : 72);
    final double dayFont = veryCompact ? 11 : 12;
    final double numFont = veryCompact ? 13 : 14;

    final DateTime monday = _onlyDate(_selectedDay)
        .subtract(Duration(days: _selectedDay.weekday - DateTime.monday));
    final days =
        List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));

    // IOS-FIRST IMPROVEMENT START
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(IosCornerRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: IosSpacing.xs,
            vertical: IosSpacing.xs,
          ),
          child: Row(
            children: [
              for (final d in days)
                Expanded(
                  child: HomeDayChip(
                    day: d,
                    selected: _onlyDate(d) == _onlyDate(_selectedDay),
                    primaryDark: primaryDark,
                    dayFont: dayFont,
                    numFont: numFont,
                    onTap: () {
                      final newDay = _onlyDate(d);
                      IosFeedback.selection();
                      _applyHomeState(() {
                        _selectedDay = newDay;
                        _habitCompletionTransitions.clear();
                      });
                      context.read<UserStateStore>().setActiveViewDate(newDay);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }

  Widget _dayProgressMini({
    required String label,
    required ValueChanged<BuildContext> onOpenHabitStatusFilter,
  }) {
    // IOS-FIRST IMPROVEMENT START
    return HomeDayProgressFilterRow(
      label: label,
      onOpenFilter: onOpenHabitStatusFilter,
    );
    // IOS-FIRST IMPROVEMENT END
  }

  // ignore: unused_element
  Widget _completedHeader({required int count}) {
    // Obsoleto desde Fase 6C: se conserva temporalmente para facilitar retiro
    // posterior, pero ya no se pasa al arbol de Habit Cards.
    return _HomeSectionToggle(
      icon: CupertinoIcons.check_mark_circled_solid,
      title: context.l10n.homeCompletedCount(count.toString()),
      isExpanded: _showCompleted,
      onTap: () => _applyHomeState(() => _showCompleted = !_showCompleted),
    );
  }
}

// IOS-FIRST IMPROVEMENT START
class HomeDayProgressFilterRow extends StatelessWidget {
  const HomeDayProgressFilterRow({
    super.key,
    required this.label,
    required this.onOpenFilter,
  });

  final String label;
  final ValueChanged<BuildContext> onOpenFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: IosSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              key: const Key('homeDayProgressDateLabel'),
              style: IosTypography.title(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ),
          HomeHabitStatusFilterButton(onOpenFilter: onOpenFilter),
        ],
      ),
    );
  }
}

class HomeHabitStatusFilterButton extends StatelessWidget {
  const HomeHabitStatusFilterButton({
    super.key,
    required this.onOpenFilter,
  });

  final ValueChanged<BuildContext> onOpenFilter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Cambiar filtro de hábitos',
      onTap: () => onOpenFilter(context),
      child: Tooltip(
        message: 'Cambiar filtro de hábitos',
        child: CupertinoButton(
          key: const Key('homeHabitStatusFilterButton'),
          minimumSize: const Size.square(44),
          padding: EdgeInsets.zero,
          onPressed: () {
            IosFeedback.selection();
            onOpenFilter(context);
          },
          child: Icon(
            CupertinoIcons.ellipsis,
            size: 24,
            color: Colors.black.withValues(alpha: 0.62),
          ),
        ),
      ),
    );
  }
}

class HomeHabitStatusFilterHeader extends StatelessWidget {
  const HomeHabitStatusFilterHeader({
    super.key,
    required this.selectedFilter,
    required this.pendingCount,
    required this.completedCount,
    required this.skippedCount,
    required this.onOpenFilter,
  });

  final HomeHabitStatusFilter selectedFilter;
  final int pendingCount;
  final int completedCount;
  final int skippedCount;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final title = selectedFilter.title;
    final count = selectedFilter.countFrom(
      pending: pendingCount,
      completed: completedCount,
      skipped: skippedCount,
    );

    return IosFrostedCard(
      padding: const EdgeInsets.fromLTRB(
        IosSpacing.md,
        IosSpacing.xs,
        IosSpacing.xs,
        IosSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '$title · $count',
                key: ValueKey(
                    'habit_filter_header_${selectedFilter.name}_$count'),
                style: IosTypography.body(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Cambiar filtro de hábitos',
            onTap: onOpenFilter,
            child: Tooltip(
              message: 'Cambiar filtro de hábitos',
              child: CupertinoButton(
                key: const Key('obsoleteHomeHabitStatusFilterHeaderButton'),
                minimumSize: const Size.square(44),
                padding: EdgeInsets.zero,
                onPressed: () {
                  IosFeedback.selection();
                  onOpenFilter();
                },
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 24,
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeHabitFilterEmptyState extends StatelessWidget {
  const HomeHabitFilterEmptyState({
    super.key,
    required this.selectedFilter,
  });

  final HomeHabitStatusFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Text(
          selectedFilter.emptyMessage,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
Future<HomeHabitStatusFilter?> showHomeHabitStatusFilterMenu({
  required BuildContext context,
  required BuildContext anchorContext,
  required HomeHabitStatusFilter selectedFilter,
  required int pendingCount,
  required int completedCount,
  required int skippedCount,
}) {
  final buttonBox = anchorContext.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (buttonBox == null ||
      overlayBox == null ||
      !buttonBox.hasSize ||
      !overlayBox.hasSize) {
    return Future<HomeHabitStatusFilter?>.value();
  }

  final buttonTopLeft = buttonBox.localToGlobal(
    Offset.zero,
    ancestor: overlayBox,
  );
  final buttonRect = buttonTopLeft & buttonBox.size;
  final overlayRect = Offset.zero & overlayBox.size;
  final availableLeft = overlayBox.size.width - 8;
  final menuRight = buttonRect.right.clamp(8.0, availableLeft).toDouble();
  final menuLeft = (menuRight - 240).clamp(8.0, availableLeft).toDouble();
  final safeTop = MediaQuery.paddingOf(context).top + 8;
  final menuTop =
      buttonRect.bottom + 4 < safeTop ? safeTop : buttonRect.bottom + 4;
  final anchorRect = Rect.fromLTRB(menuLeft, menuTop, menuRight, menuTop);

  return showMenu<HomeHabitStatusFilter>(
    context: context,
    position: RelativeRect.fromRect(anchorRect, overlayRect),
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(IosCornerRadius.card),
    ),
    constraints: const BoxConstraints(minWidth: 210, maxWidth: 260),
    items: [
      for (final filter in HomeHabitStatusFilter.values)
        PopupMenuItem<HomeHabitStatusFilter>(
          value: filter,
          onTap: IosFeedback.selection,
          padding: EdgeInsets.zero,
          height: 48,
          child: _HomeHabitStatusFilterMenuItem(
            filter: filter,
            count: filter.countFrom(
              pending: pendingCount,
              completed: completedCount,
              skipped: skippedCount,
            ),
            selected: filter == selectedFilter,
          ),
        ),
    ],
  );
}

class _HomeHabitStatusFilterMenuItem extends StatelessWidget {
  const _HomeHabitStatusFilterMenuItem({
    required this.filter,
    required this.count,
    required this.selected,
  });

  final HomeHabitStatusFilter filter;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accentColor = selected ? primaryDark : Colors.black;

    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: '${filter.title}, $count hábitos',
      child: Container(
        color: selected ? primary.withValues(alpha: 0.10) : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: IosSpacing.md,
          vertical: IosSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                filter.title,
                style: IosTypography.body(context).copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: accentColor.withValues(alpha: 0.78),
                ),
              ),
            ),
            Text(
              count.toString(),
              style: IosTypography.body(context).copyWith(
                fontWeight: FontWeight.w800,
                color: accentColor.withValues(alpha: 0.64),
              ),
            ),
            const SizedBox(width: IosSpacing.sm),
            SizedBox(
              width: 22,
              child: selected
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: 18,
                      color: primaryDark,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

extension HomeHabitStatusFilterPresentation on HomeHabitStatusFilter {
  String get title {
    return switch (this) {
      HomeHabitStatusFilter.pending => 'Pendientes',
      HomeHabitStatusFilter.completed => 'Completados',
      HomeHabitStatusFilter.skipped => 'Saltados',
    };
  }

  String get emptyMessage {
    return switch (this) {
      HomeHabitStatusFilter.pending => 'No tienes hábitos pendientes.',
      HomeHabitStatusFilter.completed => 'Aún no has completado hábitos hoy.',
      HomeHabitStatusFilter.skipped => 'No has saltado hábitos hoy.',
    };
  }

  int countFrom({
    required int pending,
    required int completed,
    required int skipped,
  }) {
    return switch (this) {
      HomeHabitStatusFilter.pending => pending,
      HomeHabitStatusFilter.completed => completed,
      HomeHabitStatusFilter.skipped => skipped,
    };
  }
}

class _HomeSectionToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;

  const _HomeSectionToggle({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(IosCornerRadius.card),
        onTap: () {
          IosFeedback.selection();
          onTap();
        },
        child: IosFrostedCard(
          padding: const EdgeInsets.symmetric(
            horizontal: IosSpacing.md,
            vertical: IosSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              const SizedBox(width: IosSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: IosTypography.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.78),
                  ),
                ),
              ),
              Icon(
                isExpanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 16,
                color: Colors.black.withValues(alpha: 0.52),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// IOS-FIRST IMPROVEMENT END
