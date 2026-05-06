import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/app_header/app_header.dart';

class StatisticsV3Header extends StatelessWidget {
  const StatisticsV3Header({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isHabitView,
    required this.onToggleView,
    required this.onMenuTap,
  });

  final String title;
  final String subtitle;
  final bool isHabitView;
  final VoidCallback onToggleView;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    const actionColor = Color(0xFF6C4022);

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Semantics(
              label: '$title. $subtitle',
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.authTitle.copyWith(
                  fontSize: 28,
                  color: const Color(0xFF725038),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 104,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: AppDrawerButton(
                      tooltip: context.l10n.diaryMenuTooltip,
                      color: const Color(0xFF725038),
                      boxSize: 44,
                      onTap: onMenuTap,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 104,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onToggleView,
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isHabitView
                            ? actionColor.withValues(alpha: 0.13)
                            : Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isHabitView
                              ? actionColor.withValues(alpha: 0.36)
                              : const Color(0xFFE8E2D8),
                        ),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 18,
                        color: isHabitView
                            ? actionColor
                            : const Color(0xFF6A5A47),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
