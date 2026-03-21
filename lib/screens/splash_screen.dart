import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../utils/app_theme.dart';
import '../utils/rutio_responsive.dart';
import '../widgets/backgrounds/rutio_sky_background.dart';
import '../widgets/scene_painters.dart';
import 'root_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _tagOpacity;
  late final Animation<double> _hintOpacity;

  bool _revealingRoot = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    );

    _tagOpacity = Tween<double>(begin: 0, end: 0.6).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );

    _hintOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();

    // ✅ Tiempo mínimo de splash: 1.3s
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      _goNext();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_revealingRoot) return;
    setState(() => _revealingRoot = true);

    // ✅ Pre-render real: RootGate se construye por debajo y el Splash hace fade-out.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: Duration.zero, // la animación la hacemos dentro
        pageBuilder: (_, __, ___) => const _RootReveal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goNext, // tap acelera
      child: _SplashBody(
        scale: _scale,
        tagOpacity: _tagOpacity,
        hintOpacity: _hintOpacity,
      ),
    );
  }
}

/// Pantalla “puente” que PRE-RENDERIZA RootGate por debajo
/// y hace fade-out del Splash por encima.
class _RootReveal extends StatefulWidget {
  const _RootReveal();

  @override
  State<_RootReveal> createState() => _RootRevealState();
}

class _RootRevealState extends State<_RootReveal> {
  double _overlayOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    // Dejamos 1 frame para que RootGate se construya y pinte por debajo,
    // y entonces comenzamos el fade-out del overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _overlayOpacity = 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RootGate(), // ✅ ya está renderizando debajo

        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _overlayOpacity,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: const _SplashOverlayStatic(),
          ),
        ),
      ],
    );
  }
}

/// Overlay del splash (estático) para que el fade sea limpio.
/// Si quieres que siga animando durante el fade, se puede,
/// pero este método suele ser el más “premium” y estable.
class _SplashOverlayStatic extends StatelessWidget {
  const _SplashOverlayStatic();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RutioSkyBackground(showBottomFade: false),
          // Suelo
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _SplashGround(),
          ),
          // Logo + textos (estático)
          Center(child: _SplashCenterStatic()),
        ],
      ),
    );
  }
}

class _SplashGround extends StatelessWidget {
  const _SplashGround();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width, R.h(context, 340)),
      painter: SplashScenePainter(),
    );
  }
}

class _SplashCenterStatic extends StatelessWidget {
  const _SplashCenterStatic();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SplashWordmark(),
        SizedBox(height: R.h(context, 18)),
        Opacity(
          opacity: 0.6,
          child: Text(
            context.l10n.splashTagline,
            style: AppTextStyles.tagline,
          ),
        ),
      ],
    );
  }
}

class _SplashBody extends StatelessWidget {
  final Animation<double> scale;
  final Animation<double> tagOpacity;
  final Animation<double> hintOpacity;

  const _SplashBody({
    required this.scale,
    required this.tagOpacity,
    required this.hintOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RutioSkyBackground(showBottomFade: false),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, R.h(context, 340)),
              painter: SplashScenePainter(),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SplashWordmark(),
                  SizedBox(height: R.h(context, 18)),
                  FadeTransition(
                    opacity: tagOpacity,
                    child: Text(
                      context.l10n.splashTagline,
                      style: AppTextStyles.tagline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: R.h(context, 70),
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: hintOpacity,
              child: _PulsingHint(text: context.l10n.splashTapToStart),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo icon ──
class _SplashWordmark extends StatelessWidget {
  const _SplashWordmark();

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.splash.copyWith(
      fontSize: R.sp(context, 74),
      letterSpacing: -R.r(context, 4),
      height: 0.92,
    );

    return SizedBox(
      width: R.r(context, 220),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Rut',
                style: baseStyle.copyWith(color: const Color(0xFF3D2010)),
              ),
              TextSpan(
                text: 'io',
                style: baseStyle.copyWith(color: const Color(0xFFB8895A)),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}

// ── Pulsing hint ──
class _PulsingHint extends StatefulWidget {
  final String text;
  const _PulsingHint({required this.text});

  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.32, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: R.sp(context, 10),
            letterSpacing: R.r(context, 2),
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
