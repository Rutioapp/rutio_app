import 'package:flutter/material.dart';

class HabitStatsHeader extends StatelessWidget {
  final String title;
  final String familyAndObjective;
  final Color familyColor;
  final bool showControls;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMorePressed;

  const HabitStatsHeader({
    super.key,
    required this.title,
    required this.familyAndObjective,
    required this.familyColor,
    this.showControls = false,
    this.onBackPressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = title.trim();
    final titleLength = trimmedTitle.length;
    final titleFontSize = titleLength >= 24
        ? 32.0
        : titleLength >= 14
            ? 34.0
            : 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showControls)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBackPressed,
                ),
                const Spacer(),
                _CircleIconButton(
                  icon: Icons.more_horiz_rounded,
                  onPressed: onMorePressed,
                ),
              ],
            ),
          ),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: titleFontSize,
                height: 0.98,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.55,
                color: const Color(0xFF2B1A10),
                fontFamily: 'Georgia',
              ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: familyColor.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                familyAndObjective,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF645648),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleIconButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCF8F0),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEAE0D3)),
          ),
          child: Icon(icon, color: const Color(0xFF4A3426), size: 16),
        ),
      ),
    );
  }
}
