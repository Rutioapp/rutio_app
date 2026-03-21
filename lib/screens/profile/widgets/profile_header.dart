import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'pill_button.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final Color accent;
  final String name;
  final String subtitle;
  final String? email;
  final ImageProvider? avatarImage;
  final VoidCallback onEdit;

  const ProfileHeader({
    super.key,
    required this.accent,
    required this.name,
    required this.subtitle,
    required this.email,
    required this.avatarImage,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(accent: accent, image: avatarImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                    height: 1.2,
                  ),
                ),
                if (email != null && email!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    email!.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillButton(
            accent: accent,
            icon: Icons.edit,
            label: context.l10n.profileEditButton,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}
