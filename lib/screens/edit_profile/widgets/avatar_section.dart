import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';

class AvatarSection extends StatelessWidget {
  const AvatarSection({
    super.key,
    required this.avatarPath,
    required this.nameCtrl,
    required this.goalCtrl,
    required this.onTap,
  });

  final ValueListenable<String> avatarPath;
  final TextEditingController nameCtrl;
  final TextEditingController goalCtrl;
  final VoidCallback onTap;

  static const _cardRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: Listenable.merge([avatarPath, nameCtrl, goalCtrl]),
      builder: (context, _) {
        final name = nameCtrl.text.trim().isNotEmpty
            ? nameCtrl.text.trim()
            : l10n.editProfileHeaderNameFallback;
        final goal = goalCtrl.text.trim().isNotEmpty
            ? goalCtrl.text.trim()
            : l10n.editProfileHeaderGoalFallback;
        final path = avatarPath.value.trim();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: AppColors.earth.withValues(alpha: 0.10)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 22,
                offset: Offset(0, 12),
                color: Color(0x10000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.editProfilePreviewSectionLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.earth,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    key: const Key('editProfileAvatarButton'),
                    onTap: onTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cream,
                              width: 4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 14,
                                offset: Offset(0, 8),
                                color: Color(0x16000000),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: path.isNotEmpty
                                ? Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const _AvatarFallback(),
                                  )
                                : const _AvatarFallback(),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 4,
                          child: Material(
                            color: AppColors.earth,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onTap,
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  color: AppColors.cream,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          key: const Key('editProfilePreviewName'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.spa_outlined,
                              size: 16,
                              color: AppColors.earth,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                goal,
                                key: const Key('editProfilePreviewGoal'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.25,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream2,
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 48,
          color: AppColors.earth,
        ),
      ),
    );
  }
}
