import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../stores/user_state_store.dart';

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

  factory StatsRow.fromStore(UserStateStore store) {
    final state = store.state;
    final userState = (state?['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final progression =
        (userState['progression'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final wallet = (userState['wallet'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final xp = ((progression['xp'] as num?) ?? 0).toInt();
    final level = ((progression['level'] as num?) ?? (1 + (xp ~/ 100))).toInt();
    final coins = ((wallet['coins'] as num?) ?? 0).toInt();

    return StatsRow(level: level, xp: xp, coins: coins);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: context.l10n.editProfileStatLevel,
              value: '$level',
              icon: Icons.emoji_events_rounded,
            ),
          ),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(
            child: _Stat(
              label: context.l10n.editProfileStatXp,
              value: '$xp',
              icon: Icons.bolt_rounded,
            ),
          ),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(
            child: _Stat(
              label: context.l10n.editProfileStatCoins,
              value: '$coins',
              icon: Icons.paid_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
