part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenHeaderBuilders on _HomeScreenState {
  Widget _statsHeader({
    required BuildContext context,
    required String username,
    required int level,
    required int xp,
    required int xpToNext,
    required int coins,
    required String? avatarUrl,
  }) {
    final double denom = (xp + xpToNext).toDouble();
    final double xpValue = (denom <= 0) ? 0.0 : (xp / denom).clamp(0.0, 1.0);
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
          child: IosFrostedCard(
            padding: const EdgeInsets.symmetric(
              horizontal: IosSpacing.sm,
              vertical: IosSpacing.xxs,
            ),
            borderRadius: BorderRadius.circular(20),
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
                      _applyHomeState(() => _selectedDay = newDay);
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
    required int done,
    required int total,
  }) {
    // IOS-FIRST IMPROVEMENT START
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: IosSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: IosTypography.title(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ),
          Text(
            context.l10n.homeCompletedLabel,
            style: IosTypography.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              '$done/$total',
              key: ValueKey('$done/$total'),
              style: IosTypography.title(context).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }

  Widget _completedHeader({required int count}) {
    return _HomeSectionToggle(
      icon: CupertinoIcons.check_mark_circled_solid,
      title: context.l10n.homeCompletedCount(count.toString()),
      isExpanded: _showCompleted,
      onTap: () => _applyHomeState(() => _showCompleted = !_showCompleted),
    );
  }
}

// IOS-FIRST IMPROVEMENT START
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
