import 'package:flutter/material.dart';

class DiaryEntryDetailMeta extends StatelessWidget {
  const DiaryEntryDetailMeta({
    super.key,
    required this.leadingText,
    required this.trailingText,
  });

  final String leadingText;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            leadingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6F5E50),
            ),
          ),
        ),
        Text(
          trailingText,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF2A2119),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
