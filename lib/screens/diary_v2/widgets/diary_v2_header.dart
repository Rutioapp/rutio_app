import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/app_header/app_header.dart';

import 'diary_v2_styles.dart';

class DiaryV2Header extends StatelessWidget {
  static const Color _statisticsTitleColor = Color(0xFF725038);

  const DiaryV2Header({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onMenuTap,
    this.onAllEntriesTap,
    this.allEntriesTooltip,
  });

  final String title;
  final String subtitle;
  final VoidCallback onMenuTap;
  final VoidCallback? onAllEntriesTap;
  final String? allEntriesTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppDrawerButton(
                    tooltip: context.l10n.diaryMenuTooltip,
                    color: _statisticsTitleColor,
                    onTap: onMenuTap,
                  ),
                ),
                if (onAllEntriesTap != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _HeaderActionButton(
                      icon: Icons.notes_outlined,
                      color: _statisticsTitleColor,
                      tooltip: allEntriesTooltip ?? '',
                      onTap: onAllEntriesTap!,
                    ),
                  ),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authTitle.copyWith(
                      fontSize: 34,
                      color: _statisticsTitleColor,
                      letterSpacing: -0.8,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DiaryV2Styles.mutedText,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: color.withValues(alpha: 0.82),
          ),
        ),
      ),
    );

    if (tooltip.isNotEmpty) {
      child = Tooltip(message: tooltip, child: child);
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: child,
    );
  }
}
