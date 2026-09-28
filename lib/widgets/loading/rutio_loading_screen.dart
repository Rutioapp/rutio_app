import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../shared_widgets.dart';

/// Visual phase of the shared Rutio loading journey.
/// The real bootstrap operation remains the source of truth outside this UI.
enum RutioLoadingPhase { progressing, waiting, completing, completed }

/// Returns the center position of the sun on its 0° → 180° semi-ellipse.
/// Coordinates are relative to the loading layer's local canvas.
Offset rutioLoadingSunPosition(
  Size size,
  double progress, {
  double sunSize = 0,
}) {
  final normalizedProgress = progress.clamp(0.0, 1.0);
  const radiusYFactor = 0.28;
  const baselineFactor = 0.68;
  const desiredSidePadding = 12.0;
  final centerX = size.width * 0.50;
  final baselineY = size.height * baselineFactor;
  final horizontalMargin = math.min(
    sunSize / 2 + desiredSidePadding,
    size.width / 2,
  );
  final radiusX = (size.width - horizontalMargin * 2) / 2;
  final radiusY = size.height * radiusYFactor;
  final angle = _rutioLoadingEllipseAngleForProgress(
    normalizedProgress,
    radiusX: radiusX,
    radiusY: radiusY,
  );
  return Offset(
    centerX - radiusX * math.cos(angle),
    baselineY - radiusY * math.sin(angle),
  );
}

/// Maps progress to distance travelled along the semi-ellipse instead of to
/// its angle. This keeps the sun's visual speed approximately constant.
double _rutioLoadingEllipseAngleForProgress(
  double progress, {
  required double radiusX,
  required double radiusY,
}) {
  const sampleCount = 96;
  if (progress <= 0) return 0;
  if (progress >= 1) return math.pi;

  final cumulativeLengths = List<double>.filled(sampleCount + 1, 0);
  for (var index = 1; index <= sampleCount; index++) {
    final previousAngle = math.pi * (index - 1) / sampleCount;
    final angle = math.pi * index / sampleCount;
    final deltaX = radiusX * (math.cos(angle) - math.cos(previousAngle));
    final deltaY = radiusY * (math.sin(angle) - math.sin(previousAngle));
    cumulativeLengths[index] = cumulativeLengths[index - 1] +
        math.sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  final targetLength = cumulativeLengths[sampleCount] * progress;
  var lower = 0;
  var upper = sampleCount;
  while (lower + 1 < upper) {
    final middle = (lower + upper) ~/ 2;
    if (cumulativeLengths[middle] < targetLength) {
      lower = middle;
    } else {
      upper = middle;
    }
  }

  final segmentLength = cumulativeLengths[upper] - cumulativeLengths[lower];
  final segmentProgress = segmentLength == 0
      ? 0.0
      : (targetLength - cumulativeLengths[lower]) / segmentLength;
  final lowerAngle = math.pi * lower / sampleCount;
  final upperAngle = math.pi * upper / sampleCount;
  return lowerAngle + (upperAngle - lowerAngle) * segmentProgress;
}

/// Purely visual sun. Position and animation belong to its parent.
class RutioSun extends StatelessWidget {
  const RutioSun({
    super.key,
    required this.size,
    this.rayColor = const Color(0xACAC7C20),
    this.fillColor = const Color(0x70F0C648),
  });

  final double size;
  final Color rayColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SunPainter(rayColor: rayColor, fillColor: fillColor),
      ),
    );
  }
}

class RutioLoadingScreen extends StatefulWidget {
  const RutioLoadingScreen({
    super.key,
    this.title = 'Preparando mi Rutio',
    this.subtitle = 'Estamos dejando todo listo para ti',
    this.isOperationComplete = false,
    this.errorMessage,
    this.onRetry,
    this.onCompleted,
    this.initialProgress = 0,
    this.startJourney = true,
    this.minimumVisibleDuration = _RutioLoadingTimings.minimumVisible,
  });

  final String title;
  final String subtitle;
  final bool isOperationComplete;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCompleted;
  final double initialProgress;
  final bool startJourney;
  final Duration minimumVisibleDuration;

  @override
  State<RutioLoadingScreen> createState() => _RutioLoadingScreenState();
}

class _RutioLoadingTimings {
  const _RutioLoadingTimings._();

  static const progressDuration = Duration(milliseconds: 5000);
  static const completionDuration = Duration(milliseconds: 650);
  static const completedHoldDuration = Duration(milliseconds: 420);
  static const exitDuration = Duration(milliseconds: 240);
  static const minimumVisible = Duration(milliseconds: 1600);
}

