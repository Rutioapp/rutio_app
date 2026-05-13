part of '../habit_stats_tab.dart';

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.streakDays,
  });

  final String title;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD2A068), Color(0xFFB77E47), Color(0xFF6B4324)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -16,
            child: _GlowBlob(
              size: 110,
              color: const Color(0x70FFF6DC),
            ),
          ),
          Positioned(
            bottom: -26,
            left: -10,
            child: _GlowBlob(
              size: 140,
              color: const Color(0x2D2E170A),
            ),
          ),
          Positioned(
            bottom: -32,
            right: 10,
            child: _GlowBlob(
              size: 150,
              color: const Color(0x3527160C),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x46FFF6E2),
                    border: Border.all(
                      color: const Color(0xA6FFEED0),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.flame_fill,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 35,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF8F2E8),
                        ),
                      ),
                      Text(
                        l10n.habitStatsDaysLabel(streakDays),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.serifFamily,
                          fontSize: 60,
                          height: 0.95,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
