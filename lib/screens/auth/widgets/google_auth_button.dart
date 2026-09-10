import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({required this.label, required this.onTap, this.isLoading = false, super.key});

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null && !isLoading,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: BorderSide(color: AppColors.ink.withValues(alpha: .16)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
