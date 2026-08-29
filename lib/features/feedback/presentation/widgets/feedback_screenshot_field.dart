import 'package:flutter/material.dart';

import '../../../../utils/app_theme.dart';

class FeedbackScreenshotField extends StatelessWidget {
  const FeedbackScreenshotField({
    super.key,
    required this.title,
    required this.placeholderLabel,
    this.onTap,
  });

  final String title;
  final String placeholderLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.fieldLabel.copyWith(
            color: AppColors.earth,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          button: interactive,
          label: title,
          child: Material(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 98),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.earthSoft.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.sage,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        placeholderLabel,
                        style: AppTextStyles.authSub.copyWith(
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (interactive) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFB49F83),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
