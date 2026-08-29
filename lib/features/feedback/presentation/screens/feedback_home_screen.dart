import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';
import '../widgets/feedback_action_tile.dart';

class FeedbackHomeScreen extends StatelessWidget {
  const FeedbackHomeScreen({super.key});

  static const route = '/feedback';

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
        title: Text(l10n.feedbackTitle),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFDFBF5),
                            Color(0xFFF0E6D2),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.earthSoft.withValues(alpha: 0.16),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 20,
                            offset: Offset(0, 10),
                            color: Color(0x11000000),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              color: AppColors.sage,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.feedbackTitle,
                            style: AppTextStyles.welcomeTitle.copyWith(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.feedbackIntro,
                            style: AppTextStyles.welcomeSub.copyWith(
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FeedbackActionTile(
                      title: l10n.feedbackSendAction,
                      subtitle: l10n.feedbackSendActionSubtitle,
                      icon: Icons.edit_note_rounded,
                      tint: AppColors.earth,
                      onTap: () => Navigator.of(context).pushNamed(
                        '/feedback/new',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FeedbackActionTile(
                      title: l10n.feedbackMineAction,
                      subtitle: l10n.feedbackMineActionSubtitle,
                      icon: Icons.inbox_outlined,
                      tint: AppColors.sage,
                      onTap: () => Navigator.of(context).pushNamed(
                        '/feedback/mine',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