class _RutioLoadingScreenState extends State<RutioLoadingScreen>
    with TickerProviderStateMixin {
  static const _journeyLimit = 1.0;

  late final AnimationController _journeyController;
  late final AnimationController _ambientController;
  Timer? _completionTimer;
  Timer? _minimumVisibleTimer;
  RutioLoadingPhase _phase = RutioLoadingPhase.progressing;
  bool _completionRequested = false;
  bool _completionStarted = false;
  bool _completionCallbackSent = false;
  bool _isExiting = false;
  bool _minimumVisibleElapsed = false;
  bool _journeyStartScheduled = false;
  bool _journeyStarted = false;

  RutioLoadingPhase get phase => _phase;

  @override
  void initState() {
    super.initState();
    _journeyController = AnimationController(
      vsync: this,
      duration: _RutioLoadingTimings.progressDuration,
      value: widget.initialProgress.clamp(0.0, _journeyLimit),
    )..addListener(_onJourneyTick);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    _scheduleMinimumVisibleTimer();
    if (widget.isOperationComplete) _requestCompletion();
  }

  @override
  void didUpdateWidget(covariant RutioLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorMessage != null && widget.errorMessage == null) {
      _completionTimer?.cancel();
      _minimumVisibleTimer?.cancel();
      _completionRequested = false;
      _completionStarted = false;
      _completionCallbackSent = false;
      _isExiting = false;
      _minimumVisibleElapsed = false;
      _phase = RutioLoadingPhase.progressing;
      _journeyController.value =
          widget.initialProgress.clamp(0.0, _journeyLimit);
      _scheduleMinimumVisibleTimer();
      if (_journeyStarted) {
        _advanceToJourneyLimit();
      } else {
        _ensureJourneyStartsAfterLayout();
      }
    }
    if (widget.errorMessage != null) {
      _completionTimer?.cancel();
      _minimumVisibleTimer?.cancel();
      _journeyController.stop();
      if (_phase != RutioLoadingPhase.completed) {
        _phase = RutioLoadingPhase.waiting;
      }
      return;
    }
    if (!oldWidget.isOperationComplete && widget.isOperationComplete) {
      _requestCompletion();
    }
  }

  void _ensureJourneyStartsAfterLayout() {
    if (!widget.startJourney || _journeyStarted || _journeyStartScheduled)
      return;
    _journeyStartScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.startJourney) {
        _journeyStartScheduled = false;
        return;
      }
      if (widget.errorMessage != null) {
        _journeyStartScheduled = false;
        return;
      }
      setState(() => _journeyStarted = true);
      _advanceToJourneyLimit();
    });
  }

  void _advanceToJourneyLimit() {
    if (widget.errorMessage != null) return;
    _journeyController.animateTo(
      _journeyLimit,
      duration: _RutioLoadingTimings.progressDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  void _onJourneyTick() {
    if (!mounted) return;
    if (_journeyController.value >= _journeyLimit - 0.001 &&
        _phase == RutioLoadingPhase.progressing) {
      setState(() => _phase = RutioLoadingPhase.waiting);
    }
    _maybeCompleteJourney();
  }

  void _requestCompletion() {
    if (_completionRequested || widget.errorMessage != null) return;
    _completionRequested = true;
    _maybeCompleteJourney();
  }

  void _scheduleMinimumVisibleTimer() {
    _minimumVisibleTimer?.cancel();
    if (widget.minimumVisibleDuration <= Duration.zero) {
      _minimumVisibleElapsed = true;
      return;
    }
    _minimumVisibleTimer = Timer(
      widget.minimumVisibleDuration,
      _markMinimumVisibleElapsed,
    );
  }

  void _markMinimumVisibleElapsed() {
    if (!mounted) return;
    _minimumVisibleElapsed = true;
    _minimumVisibleTimer = null;
    _maybeCompleteJourney();
  }

  void _maybeCompleteJourney() {
    if (!mounted ||
        widget.errorMessage != null ||
        !_completionRequested ||
        _completionStarted ||
        !_minimumVisibleElapsed ||
        _journeyController.value < _journeyLimit - 0.001) {
      return;
    }
    _completeJourney();
  }

  void _completeJourney() {
    if (!mounted || widget.errorMessage != null || _completionStarted) return;
    _completionStarted = true;
    _minimumVisibleTimer = null;
    setState(() => _phase = RutioLoadingPhase.completing);
    _completionTimer = Timer(_RutioLoadingTimings.completionDuration, () {
      if (!mounted || widget.errorMessage != null) return;
      setState(() => _phase = RutioLoadingPhase.completed);
      _completionTimer = Timer(
        _RutioLoadingTimings.completedHoldDuration,
        _beginExit,
      );
    });
  }

  void _beginExit() {
    if (!mounted || widget.errorMessage != null) return;
    setState(() => _isExiting = true);
    _completionTimer =
        Timer(_RutioLoadingTimings.exitDuration, _notifyCompleted);
  }

  void _notifyCompleted() {
    if (!mounted || _completionCallbackSent) return;
    _completionCallbackSent = true;
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _minimumVisibleTimer?.cancel();
    _journeyController
      ..removeListener(_onJourneyTick)
      ..dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorMessage;
    return Scaffold(
      // The painted loading background is opaque. Keeping the Scaffold
      // transparent prevents the morning-blue fallback from flashing while
      // the final sunset frame is handed off to Home.
      backgroundColor: Colors.transparent,
      body: Semantics(
        label: error ?? widget.title,
        liveRegion: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _journeyController,
                builder: (context, _) => CustomPaint(
                  painter: _LoadingBackgroundPainter(
                    progress: _journeyController.value,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _isExiting ? 0 : 1,
              duration: _RutioLoadingTimings.exitDuration,
              curve: Curves.easeOut,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: _RutioLoadingSunLayer(
                      journey: _journeyController,
                      ambient: _ambientController,
                      phase: _phase,
                      showSun: _journeyStarted || !widget.startJourney,
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 120),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                                child: Text(
                                  _phase == RutioLoadingPhase.completed
                                      ? 'Todo listo'
                                      : widget.title,
                                  key: ValueKey<bool>(
                                    _phase == RutioLoadingPhase.completed,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.welcomeTitle.copyWith(
                                    color: AppColors.ink,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                error ?? widget.subtitle,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.welcomeSub.copyWith(
                                  color: AppColors.inkSoft,
                                  fontSize: 14,
                                ),
                              ),
                              if (error != null && widget.onRetry != null) ...[
                                const SizedBox(height: 22),
                                FilledButton(
                                  onPressed: widget.onRetry,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBackgroundPainter extends CustomPainter {
  const _LoadingBackgroundPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final palette = _LoadingPalette.forProgress(t);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.top, palette.mid, palette.bottom],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Final loading background used while handing off visually to Home.
class RutioLoadingFinalBackground extends StatelessWidget {
  const RutioLoadingFinalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _LoadingBackgroundPainter(progress: 1),
      child: SizedBox.expand(),
    );
  }
}

class _RutioLoadingSunLayer extends StatelessWidget {
  const _RutioLoadingSunLayer({
    required this.journey,
    required this.ambient,
    required this.phase,
    required this.showSun,
  });

  final Animation<double> journey;
  final Animation<double> ambient;
  final RutioLoadingPhase phase;
  final bool showSun;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.width.isFinite ||
            !size.height.isFinite ||
            size.width <= 0 ||
            size.height <= 0) {
          return const SizedBox.shrink();
        }
        final state =
            context.findAncestorStateOfType<_RutioLoadingScreenState>();
        state?._ensureJourneyStartsAfterLayout();
        if (!showSun) return const SizedBox.expand();
        final sunSize = math.min(size.shortestSide * 0.29, 126.0);
        final sun = RepaintBoundary(
          child: RutioSun(size: sunSize),
        );
        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([journey, ambient]),
                child: sun,
                builder: (context, child) {
                  final progress = journey.value;
                  final position = rutioLoadingSunPosition(
                    size,
                    progress,
                    sunSize: sunSize,
                  );
                  final breathing = phase == RutioLoadingPhase.waiting &&
                          progress >=
                              _RutioLoadingScreenState._journeyLimit - 0.001
                      ? 1 + math.sin(ambient.value * math.pi) * 0.01
                      : 1.0;
                  return Transform.translate(
                    offset: Offset(
                      position.dx - sunSize / 2,
                      position.dy - sunSize / 2,
                    ),
                    child: Transform.scale(
                      scale: breathing,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingPalette {
  const _LoadingPalette(this.top, this.mid, this.bottom);

  final Color top;
  final Color mid;
  final Color bottom;

  static _LoadingPalette forProgress(double value) {
    final t = value.clamp(0.0, 1.0);
    const stopPositions = <double>[0.0, 0.28, 0.58, 0.82, 1.0];
    const stops = <_LoadingPalette>[
      _LoadingPalette(
        AppColors.loadingMorningTop,
        AppColors.loadingMorningMid,
        AppColors.loadingMorningBottom,
      ),
      _LoadingPalette(
        Color(0xFFD2E6F5),
        Color(0xFFBBD4EF),
        Color(0xFFE2E6E8),
      ),
      _LoadingPalette(
        Color(0xFFC5D0E8),
        Color(0xFFB6BEDA),
        Color(0xFFE7D3C6),
      ),
      _LoadingPalette(
        Color(0xFFC5B8D4),
        Color(0xFFD0A8B2),
        Color(0xFFE8B18F),
      ),
      _LoadingPalette(
        Color(0xFFC5B8D4),
        Color(0xFFD0A8B2),
        Color(0xFFE8B18F),
      ),
    ];

    for (var index = 0; index < stopPositions.length - 1; index++) {
      final start = stopPositions[index];
      final end = stopPositions[index + 1];
      if (t > end && index < stopPositions.length - 2) continue;
      final segmentProgress = ((t - start) / (end - start)).clamp(0.0, 1.0);
      final easedProgress =
          segmentProgress * segmentProgress * (3 - 2 * segmentProgress);
      return _LoadingPalette._lerp(
        stops[index],
        stops[index + 1],
        easedProgress,
      );
    }

    return stops.last;
  }

  static _LoadingPalette _lerp(
    _LoadingPalette a,
    _LoadingPalette b,
    double value,
  ) {
    return _LoadingPalette(
      Color.lerp(a.top, b.top, value)!,
      Color.lerp(a.mid, b.mid, value)!,
      Color.lerp(a.bottom, b.bottom, value)!,
    );
  }
}
