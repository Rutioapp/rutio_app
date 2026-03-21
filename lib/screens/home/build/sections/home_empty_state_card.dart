part of 'package:rutio/screens/home/home_screen.dart';

class HomeEmptyStateCard extends StatelessWidget {
  const HomeEmptyStateCard({
    super.key,
    required this.onPrimaryAction,
  });

  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final message = context.l10n.homeEmptyStateMultiline.replaceAll('`n', '\n');

    // IOS-FIRST IMPROVEMENT START
    return IosFrostedCard(
      elevated: true,
      padding: const EdgeInsets.all(IosSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(IosCornerRadius.chip),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.sparkles,
              color: primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(height: IosSpacing.md),
          Text(
            context.l10n.homeEmptyStateSingleLine,
            style: IosTypography.title(context),
          ),
          const SizedBox(height: IosSpacing.xs),
          Text(
            message,
            style: IosTypography.body(context),
          ),
          const SizedBox(height: IosSpacing.lg),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: IosSpacing.md,
              vertical: IosSpacing.sm,
            ),
            color: primaryDark,
            borderRadius: BorderRadius.circular(IosCornerRadius.control),
            onPressed: onPrimaryAction,
            child: Text(context.l10n.createHabitNewHabitTitle),
          ),
        ],
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }
}
