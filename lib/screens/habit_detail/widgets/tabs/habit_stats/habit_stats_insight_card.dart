part of '../habit_stats_tab.dart';

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F0E4), Color(0xFFF2EBDD)],
        ),
        border: Border.all(color: const Color(0x1A2A2118)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0x55FFECCB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.lightbulb_fill,
              color: Color(0xFFC0831E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: 36,
                    height: 0.96,
                    color: Color(0xFF2A2119),
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
