import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/presentation/models/mystery_box_opening_state.dart';
import 'package:rutio/features/shop/presentation/widgets/mystery_box_hero_view.dart';
import 'package:rutio/features/shop/presentation/widgets/mystery_box_opening_sheet.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';

enum MysteryBoxHapticCue {
  light,
  medium,
  success,
}

typedef MysteryBoxHapticPlayer = Future<void> Function(MysteryBoxHapticCue cue);
typedef MysteryBoxOpenRequest = Future<MysteryBoxOperationResult> Function();
typedef MysteryBoxMarkPresented = Future<bool> Function(
  MysteryBoxOpeningTransaction transaction,
);

class MysteryBoxOpeningScreen extends StatefulWidget {
  const MysteryBoxOpeningScreen({
    super.key,
    required this.onClose,
    this.transaction,
    this.onOpenRequested,
    this.onBoxTapped,
    this.onMarkPresented,
    this.hapticPlayer = _defaultHapticPlayer,
  });

  final VoidCallback onClose;
  final MysteryBoxOpeningTransaction? transaction;
  final MysteryBoxOpenRequest? onOpenRequested;
  final VoidCallback? onBoxTapped;
  final MysteryBoxMarkPresented? onMarkPresented;
  final MysteryBoxHapticPlayer hapticPlayer;

  @override
  State<MysteryBoxOpeningScreen> createState() =>
      _MysteryBoxOpeningScreenState();

  static Future<void> _defaultHapticPlayer(MysteryBoxHapticCue cue) async {
    switch (cue) {
      case MysteryBoxHapticCue.light:
        await IosFeedback.lightImpact();
        break;
      case MysteryBoxHapticCue.medium:
        await IosFeedback.mediumImpact();
        break;
      case MysteryBoxHapticCue.success:
        await HapticFeedback.heavyImpact();
        break;
    }
  }
}

