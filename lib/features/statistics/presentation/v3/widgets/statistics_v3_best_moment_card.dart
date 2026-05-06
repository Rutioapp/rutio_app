import 'package:flutter/material.dart';

class StatisticsV3BestMomentCard extends StatelessWidget {
  const StatisticsV3BestMomentCard({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E3D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 70,
              height: 44,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: const Color(0xFFF8EFD9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 7),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 22,
                  color: Color(0xFFC78922),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F463A),
            ),
          ),
        ],
      ),
    );
  }
}
