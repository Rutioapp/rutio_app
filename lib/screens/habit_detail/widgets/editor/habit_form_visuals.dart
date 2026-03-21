import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rutio/utils/app_theme.dart';

class HabitFormBackground extends StatelessWidget {
  const HabitFormBackground({
    super.key,
    required this.familyColor,
  });

  static const Color _cream = Color(0xFFF5EDE0);
  static const Color _camel = Color(0xFFB8895A);

  final Color familyColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: _cream),
          ),
        ),
        Positioned(
          top: -60,
          right: -30,
          child: _HabitFormBlurOrb(
            size: 220,
            color: familyColor.withValues(alpha: 0.13),
          ),
        ),
        Positioned(
          top: 160,
          left: -55,
          child: _HabitFormBlurOrb(
            size: 180,
            color: _camel.withValues(alpha: 0.09),
          ),
        ),
      ],
    );
  }
}

class HabitFormBottomCta extends StatelessWidget {
  const HabitFormBottomCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDisabled = false,
    this.backgroundColor = const Color(0xFF3D2010),
    this.foregroundColor = const Color(0xFFF5EDE0),
    this.baseColor = const Color(0xFFF5EDE0),
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDisabled;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  baseColor.withValues(alpha: 0),
                  baseColor,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(20),
                color: backgroundColor,
                onPressed: isDisabled ? null : onPressed,
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HabitFormSectionLabel extends StatelessWidget {
  const HabitFormSectionLabel({
    super.key,
    required this.text,
  });

  static const Color _dark = Color(0xFF3D2010);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: _dark.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}

class HabitFormTypeCard extends StatelessWidget {
  const HabitFormTypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _camel = Color(0xFFB8895A);
  static const Color _dark = Color(0xFF3D2010);
  static const Color _cream = Color(0xFFF5EDE0);

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : _camel.withValues(alpha: 0.20),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    isSelected ? accentColor : _camel.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? _cream : _camel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _dark.withValues(alpha: 0.48),
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

class HabitFormEditableTargetValue extends StatelessWidget {
  const HabitFormEditableTargetValue({
    super.key,
    required this.value,
    required this.onTap,
  });

  static const Color _camel = Color(0xFFB8895A);
  static const Color _dark = Color(0xFF3D2010);

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _camel.withValues(alpha: 0.20)),
          color: Colors.white.withValues(alpha: 0.28),
        ),
        child: Text(
          '$value',
          style: const TextStyle(
            fontFamily: AppTextStyles.serifFamily,
            fontSize: 24,
            color: _dark,
          ),
        ),
      ),
    );
  }
}

class HabitFormStepperButton extends StatelessWidget {
  const HabitFormStepperButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  static const Color _camel = Color(0xFFB8895A);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _camel.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: _camel,
        ),
      ),
    );
  }
}

class HabitFormFrequencyChip extends StatelessWidget {
  const HabitFormFrequencyChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _camel = Color(0xFFB8895A);
  static const Color _dark = Color(0xFF3D2010);
  static const Color _cream = Color(0xFFF5EDE0);

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _dark : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _dark : _camel.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? _cream : _dark.withValues(alpha: 0.50),
          ),
        ),
      ),
    );
  }
}

class _HabitFormBlurOrb extends StatelessWidget {
  const _HabitFormBlurOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
