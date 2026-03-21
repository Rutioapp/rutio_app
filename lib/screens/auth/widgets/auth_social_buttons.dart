import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

class AuthSocialButtons extends StatelessWidget {
  final String dividerLabel;
  final String googleLabel;
  final String appleLabel;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  const AuthSocialButtons({
    super.key,
    required this.dividerLabel,
    required this.googleLabel,
    required this.appleLabel,
    this.onGoogle,
    this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DividerLabel(text: dividerLabel),
        const SizedBox(height: 14),
        _SocialButton(
          label: appleLabel,
          leading: const Icon(Icons.apple, size: 18),
          onTap: onApple,
        ),
        const SizedBox(height: 10),
        _SocialButton(
          label: googleLabel,
          leading: _GoogleMark(),
          onTap: onGoogle,
        ),
      ],
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String text;

  const _DividerLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Container(
                height: 1, color: AppColors.ink.withValues(alpha: 0.08))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text.toUpperCase(),
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.ink.withValues(alpha: 0.35),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
            child: Container(
                height: 1, color: AppColors.ink.withValues(alpha: 0.08))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(
              color: AppColors.ink.withValues(alpha: 0.18), width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.btnOutlineLabel,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
      ),
      child: Text(
        'G',
        style: AppTextStyles.btnOutlineLabel.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
