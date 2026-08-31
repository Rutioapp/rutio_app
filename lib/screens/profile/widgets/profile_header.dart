import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../l10n/l10n.dart';
import 'pill_button.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final Color accent;
  final String name;
  final String? note;
  final String? goal;
  final ImageProvider? avatarImage;
  final VoidCallback onEdit;

  const ProfileHeader({
    super.key,
    required this.accent,
    required this.name,
    required this.note,
    required this.goal,
    required this.avatarImage,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final noteText = (note ?? '').trim();
    final goalText = (goal ?? '').trim();
    final secondaryText = noteText.isNotEmpty
        ? noteText
        : goalText.isNotEmpty
            ? goalText
            : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.earth.withValues(alpha: 0.12)),
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
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (secondaryText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
