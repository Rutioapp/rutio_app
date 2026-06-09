import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2EditorWriteCard extends StatelessWidget {
  const DiaryV2EditorWriteCard({
    super.key,
    required this.title,
    required this.helperText,
    required this.controller,
    required this.currentLength,
    required this.maxLength,
  });

  final String title;
  final String helperText;
  final TextEditingController controller;
  final int currentLength;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      constraints: const BoxConstraints(minHeight: 300),
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u201c',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: DiaryV2Styles.accent,
                  fontSize: 30,
                  height: 0.9,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: DiaryV2Styles.title(context).copyWith(
              fontSize: 18,
              color: DiaryV2Styles.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DiaryV2Styles.mutedTextStrong,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 7,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontSize: 17,
                  height: 1.62,
                ),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$currentLength / $maxLength',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DiaryV2Styles.mutedText,
                    fontSize: 12,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
