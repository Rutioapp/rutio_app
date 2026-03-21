import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'profile_option_tile.dart';

class DangerZone extends StatelessWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onDeleteData;

  const DangerZone({
    super.key,
    this.onLogout,
    this.onDeleteData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.profileDangerZoneTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ProfileOptionTile(
          icon: Icons.logout,
          title: context.l10n.profileLogoutTitle,
          subtitle: context.l10n.profileLogoutSubtitle,
          iconColor: const Color(0xFFE67E22),
          onTap: onLogout,
        ),
        const SizedBox(height: 10),
        ProfileOptionTile(
          icon: Icons.delete_forever,
          title: context.l10n.profileDeleteDataTitle,
          subtitle: context.l10n.profileDeleteDataSubtitle,
          iconColor: const Color(0xFFE74C3C),
          onTap: onDeleteData,
        ),
      ],
    );
  }
}
