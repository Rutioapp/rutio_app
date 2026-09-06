import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../domain/models/onboarding_reminder_configuration.dart';
import '../domain/models/onboarding_types.dart';

class OnboardingReminderStep extends StatefulWidget {
  const OnboardingReminderStep({
    super.key,
    required this.initialConfiguration,
    required this.onSubmit,
    required this.onDecisionChanged,
    this.errorMessage,
  });

  final OnboardingReminderConfiguration initialConfiguration;
  final ValueChanged<OnboardingReminderConfiguration> onSubmit;
  final ValueChanged<bool> onDecisionChanged;
  final String? errorMessage;

  @override
  State<OnboardingReminderStep> createState() => OnboardingReminderStepState();
}

class OnboardingReminderStepState extends State<OnboardingReminderStep> {
  late OnboardingReminderTime _time;
  late bool _enabled;
  late bool _decisionMade;

  @override
  void initState() {
    super.initState();
    _time = widget.initialConfiguration.selectedTime ??
        const OnboardingReminderTime(hour: 8, minute: 0);
    _enabled = widget.initialConfiguration.enabled;
    _decisionMade = widget.initialConfiguration.schedulingState !=
        ReminderSchedulingState.notRequested;
  }

  void submit() {
    if (!_decisionMade) return;
    widget.onSubmit(
      _enabled
          ? OnboardingReminderConfiguration.pending(selectedTime: _time)
          : OnboardingReminderConfiguration.disabled(
              permissionState: widget.initialConfiguration.permissionState ==
                      ReminderPermissionState.notRequested
                  ? ReminderPermissionState.notRequested
                  : widget.initialConfiguration.permissionState,
            ),
    );
  }

  void _setDecision(bool enabled) {
    setState(() {
      _enabled = enabled;
      _decisionMade = true;
    });
    widget.onDecisionChanged(true);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final selected = await showModalBottomSheet<OnboardingReminderTime>(
      context: context,
      builder: (context) {
        var value = DateTime(
          now.year,
          now.month,
          now.day,
          _time.hour,
          _time.minute,
        );
        return SafeArea(
          child: SizedBox(
            height: 310,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      OnboardingReminderTime(
                        hour: value.hour,
                        minute: value.minute,
                      ),
                    ),
                    child: Text(context.l10n.onboardingReminderTimeDone),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                    initialDateTime: value,
                    onDateTimeChanged: (next) => value = next,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _time = selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayedTime = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: _time.hour, minute: _time.minute),
    );
    final permissionState = widget.initialConfiguration.permissionState;
    final permissionWarning = permissionState == ReminderPermissionState.denied
        ? l10n.onboardingReminderPermissionDenied
        : permissionState == ReminderPermissionState.restricted
            ? l10n.onboardingReminderPermissionRestricted
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboardingReminderSupport, style: AppTextStyles.welcomeSub),
        const SizedBox(height: 22),
        Semantics(
          button: true,
          selected: _enabled && _decisionMade,
          label: l10n.onboardingReminderEnable,
          child: OutlinedButton.icon(
            key: const ValueKey('onboardingReminderEnable'),
            onPressed: () => _setDecision(true),
            icon: const Icon(CupertinoIcons.bell),
            label: Text(l10n.onboardingReminderEnable),
          ),
        ),
        if (_enabled && _decisionMade) ...[
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: '${l10n.onboardingReminderTime}: $displayedTime',
            child: InkWell(
              key: const ValueKey('onboardingReminderTime'),
              borderRadius: BorderRadius.circular(18),
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.clock),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.onboardingReminderTime)),
                    Text(
                      displayedTime,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        TextButton(
          key: const ValueKey('onboardingReminderNotNow'),
          onPressed: () {
            _setDecision(false);
            widget.onSubmit(
              OnboardingReminderConfiguration.disabled(
                permissionState:
                    permissionState == ReminderPermissionState.notRequested
                        ? ReminderPermissionState.notRequested
                        : permissionState,
              ),
            );
          },
          child: Text(l10n.onboardingReminderNotNow),
        ),
        if (permissionWarning != null) ...[
          const SizedBox(height: 14),
          Text(
            permissionWarning,
            key: const ValueKey('onboardingReminderPermissionWarning'),
            style: AppTextStyles.authSub.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.errorMessage!,
            style: AppTextStyles.authSub.copyWith(
              color: AppColors.rust,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
