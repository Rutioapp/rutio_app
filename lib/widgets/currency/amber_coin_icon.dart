import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class AmberCoinIcon extends StatelessWidget {
  const AmberCoinIcon({
    super.key,
    this.size = 16,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final _AmberCoinPalette palette = _AmberCoinPalette.resolve(context);
    final double borderWidth = size * 0.05;
    final double blurRadius = size * 0.5;
    final double verticalOffset = size * 0.125;
    final double letterSize = size * 0.59375;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.34),
          radius: 0.96,
          colors: <Color>[
            palette.coinHighlight,
            palette.coinBase,
            palette.coinEdge,
          ],
          stops: const <double>[0.0, 0.66, 1.0],
        ),
        border: Border.all(
          color: palette.coinStroke,
          width: borderWidth,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.coinShadow,
            blurRadius: blurRadius,
            offset: Offset(0, verticalOffset),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'R',
        style: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: letterSize,
          height: 1.0,
          color: palette.coinLetter,
        ),
      ),
    );
  }
}

class _AmberCoinPalette {
  const _AmberCoinPalette({
    required this.coinHighlight,
    required this.coinBase,
    required this.coinEdge,
    required this.coinStroke,
    required this.coinLetter,
    required this.coinShadow,
  });

  final Color coinHighlight;
  final Color coinBase;
  final Color coinEdge;
  final Color coinStroke;
  final Color coinLetter;
  final Color coinShadow;

  factory _AmberCoinPalette.resolve(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return _AmberCoinPalette(
        coinHighlight: Colors.white,
        coinBase: AppColors.cream,
        coinEdge: AppColors.cream2,
        coinStroke: AppColors.earth.withValues(alpha: 0.52),
        coinLetter: AppColors.ink,
        coinShadow: AppColors.flowerYellow.withValues(alpha: 0.16),
      );
    }

    return _AmberCoinPalette(
      coinHighlight: AppColors.ink,
      coinBase: const Color(0xFF2A1408),
      coinEdge: const Color(0xFF1A0C04),
      coinStroke: AppColors.earth.withValues(alpha: 0.62),
      coinLetter: AppColors.cream,
      coinShadow: AppColors.earth.withValues(alpha: 0.16),
    );
  }
}
