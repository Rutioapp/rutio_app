import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/app_header/app_header.dart';

class TodoTopBar extends StatelessWidget {
  const TodoTopBar({
    super.key,
    required this.onMenuTap,
    required this.title,
  });

  final VoidCallback onMenuTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // IOS-FIRST IMPROVEMENT START
          IgnorePointer(
            child: Text(
              title,
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
                      onTap: onMenuTap,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 104),
            ],
          ),
          // IOS-FIRST IMPROVEMENT END
        ],
      ),
    );
  }
}
