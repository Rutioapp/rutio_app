import 'package:flutter/material.dart';

class DiaryEntryDetailBody extends StatelessWidget {
  const DiaryEntryDetailBody({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF2A2119),
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
