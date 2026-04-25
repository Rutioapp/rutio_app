import 'package:flutter/cupertino.dart';

import '../../../../utils/app_theme.dart';

class AchievementsPageHeader extends StatelessWidget {
  const AchievementsPageHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8DCC8),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              CupertinoIcons.back,
              size: 18,
              color: Color(0xFF4A3425),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppTextStyles.serifFamily,
                fontSize: 25,
                letterSpacing: -0.4,
                color: Color(0xFF412B1E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }
}
