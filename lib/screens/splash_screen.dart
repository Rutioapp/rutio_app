import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/loading/rutio_loading_screen.dart';

/// Compatibility entry point for the historical splash route.
/// The visual implementation is shared with bootstrap and onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onFinished,
    this.autoAdvanceDuration,
    this.enableTapToContinue = false,
    this.showTapHint = true,
    this.isOperationComplete = false,
    this.startJourney = true,
  });

  final VoidCallback? onFinished;
  final Duration? autoAdvanceDuration;
  final bool enableTapToContinue;
  final bool showTapHint;
  final bool isOperationComplete;
  final bool startJourney;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _autoAdvanceTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.autoAdvanceDuration;
    if (duration != null) _autoAdvanceTimer = Timer(duration, _goNext);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (_finished || !mounted) return;
    _finished = true;
    final callback = widget.onFinished;
    if (callback != null) {
      callback();
    } else if (widget.enableTapToContinue) {
      Navigator.of(context).pushReplacementNamed('/root');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enableTapToContinue ? _goNext : null,
      child: RutioLoadingScreen(
        isOperationComplete: widget.isOperationComplete,
        startJourney: widget.startJourney,
        onCompleted: _goNext,
      ),
    );
  }
}
