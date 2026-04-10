import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../ui/foundations/ios_foundations.dart';

class OnboardingAvatarPlaceholder extends StatelessWidget {
  const OnboardingAvatarPlaceholder({
    super.key,
    this.size = 56,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFF0E7D8),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size - IosSpacing.lg,
        height: size - IosSpacing.lg,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.earth.withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.sparkles,
          size: 18,
          color: AppColors.earth,
        ),
      ),
    );
  }
}
