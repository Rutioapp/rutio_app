import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

// IOS-FIRST IMPROVEMENT START
class IosSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  const IosSpacing._();
}

class IosCornerRadius {
  static const double control = 14;
  static const double chip = 16;
  static const double card = 22;
  static const double pill = 999;

  const IosCornerRadius._();
}

class IosTypography {
  const IosTypography._();

  static TextStyle largeTitle(BuildContext context) {
    return AppTextStyles.welcomeTitle.copyWith(
      fontSize: 34,
      height: 1.0,
      letterSpacing: -0.8,
      color: Colors.black.withValues(alpha: 0.92),
    );
  }

  static TextStyle title(BuildContext context) {
    return AppTextStyles.authTitle.copyWith(
      fontSize: 20,
      color: Colors.black.withValues(alpha: 0.88),
    );
  }

  static TextStyle body(BuildContext context) {
    return (Theme.of(context).textTheme.bodyMedium ?? AppTextStyles.fieldInput)
        .copyWith(
      fontFamily: AppTextStyles.sansFamily,
      fontSize: 15,
      color: Colors.black.withValues(alpha: 0.68),
    );
  }

  static TextStyle caption(BuildContext context) {
    return (Theme.of(context).textTheme.bodySmall ?? AppTextStyles.fieldHint)
        .copyWith(
      fontFamily: AppTextStyles.sansFamily,
      fontSize: 12.5,
      color: Colors.black.withValues(alpha: 0.52),
    );
  }
}

class IosFrostedCard extends StatelessWidget {
  const IosFrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(IosSpacing.md),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(IosCornerRadius.card),
    ),
    this.blurSigma = 18,
    this.elevated = false,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;
  final bool elevated;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fill = backgroundColor ?? Colors.white.withValues(alpha: 0.68);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
// IOS-FIRST IMPROVEMENT END
