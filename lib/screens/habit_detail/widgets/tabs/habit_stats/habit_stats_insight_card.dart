import 'package:flutter/cupertino.dart';

import '../../../../../utils/app_theme.dart';

class HabitStatsInsightCard extends StatelessWidget {
  const HabitStatsInsightCard({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1E2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEDDCA)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF5E5C8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.lightbulb,
              color: Color(0xFFD38B22),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight',
                  style: TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22201D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: 45,
                    fontStyle: FontStyle.italic,
                    height: 1.02,
                    color: Color(0xFF2D241D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
