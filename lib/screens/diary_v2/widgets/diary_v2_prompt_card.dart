import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2PromptCard extends StatelessWidget {
  const DiaryV2PromptCard({
    super.key,
    required this.title,
    required this.prompt,
    this.onTap,
  });

  final String title;
  final String prompt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DiaryV2Styles.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DiaryV2Styles.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      color: DiaryV2Styles.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: DiaryV2Styles.title(context).copyWith(fontSize: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  prompt,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DiaryV2Styles.textStrong,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: DiaryV2Styles.accent),
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_right,
                      color: DiaryV2Styles.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
