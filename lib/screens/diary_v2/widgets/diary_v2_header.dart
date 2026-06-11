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
  });

  final String title;
  final String subtitle;
  final VoidCallback onMenuTap;

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
