import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/presentation/global_wallet_ui_state.dart';

import '../../../l10n/l10n.dart';
import '../../../stores/user_state_store.dart';
import '../../../utils/app_theme.dart';

class StatsRow extends StatelessWidget {
  final int level;
  final int xp;
  final int coins;

  const StatsRow({
    super.key,
    required this.level,
    required this.xp,
    required this.coins,
  });

  factory StatsRow.fromStore(BuildContext context, UserStateStore store) {
    final state = store.state;
    final userState = (state?['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final progression =
        (userState['progression'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final wallet = (userState['wallet'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final xp = ((progression['xp'] as num?) ?? 0).toInt();
    final level = LevelProgression.fromTotalXp(xp).level;
    final coins = _resolveCoinsForUi(context, wallet);

    return StatsRow(level: level, xp: xp, coins: coins);
  }

  static int _resolveCoinsForUi(
    BuildContext context,
    Map<String, dynamic> wallet,
  ) {
    try {
      final walletController = context.watch<GlobalWalletController>();
      return walletController.resolveCoinsForUi(
        legacyCoinsBuilder: () => ((wallet['coins'] as num?) ?? 0).toInt(),
      );
    } catch (_) {
      return ((wallet['coins'] as num?) ?? 0).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.earth,
            label: context.l10n.editProfileStatLevel,
            value: '$level',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFC27A39),
            label: context.l10n.editProfileStatXp,
            value: '$xp',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.monetization_on_outlined,
            iconColor: const Color(0xFFAA8130),
            label: context.l10n.editProfileStatCoins,
            value: '$coins',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.earth.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x0F000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: AppTextStyles.serifFamily,
                fontSize: 22,
                height: 1,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
