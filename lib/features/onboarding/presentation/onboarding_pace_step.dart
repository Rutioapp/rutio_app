import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../domain/models/onboarding_types.dart';

/// Real Pace presenter. The selected value is transient until the Coordinator
/// confirms it through submitPace.
class OnboardingPaceStep extends StatefulWidget {
  const OnboardingPaceStep({
    super.key,
    required this.initialPace,
    required this.onSubmit,
    required this.onSelectionChanged,
    this.errorMessage,
  });

  final OnboardingPace? initialPace;
  final ValueChanged<OnboardingPace> onSubmit;
  final ValueChanged<OnboardingPace?> onSelectionChanged;
  final String? errorMessage;

  @override
  OnboardingPaceStepState createState() => OnboardingPaceStepState();
}

class OnboardingPaceStepState extends State<OnboardingPaceStep> {
  late OnboardingPace? _selected;
  late OnboardingPace? _confirmedSelection;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPace;
    _confirmedSelection = widget.initialPace;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSelectionChanged(_selected);
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingPaceStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPace != _confirmedSelection) {
      _selected = widget.initialPace;
      _confirmedSelection = widget.initialPace;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelectionChanged(_selected);
      });
    }
  }

  void submit() {
    final selected = _selected;
    if (selected != null) widget.onSubmit(selected);
  }

  void _select(OnboardingPace pace) {
    if (_selected == pace) return;
    setState(() => _selected = pace);
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingPaceTitle,
          style: AppTextStyles.welcomeTitle.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 12),
        ...OnboardingPace.values.indexed.expand((entry) {
          final index = entry.$1;
          final pace = entry.$2;
          return [
            _PaceOption(
              pace: pace,
              title: _titleFor(context, pace),
              description: _descriptionFor(context, pace),
              selected: _selected == pace,
              reduceMotion: reduceMotion,
              onTap: () => _select(pace),
            ),
            if (index < OnboardingPace.values.length - 1)
              const SizedBox(height: 12),
          ];
        }),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorMessage!,
              style: AppTextStyles.authSub.copyWith(
                color: AppColors.rust,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _titleFor(BuildContext context, OnboardingPace pace) {
    final l10n = context.l10n;
    switch (pace) {
      case OnboardingPace.gentle:
        return l10n.onboardingPaceGentleTitle;
      case OnboardingPace.balanced:
        return l10n.onboardingPaceBalancedTitle;
      case OnboardingPace.energized:
        return l10n.onboardingPaceEnergizedTitle;
    }
  }

  String _descriptionFor(BuildContext context, OnboardingPace pace) {
    final l10n = context.l10n;
    switch (pace) {
      case OnboardingPace.gentle:
        return l10n.onboardingPaceGentleDescription;
      case OnboardingPace.balanced:
        return l10n.onboardingPaceBalancedDescription;
      case OnboardingPace.energized:
        return l10n.onboardingPaceEnergizedDescription;
    }
  }
}

class _PaceOption extends StatelessWidget {
  const _PaceOption({
    required this.pace,
    required this.title,
    required this.description,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final OnboardingPace pace;
  final String title;
  final String description;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      selected: selected,
      label: '$title. $description',
      value: selected ? l10n.onboardingPaceSelected : null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.rust.withValues(alpha: 0.12)
                : AppColors.cream2.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.rust
                  : AppColors.ink.withValues(alpha: 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.rust
                      : AppColors.ink.withValues(alpha: 0.48),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.authSub.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.authSub.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
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
