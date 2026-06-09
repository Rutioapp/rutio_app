import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';

import 'diary_v2_styles.dart';

class DiaryV2Header extends StatelessWidget {
  const DiaryV2Header({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onMenuTap,
    this.onSearchTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onMenuTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleButton(
            tooltip: context.l10n.diaryMenuTooltip,
            icon: CupertinoIcons.line_horizontal_3,
            onTap: onMenuTap,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.authTitle.copyWith(
                      fontSize: 34,
                      color: DiaryV2Styles.textStrong,
                      letterSpacing: -0.8,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DiaryV2Styles.mutedText,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          _CircleButton(
            icon: CupertinoIcons.search,
            onTap: onSearchTap,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 52,
      height: 52,
      decoration: DiaryV2Styles.softButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Icon(
            icon,
            color: DiaryV2Styles.text,
            size: 23,
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}
