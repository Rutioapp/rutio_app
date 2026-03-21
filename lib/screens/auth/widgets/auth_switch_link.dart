import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

class AuthSwitchLink extends StatelessWidget {
  final String prefix;
  final String linkText;
  final VoidCallback onTap;

  const AuthSwitchLink({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.authSwitch,
          children: [
            TextSpan(text: prefix),
            WidgetSpan(
              child: GestureDetector(
                onTap: onTap,
                child: Text(linkText, style: AppTextStyles.authSwitchLink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
