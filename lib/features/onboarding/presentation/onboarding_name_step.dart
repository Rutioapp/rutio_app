import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';

/// Real Name presenter for Phase 3A. It owns only transient editing state;
/// the confirmed value belongs to OnboardingDraft through the Coordinator.
class OnboardingNameStep extends StatefulWidget {
  const OnboardingNameStep({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    this.errorMessage,
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final String? errorMessage;

  @override
  OnboardingNameStepState createState() => OnboardingNameStepState();
}

class OnboardingNameStepState extends State<OnboardingNameStep> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void submit() => widget.onSubmit(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingNameTitle,
          style: AppTextStyles.welcomeTitle.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingNameSubtitle,
          style: AppTextStyles.welcomeSub.copyWith(
            color: AppColors.ink.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.name,
          autofillHints: const <String>[AutofillHints.name],
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(
            labelText: l10n.onboardingNameInputLabel,
            hintText: l10n.onboardingNameInputHint,
            errorText: widget.errorMessage,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
