import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class SectionCard extends StatelessWidget {
  final Widget child;

  const SectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}
