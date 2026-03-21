import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../widgets/scene_painters.dart';

class RutioBackdrop extends StatelessWidget {
  final bool isLogin;
  final String subtitle;
  final VoidCallback? onBack;

  const RutioBackdrop({
    super.key,
    required this.isLogin,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: AuthScenePainter(greenLevel: isLogin ? 0.0 : 1.0),
          ),
          Positioned(
            top: 17,
            left: 17,
            child: SafeArea(
              child: _CircleBackButton(
                onTap: onBack ?? () => Navigator.maybePop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _AuthBrand(subtitle: subtitle.toUpperCase()),
          ),
          Positioned(
            top: 20,
            right: 18,
            child: SafeArea(
              child: _ProgressDots(active: isLogin ? 0 : 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.56),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 14,
          color: AppColors.ink.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int active; // 0 or 1

  const _ProgressDots({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(left: 5),
          width: isActive ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: isActive ? 0.55 : 0.18),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  final String subtitle;

  const _AuthBrand({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('rutio', style: AppTextStyles.brandName),
        const SizedBox(height: 3),
        Text(subtitle, style: AppTextStyles.brandSub),
      ],
    );
  }
}
