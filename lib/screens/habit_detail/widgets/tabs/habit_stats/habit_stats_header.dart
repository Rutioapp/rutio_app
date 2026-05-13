part of '../habit_stats_tab.dart';

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.familyColor,
    required this.onBack,
    required this.onMorePressed,
  });

  final String title;
  final String subtitle;
  final Color familyColor;
  final VoidCallback onBack;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CircleButton(
              icon: CupertinoIcons.back,
              onPressed: onBack,
            ),
            const Spacer(),
            if (onMorePressed != null)
              _CircleButton(
                icon: CupertinoIcons.ellipsis,
                onPressed: onMorePressed!,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.serifFamily,
            fontSize: 56,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2D1A0F),
            letterSpacing: -0.8,
            height: 0.98,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: familyColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppTextStyles.sansFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A5650),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3EA),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1A2B2014)),
        ),
        child: Icon(icon, color: const Color(0xFF3D2819), size: 20),
      ),
    );
  }
}
