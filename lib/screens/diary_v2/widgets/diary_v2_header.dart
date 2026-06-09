import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/app_header/app_header.dart';

import 'diary_v2_styles.dart';

class DiaryV2Header extends StatelessWidget {
  const DiaryV2Header({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onMenuTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      left: AppDrawerButton(
        tooltip: context.l10n.diaryMenuTooltip,
        color: DiaryV2Styles.text,
        onTap: onMenuTap,
      ),
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.authTitle.copyWith(
              fontSize: 32,
              color: DiaryV2Styles.text,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DiaryV2Styles.mutedText,
            ),
          ),
        ],
      ),
      right: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: const Icon(
          CupertinoIcons.search,
          color: DiaryV2Styles.text,
          size: 20,
        ),
      ),
    );
  }
}
