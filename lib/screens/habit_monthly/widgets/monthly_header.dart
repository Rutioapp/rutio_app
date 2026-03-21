import 'package:flutter/material.dart';

import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_monthly/utils/monthly_state_utils.dart';
import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/app_header/user_stats_card.dart';

class MonthlyHeader extends StatelessWidget {
  final String title;
  final MonthlyHeaderVM vm;
  final VoidCallback onProfileTap;

  const MonthlyHeader({
    super.key,
    required this.title,
    required this.vm,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        return Container(
          color: ColorPalette.bg,
          child: AppHeader(
            left: AppDrawerButton(
              tooltip: ctx.l10n.monthlyMenuTooltip,
              color: ColorPalette.textPrimary,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
            center: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColorPalette.textPrimary,
              ),
            ),
            right: UserStatsCard(
              username: vm.username,
              level: vm.level,
              xpValue: vm.xpValue,
              coins: vm.coins,
              onTap: onProfileTap,
              primaryDark: const Color(0xFF4B2BFF),
              compact: true,
            ),
          ),
        );
      },
    );
  }
}
