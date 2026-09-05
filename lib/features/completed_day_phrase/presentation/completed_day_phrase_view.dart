import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../ui/foundations/ios_foundations.dart';
import '../application/completed_day_phrase_controller.dart';
import '../domain/completed_day_eligibility.dart';

/// Lightweight Home host. It never renders the controller's resolving state.
class CompletedDayPhraseHost extends StatefulWidget {
  const CompletedDayPhraseHost({
    super.key,
    required this.controller,
    required this.eligibility,
    required this.input,
  });

  final CompletedDayPhraseController controller;
  final CompletedDayEligibility eligibility;
  final CompletedDayPhraseInput input;

  @override
  State<CompletedDayPhraseHost> createState() => _CompletedDayPhraseHostState();
}

class _CompletedDayPhraseHostState extends State<CompletedDayPhraseHost> {
  bool? _lastPresentationWasVisible;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant CompletedDayPhraseHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.eligibility != widget.eligibility ||
        _inputChanged(oldWidget.input, widget.input)) {
      _resolve();
    }
  }

  void _resolve() {
    widget.controller.resolve(
      eligibility: widget.eligibility,
      input: widget.input,
    );
  }

  bool _inputChanged(
    CompletedDayPhraseInput oldInput,
    CompletedDayPhraseInput newInput,
  ) {
    return oldInput.userId != newInput.userId ||
        !_sameLocalDate(oldInput.localDate, newInput.localDate) ||
        oldInput.locale != newInput.locale ||
        oldInput.name != newInput.name ||
        oldInput.streak != newInput.streak ||
        oldInput.streakLabel != newInput.streakLabel;
  }

  bool _sameLocalDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final phrase = widget.controller.state.phrase;
        final isVisible = widget.controller.state.isVisible && phrase != null;
        if (kDebugMode && _lastPresentationWasVisible != isVisible) {
          _lastPresentationWasVisible = isVisible;
          debugPrint(
            '[COMPLETED_DAY_PHRASE] presentation=${isVisible ? 'visible' : 'hidden'}',
          );
        }
        if (!isVisible) {
          return const SizedBox.shrink();
        }
        return CompletedDayPhraseView(
          text: phrase.text,
          author: phrase.phrase.author,
        );
      },
    );
  }
}

class CompletedDayPhraseView extends StatelessWidget {
  const CompletedDayPhraseView({
    super.key,
    required this.text,
    this.author,
  });

  final String text;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final normalizedAuthor = author?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: IosSpacing.md,
        vertical: IosSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: IosTypography.body(context),
          ),
          if (normalizedAuthor != null && normalizedAuthor.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: IosSpacing.xxs),
              child: Text(
                normalizedAuthor,
                textAlign: TextAlign.center,
                style: IosTypography.caption(context),
              ),
            ),
        ],
      ),
    );
  }
}
