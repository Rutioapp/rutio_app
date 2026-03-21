import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiaryEntryDetailTopBar extends StatelessWidget {
  const DiaryEntryDetailTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 6),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: onBack,
            child: const Icon(
              CupertinoIcons.back,
              size: 28,
              color: Color(0xFF2A2119),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF2A2119),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
