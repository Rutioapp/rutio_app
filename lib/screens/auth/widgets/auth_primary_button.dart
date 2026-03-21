import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.btnLabel,
        ).copyWith(
          overlayColor:
              WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(label),
      ),
    );
  }
}
