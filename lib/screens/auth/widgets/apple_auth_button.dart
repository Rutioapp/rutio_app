import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthButton extends StatelessWidget {
  const AppleAuthButton(
      {required this.label,
      required this.onTap,
      this.isLoading = false,
      super.key});
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null && !isLoading,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: SignInWithAppleButton(
          onPressed: isLoading ? null : onTap,
          text: label,
          style: SignInWithAppleButtonStyle.black,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
