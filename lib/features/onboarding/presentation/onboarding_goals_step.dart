import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../domain/onboarding_goals.dart';

/// Real Goals presenter. Selection is transient until the Coordinator
/// confirms it through submitGoals.
class OnboardingGoalsStep extends StatefulWidget {
  const OnboardingGoalsStep({
    super.key,
    required this.initialGoalCodes,
    required this.onSubmit,
    required this.onSelectionChanged,
    this.errorMessage,
  });

  final Set<String> initialGoalCodes;
  final ValueChanged<Set<String>> onSubmit;
  final ValueChanged<Set<String>> onSelectionChanged;
  final String? errorMessage;

  @override
  OnboardingGoalsStepState createState() => OnboardingGoalsStepState();
}

class OnboardingGoalsStepState extends State<OnboardingGoalsStep> {
  late Set<String> _selected;
  late Set<String> _confirmedSelection;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.of(widget.initialGoalCodes);
    _confirmedSelection = Set<String>.of(widget.initialGoalCodes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSelectionChanged(_snapshot());
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingGoalsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = Set<String>.of(widget.initialGoalCodes);
    if (!_sameSet(incoming, _confirmedSelection)) {
      _selected = incoming;
      _confirmedSelection = incoming;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelectionChanged(_snapshot());
      });
    }
  }

  void submit() => widget.onSubmit(_snapshot());

  Set<String> _snapshot() => Set<String>.unmodifiable(_selected);

  void _toggle(String code) {
    final isSelected = _selected.contains(code);
    if (!isSelected && _selected.length >= 3) return;
    setState(() {
      if (isSelected) {
        _selected.remove(code);
      } else {
        _selected.add(code);
      }
    });
    widget.onSelectionChanged(_snapshot());
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
          l10n.onboardingGoalsTitle,
          style: AppTextStyles.welcomeTitle.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingGoalsSubtitle,
          style: AppTextStyles.welcomeSub.copyWith(
            color: AppColors.ink.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 24),
        ...OnboardingGoalCatalog.definitions.indexed.expand((entry) {
          final index = entry.$1;
          final goal = entry.$2;
          return [
            _GoalOption(
              goal: goal,
              label: _labelFor(context, goal),
              selected: _selected.contains(goal.code),
              disabled: !_selected.contains(goal.code) && _selected.length >= 3,
              reduceMotion: reduceMotion,
              onTap: () => _toggle(goal.code),
            ),
            if (index < OnboardingGoalCatalog.definitions.length - 1)
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

  String _labelFor(BuildContext context, OnboardingGoalDefinition goal) {
    final l10n = context.l10n;
    switch (goal.localizationKey) {
      case 'onboardingGoalCareBody':
        return l10n.onboardingGoalCareBody;
      case 'onboardingGoalFindCalm':
        return l10n.onboardingGoalFindCalm;
      case 'onboardingGoalOrganizeDays':
        return l10n.onboardingGoalOrganizeDays;
      case 'onboardingGoalLearnGrow':
        return l10n.onboardingGoalLearnGrow;
      case 'onboardingGoalCareRelationships':
        return l10n.onboardingGoalCareRelationships;
      case 'onboardingGoalBuildDiscipline':
        return l10n.onboardingGoalBuildDiscipline;
      default:
        return goal.code;
    }
  }

  bool _sameSet(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.goal,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.reduceMotion,
    required this.onTap,
  });

  final OnboardingGoalDefinition goal;
  final String label;
  final bool selected;
  final bool disabled;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stateDescription = selected
        ? l10n.onboardingGoalSelected
        : disabled
            ? l10n.onboardingGoalUnavailable
            : null;
    return Semantics(
      container: true,
      button: true,
      enabled: !disabled,
      toggled: selected,
      label: label,
      value: stateDescription,
      onTap: disabled ? null : onTap,
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
                : AppColors.cream2.withValues(alpha: disabled ? 0.34 : 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.rust
                  : AppColors.ink.withValues(alpha: disabled ? 0.05 : 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.rust
                      : AppColors.ink.withValues(alpha: disabled ? 0.28 : 0.48),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.authSub.copyWith(
                      color: AppColors.ink.withValues(
                        alpha: disabled ? 0.42 : 0.90,
                      ),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
