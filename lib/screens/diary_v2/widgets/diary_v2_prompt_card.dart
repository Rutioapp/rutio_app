import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2PromptCard extends StatelessWidget {
  const DiaryV2PromptCard({
    super.key,
    required this.title,
    required this.prompt,
  });

  final String title;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
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
                  style: DiaryV2Styles.title(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            prompt,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: DiaryV2Styles.text,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
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
    );
  }
}