class _MysteryBoxOpeningScreenState extends State<MysteryBoxOpeningScreen>
    with TickerProviderStateMixin {
  static const Color _backgroundColor = Color(0xFFF6EFE8);
  static const double _boxWidthFactor = 0.78;
  static const Duration _idleDuration = Duration(milliseconds: 2100);
  static const Duration _idleSettleDuration = Duration(milliseconds: 140);
  static const double _idleBoxScaleMin = 0.94;
  static const double _idleBoxScaleMax = 1.06;
  static const double _idleBoxRotationMin = -0.035;
  static const double _idleBoxRotationMax = 0.035;
  static const double _idleTextScaleMin = 0.98;
  static const double _idleTextScaleMax = 1.025;
  static const Duration _flashEnterDuration = Duration(milliseconds: 220);
  static const Duration _flashHoldDuration = Duration(milliseconds: 550);
  static const Duration _flashExitDuration = Duration(milliseconds: 450);
  static const Duration _openedPreviewDuration = Duration(milliseconds: 350);
  static const Duration _assetSwapDuration = Duration(milliseconds: 150);
  static const int _flashSequenceMillis = 1220;
  static const Duration _flashSequenceDuration = Duration(
    milliseconds: _flashSequenceMillis,
  );

  late MysteryBoxOpeningState _state;
  late final AnimationController _idleController;
  late final AnimationController _revealController;
  late final Animation<double> _idleBoxScale;
  late final Animation<double> _idleBoxRotation;
  late final Animation<double> _idleTextScale;
  late final Animation<double> _flashOverlayOpacity;
  late final Animation<double> _boxScale;
  bool _disableAnimations = false;
  bool _hasPrecachingCompleted = false;
  bool _isIdleRunning = false;
  bool _isMarkingPresented = false;
  bool _showOpenedBox = false;

  @override
  void initState() {
    super.initState();
    _state = MysteryBoxOpeningState.ready(transaction: widget.transaction);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _idleController = AnimationController(
      vsync: this,
      duration: _idleDuration,
      value: 0.5,
    );
    _idleBoxScale = Tween<double>(
      begin: _idleBoxScaleMin,
      end: _idleBoxScaleMax,
    ).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOut,
      ),
    );
    _idleBoxRotation = Tween<double>(
      begin: _idleBoxRotationMin,
      end: _idleBoxRotationMax,
    ).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );
    _idleTextScale = Tween<double>(
      begin: _idleTextScaleMin,
      end: _idleTextScaleMax,
    ).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: const Interval(0.08, 0.92, curve: Curves.easeInOut),
      ),
    );
    _revealController = AnimationController(
      vsync: this,
      duration: _flashSequenceDuration,
    );
    _flashOverlayOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: _flashEnterDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.95),
        weight: _flashHoldDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.95,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: _flashExitDuration.inMilliseconds.toDouble(),
      ),
    ]).animate(_revealController);
    _boxScale = Tween<double>(
      begin: 1.0,
      end: 1.018,
    ).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncIdleAnimation();
    if (!_hasPrecachingCompleted) {
      _hasPrecachingCompleted = true;
      precacheImage(
        const AssetImage(MysteryBoxHeroView.defaultAssetPath),
        context,
      );
      precacheImage(
        const AssetImage(MysteryBoxHeroView.openedAssetPath),
        context,
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _idleController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canShowReward = _state.isRewardVisible && _state.transaction != null;
    final showTapText =
        _state.status == MysteryBoxOpeningUiStatus.ready && !_showOpenedBox;
    final showIdleMotion = _shouldAnimateIdle;

    return PopScope(
      canPop: _state.canStartOpening,
      onPopInvokedWithResult: _handleSystemBack,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _idleController,
                _revealController,
              ]),
              builder: (BuildContext context, _) {
                final currentAsset = _showOpenedBox
                    ? MysteryBoxHeroView.openedAssetPath
                    : MysteryBoxHeroView.defaultAssetPath;
                final idleBoxScale = showIdleMotion ? _idleBoxScale.value : 1.0;
                final idleRotation =
                    showIdleMotion ? _idleBoxRotation.value : 0.0;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: FractionallySizedBox(
                            key: const Key('mysteryBoxHeroSizing'),
                            widthFactor: _boxWidthFactor,
                            child: RepaintBoundary(
                              child: Transform.rotate(
                                key: const Key('mysteryBoxIdleRotation'),
                                angle: idleRotation,
                                child: Transform.scale(
                                  key: const Key('mysteryBoxIdleScale'),
                                  scale: idleBoxScale,
                                  child: Transform.scale(
                                    scale:
                                        _state.isBusy ? _boxScale.value : 1.0,
                                    child: AnimatedSwitcher(
                                      duration: _effectiveDuration(
                                        _assetSwapDuration,
                                      ),
                                      switchInCurve: Curves.linear,
                                      switchOutCurve: Curves.linear,
                                      layoutBuilder: (
                                        Widget? currentChild,
                                        List<Widget> previousChildren,
                                      ) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: <Widget>[
                                            ...previousChildren,
                                            if (currentChild != null)
                                              currentChild,
                                          ],
                                        );
                                      },
                                      child: KeyedSubtree(
                                        key: const Key(
                                          'mysteryBoxFullscreenImage',
                                        ),
                                        child: Image.asset(
                                          currentAsset,
                                          key: ValueKey<String>(currentAsset),
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        IgnorePointer(
                          ignoring: !showTapText,
                          child: AnimatedOpacity(
                            key: const Key('mysteryBoxTapTextOpacity'),
                            duration: _effectiveDuration(
                              const Duration(milliseconds: 150),
                            ),
                            opacity: showTapText ? 1 : 0,
                            child: Transform.scale(
                              key: const Key('mysteryBoxTapTextScale'),
                              scale: showIdleMotion ? _idleTextScale.value : 1,
                              child: Text(
                                l10n.shopMysteryBoxTapToOpen,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: const Color(0xFF1D1B16),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Semantics(
              button: true,
              enabled: _state.canStartOpening,
              label: l10n.shopMysteryBoxOpenButton,
              hint: l10n.shopMysteryBoxTapToOpen,
              child: GestureDetector(
                key: const Key('mysteryBoxInteractionLayer'),
                behavior: HitTestBehavior.opaque,
                onTap: _state.canStartOpening ? _handleOpenRequested : null,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _revealController,
                  builder: (BuildContext context, _) {
                    return Stack(
                      key: const Key('mysteryBoxRevealOverlay'),
                      fit: StackFit.expand,
                      children: <Widget>[
                        Opacity(
                          key: const Key('mysteryBoxFlashOverlay'),
                          opacity: _flashOverlayOpacity.value.clamp(0.0, 1.0),
                          child: const ColoredBox(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !canShowReward,
              child: AnimatedOpacity(
                opacity: canShowReward ? 1 : 0,
                duration: _effectiveDuration(
                  const Duration(milliseconds: 220),
                ),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.16),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSlide(
                      duration: _effectiveDuration(
                        const Duration(milliseconds: 280),
                      ),
                      curve: Curves.easeOutCubic,
                      offset:
                          canShowReward ? Offset.zero : const Offset(0, 0.08),
                      child: canShowReward
                          ? MysteryBoxOpeningSheet(
                              key: const Key('mysteryBoxRewardSheet'),
                              transaction: _state.transaction!,
                              isPresenting: _isMarkingPresented,
                              errorMessage: _state.errorMessage,
                              onContinue: _markPresentedAndClose,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _effectiveDuration(Duration duration) {
    return _disableAnimations ? const Duration(milliseconds: 1) : duration;
  }

  bool get _shouldAnimateIdle =>
      !_disableAnimations &&
      _state.status == MysteryBoxOpeningUiStatus.ready &&
      !_showOpenedBox;

  void _syncIdleAnimation() {
    if (!_idleController.isAnimating && _shouldAnimateIdle) {
      _idleController.repeat(reverse: true);
      _isIdleRunning = true;
      return;
    }

    if (_idleController.isAnimating && !_shouldAnimateIdle) {
      _idleController.stop();
      _isIdleRunning = false;
    }
  }

  Future<void> _settleIdleAnimation() async {
    if (_disableAnimations || !_isIdleRunning) {
      _idleController.stop();
      _isIdleRunning = false;
      return;
    }

    _idleController.stop();
    _isIdleRunning = false;
    try {
      await _idleController.animateTo(
        0.5,
        duration: _effectiveDuration(_idleSettleDuration),
        curve: Curves.easeOutCubic,
      );
    } on TickerCanceled {
      return;
    }
  }

  Future<void> _handleOpenRequested() async {
    if (!_state.canStartOpening) return;
    final l10n = context.l10n;

    final existingTransaction = _state.transaction;
    if (existingTransaction != null) {
      await _settleIdleAnimation();
      if (!mounted) return;
      widget.onBoxTapped?.call();
      await widget.hapticPlayer(MysteryBoxHapticCue.medium);
      await _playRevealWithTransaction(existingTransaction);
      return;
    }

    final openRequest = widget.onOpenRequested;
    if (openRequest == null) {
      _setRecoverableError(l10n.shopMysteryBoxErrorOpen);
      return;
    }

    setState(() {
      _state = _state.copyWith(
        status: MysteryBoxOpeningUiStatus.openingInProgress,
        clearError: true,
        clearTransaction: true,
      );
      _showOpenedBox = false;
    });
    await _settleIdleAnimation();
    if (!mounted) return;

    widget.onBoxTapped?.call();
    await widget.hapticPlayer(MysteryBoxHapticCue.medium);

    final result = await openRequest();
    if (!mounted) return;

    if ((result.isSuccess ||
            result.status == MysteryBoxOperationStatus.duplicateTransaction) &&
        result.transaction != null) {
      await _playRevealWithTransaction(result.transaction!);
      return;
    }

    _setRecoverableError(_errorMessageFor(l10n, result));
  }

  Future<void> _playRevealWithTransaction(
    MysteryBoxOpeningTransaction transaction,
  ) async {
    if (!mounted) return;

    setState(() {
      _state = _state.copyWith(
        status: MysteryBoxOpeningUiStatus.revealAnimation,
        transaction: transaction,
        clearError: true,
      );
      _showOpenedBox = false;
    });

    final controllerFuture = _revealController.forward(from: 0);

    try {
      await Future<void>.delayed(_effectiveDuration(_flashEnterDuration));
      if (!mounted) return;

      setState(() {
        _showOpenedBox = true;
      });

      await controllerFuture.orCancel;
    } on TickerCanceled {
      return;
    }

    if (!mounted) return;

    await widget.hapticPlayer(MysteryBoxHapticCue.success);
    await Future<void>.delayed(_effectiveDuration(_openedPreviewDuration));
    if (!mounted) return;

    setState(() {
      _state = _state.copyWith(
        status: MysteryBoxOpeningUiStatus.rewardVisible,
        transaction: transaction,
      );
    });
  }

  void _setRecoverableError(String message) {
    if (!mounted) return;

    setState(() {
      _state = _state.copyWith(
        status: MysteryBoxOpeningUiStatus.ready,
        errorMessage: message,
        clearTransaction: true,
      );
      _showOpenedBox = false;
    });
    _syncIdleAnimation();

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _errorMessageFor(
    AppLocalizations l10n,
    MysteryBoxOperationResult result,
  ) {
    if (result.errorMessage != null && result.errorMessage!.trim().isNotEmpty) {
      return result.errorMessage!;
    }

    switch (result.status) {
      case MysteryBoxOperationStatus.noBoxes:
        return l10n.shopMysteryBoxErrorNoBoxes;
      case MysteryBoxOperationStatus.invalidConfiguration:
        return l10n.shopMysteryBoxErrorConfig;
      case MysteryBoxOperationStatus.persistenceError:
        return l10n.shopMysteryBoxErrorPersist;
      case MysteryBoxOperationStatus.duplicateTransaction:
        return l10n.shopMysteryBoxErrorPending;
      case MysteryBoxOperationStatus.invalidTransactionId:
      case MysteryBoxOperationStatus.transactionNotFound:
      case MysteryBoxOperationStatus.unavailableState:
        return l10n.shopMysteryBoxErrorOpen;
      case MysteryBoxOperationStatus.success:
        return l10n.shopMysteryBoxErrorReward;
    }
  }

  Future<void> _markPresentedAndClose() async {
    if (!mounted || _isMarkingPresented) return;

    final l10n = context.l10n;

    final transaction = _state.transaction;
    final onMarkPresented = widget.onMarkPresented;
    if (onMarkPresented == null || transaction == null) {
      widget.onClose();
      return;
    }

    setState(() {
      _isMarkingPresented = true;
      _state = _state.copyWith(clearError: true);
    });

    try {
      final didMark = await onMarkPresented(transaction);
      if (!mounted) return;

      if (didMark) {
        widget.onClose();
        return;
      }

      setState(() {
        _state = _state.copyWith(
          status: MysteryBoxOpeningUiStatus.ready,
          errorMessage: l10n.shopMysteryBoxErrorOpen,
        );
        _showOpenedBox = false;
      });
      _syncIdleAnimation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          status: MysteryBoxOpeningUiStatus.ready,
          errorMessage: l10n.shopMysteryBoxErrorOpen,
        );
        _showOpenedBox = false;
      });
      _syncIdleAnimation();
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingPresented = false;
        });
      }
    }
  }

  void _handleSystemBack(bool didPop, Object? result) {
    if (didPop || _state.canStartOpening) {
      return;
    }

    if (_state.isBusy) {
      return;
    }

    if (_state.isRewardVisible) {
      _markPresentedAndClose();
    }
  }
}
