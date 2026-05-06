import 'package:flutter/material.dart';

class StatisticsV3ProgressMessageChip extends StatelessWidget {
  const StatisticsV3ProgressMessageChip({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.46)),
        ),
        child: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A5A47),
          ),
        ),
      ),
    );
  }
}
