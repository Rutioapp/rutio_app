import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/app_header/app_header.dart';
import '../components/diary_header_icon_button.dart';

class DiaryScreenHeader extends StatelessWidget {
  const DiaryScreenHeader({
    super.key,
    required this.searchOpen,
    required this.onSearchTap,
    required this.onFiltersTap,
  });

  final bool searchOpen;
  final VoidCallback onSearchTap;
  final VoidCallback onFiltersTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Text(
              context.l10n.diaryTitle,
              style: AppTextStyles.authTitle.copyWith(
                fontSize: 30,
                color: const Color(0xFF725038),
                letterSpacing: -0.5,
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
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 104,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DiaryHeaderIconButton(
                      icon: searchOpen
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      tooltip: searchOpen
                          ? context.l10n.diaryCloseSearchTooltip
                          : context.l10n.diarySearchTooltip,
                      onTap: onSearchTap,
                    ),
                    const SizedBox(width: 8),
                    DiaryHeaderIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: context.l10n.diaryFiltersTooltip,
                      onTap: onFiltersTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
