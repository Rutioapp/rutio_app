import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';

class FeedbackSuccessScreen extends StatelessWidget {
  const FeedbackSuccessScreen({super.key});

  static const route = '/feedback/success';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.feedbackSuccessTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.earthSoft.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: AppColors.sage,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.feedbackSuccessTitle,
                      style: AppTextStyles.welcomeTitle.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.feedbackSuccessBody,
                      style: AppTextStyles.welcomeSub.copyWith(
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.feedbackSuccessReturnAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
