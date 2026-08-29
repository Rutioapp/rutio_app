import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';

class FeedbackResponseCard extends StatelessWidget {
  const FeedbackResponseCard({
    super.key,
    required this.response,
  });

  final String? response;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasResponse = response?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.earthSoft.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: AppColors.sage,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.feedbackResponseTitle,
                  style: AppTextStyles.authTitle.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasResponse ? response!.trim() : l10n.feedbackResponseEmpty,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
