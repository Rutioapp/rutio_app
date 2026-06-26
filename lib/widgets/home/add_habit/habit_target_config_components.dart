import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rutio/screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_constants.dart';
import 'package:rutio/utils/app_theme.dart';

class _HabitTargetConfigMetrics {
  static const double sheetRadius = 28;
  static const double topPadding = 10;
  static const double ctaReserveHeight = 104;
  static const double ctaTopPadding = 18;
  static const double ctaBottomPadding = 14;

  static const double headerAvatarSize = 42;
  static const double headerAvatarRadius = 14;
  static const double headerEmojiSize = 21;
  static const double headerGap = 12;
  static const double headerCloseSize = 34;
  static const double headerCloseIconSize = 15;
  static const double titleSize = 27;
  static const double titleSubtitleGap = 4;
  static const double subtitleSize = 12;

  static const double sectionPadding = 15;
  static const double sectionRadius = 20;
  static const double sectionLabelSize = 9;
  static const double sectionCaptionGap = 5;
  static const double sectionCaptionSize = 12;
  static const double sectionContentGap = 12;

  static const double optionHorizontalPadding = 14;
  static const double optionVerticalPadding = 10;
  static const double optionRadius = 16;
  static const double optionFontSize = 13;

  static const double stepperPaddingHorizontal = 12;
  static const double stepperPaddingVertical = 12;
  static const double stepperRadius = 18;
  static const double stepperValueSize = 34;
  static const double stepperUnitGap = 4;
  static const double stepperUnitSize = 11;

  static const double stepperButtonVisualSize = 36;
  static const double stepperButtonTapSize = 44;
  static const double stepperButtonIconSize = 16;

  static const double primaryButtonHeight = 48;
  static const double primaryButtonRadius = 18;
  static const double primaryButtonFontSize = 14;

  static const double dateButtonHorizontalPadding = 14;
  static const double dateButtonVerticalPadding = 12;
  static const double dateButtonRadius = 16;
  static const double dateButtonFontSize = 13;

  static const double weekdayVisualSize = 38;
  static const double weekdayFontSize = 12;
}

class HabitTargetConfigScaffold extends StatelessWidget {
  const HabitTargetConfigScaffold({
    super.key,
    required this.child,
    required this.bottomCta,
  });

  final Widget child;
  final Widget bottomCta;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: editHabitCream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_HabitTargetConfigMetrics.sheetRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                _HabitTargetConfigMetrics.topPadding,
                20,
                _HabitTargetConfigMetrics.ctaReserveHeight +
                    mediaQuery.viewInsets.bottom,
              ),
              child: child,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      editHabitCream.withOpacitySafe(0),
                      editHabitCream,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    _HabitTargetConfigMetrics.ctaTopPadding,
                    20,
                    _HabitTargetConfigMetrics.ctaBottomPadding +
                        mediaQuery.padding.bottom,
                  ),
                  child: bottomCta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitTargetConfigHeader extends StatelessWidget {
  const HabitTargetConfigHeader({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _HabitTargetConfigMetrics.headerAvatarSize,
          height: _HabitTargetConfigMetrics.headerAvatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacitySafe(0.62),
            borderRadius: BorderRadius.circular(
              _HabitTargetConfigMetrics.headerAvatarRadius,
            ),
            border: Border.all(
              color: editHabitCamel.withOpacitySafe(0.18),
            ),
          ),
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: _HabitTargetConfigMetrics.headerEmojiSize,
            ),
          ),
        ),
        const SizedBox(width: _HabitTargetConfigMetrics.headerGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.welcomeTitle.copyWith(
                  fontSize: _HabitTargetConfigMetrics.titleSize,
                  color: editHabitDark,
                ),
              ),
              const SizedBox(height: _HabitTargetConfigMetrics.titleSubtitleGap),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: _HabitTargetConfigMetrics.subtitleSize,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: editHabitDark.withOpacitySafe(0.64),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: _HabitTargetConfigMetrics.headerGap),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: onClose,
          child: Container(
            width: _HabitTargetConfigMetrics.headerCloseSize,
            height: _HabitTargetConfigMetrics.headerCloseSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacitySafe(0.58),
              shape: BoxShape.circle,
              border: Border.all(
                color: editHabitCamel.withOpacitySafe(0.16),
              ),
            ),
            child: Icon(
              CupertinoIcons.xmark,
              size: _HabitTargetConfigMetrics.headerCloseIconSize,
              color: editHabitDark.withOpacitySafe(0.74),
            ),
          ),
        ),
      ],
    );
  }
}

class HabitTargetConfigSection extends StatelessWidget {
  const HabitTargetConfigSection({
    super.key,
    required this.label,
    this.caption,
    required this.child,
  });

  final String label;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_HabitTargetConfigMetrics.sectionPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacitySafe(0.52),
        borderRadius: BorderRadius.circular(
          _HabitTargetConfigMetrics.sectionRadius,
        ),
        border: Border.all(color: editHabitCamel.withOpacitySafe(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: _HabitTargetConfigMetrics.sectionLabelSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
              color: editHabitDark.withOpacitySafe(0.42),
            ),
          ),
          if (caption != null && caption!.trim().isNotEmpty) ...[
            const SizedBox(height: _HabitTargetConfigMetrics.sectionCaptionGap),
            Text(
              caption!,
              style: GoogleFonts.dmSans(
                fontSize: _HabitTargetConfigMetrics.sectionCaptionSize,
                height: 1.45,
                fontWeight: FontWeight.w400,
                color: editHabitDark.withOpacitySafe(0.62),
              ),
            ),
          ],
          const SizedBox(height: _HabitTargetConfigMetrics.sectionContentGap),
          child,
        ],
      ),
    );
  }
}

class HabitTargetConfigOptionChip extends StatelessWidget {
  const HabitTargetConfigOptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: _HabitTargetConfigMetrics.optionHorizontalPadding,
          vertical: _HabitTargetConfigMetrics.optionVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: selected
              ? editHabitDark
              : Colors.white.withOpacitySafe(0.44),
          borderRadius: BorderRadius.circular(
            _HabitTargetConfigMetrics.optionRadius,
          ),
          border: Border.all(
            color: selected
                ? editHabitDark
                : editHabitCamel.withOpacitySafe(0.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: editHabitDark.withOpacitySafe(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: _HabitTargetConfigMetrics.optionFontSize,
              fontWeight: FontWeight.w600,
              color: selected
                  ? editHabitCream
                  : editHabitDark.withOpacitySafe(0.82),
            ),
          ),
        ),
      ),
    );
  }
}

class HabitTargetConfigStepper extends StatelessWidget {
  const HabitTargetConfigStepper({
    super.key,
    required this.value,
    required this.unitLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String value;
  final String unitLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _HabitTargetConfigMetrics.stepperPaddingHorizontal,
        vertical: _HabitTargetConfigMetrics.stepperPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(
          _HabitTargetConfigMetrics.stepperRadius,
        ),
        border: Border.all(color: editHabitCamel.withOpacitySafe(0.18)),
      ),
      child: Row(
        children: [
          _HabitTargetStepperButton(
            icon: CupertinoIcons.minus,
            onTap: onDecrement,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: _HabitTargetConfigMetrics.stepperValueSize,
                    height: 1,
                    color: editHabitDark,
                  ),
                ),
                const SizedBox(height: _HabitTargetConfigMetrics.stepperUnitGap),
                Text(
                  unitLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: _HabitTargetConfigMetrics.stepperUnitSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: editHabitCamel.withOpacitySafe(0.92),
                  ),
                ),
              ],
            ),
          ),
          _HabitTargetStepperButton(
            icon: CupertinoIcons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class HabitTargetConfigPrimaryButton extends StatelessWidget {
  const HabitTargetConfigPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _HabitTargetConfigMetrics.primaryButtonHeight,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(
          _HabitTargetConfigMetrics.primaryButtonRadius,
        ),
        color: editHabitDark,
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: _HabitTargetConfigMetrics.primaryButtonFontSize,
            fontWeight: FontWeight.w600,
            color: editHabitCream,
          ),
        ),
      ),
    );
  }
}

class HabitTargetConfigDateButton extends StatelessWidget {
  const HabitTargetConfigDateButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _HabitTargetConfigMetrics.dateButtonHorizontalPadding,
          vertical: _HabitTargetConfigMetrics.dateButtonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacitySafe(0.50),
          borderRadius: BorderRadius.circular(
            _HabitTargetConfigMetrics.dateButtonRadius,
          ),
          border: Border.all(color: editHabitCamel.withOpacitySafe(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 16,
              color: editHabitCamel.withOpacitySafe(0.95),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: _HabitTargetConfigMetrics.dateButtonFontSize,
                  fontWeight: FontWeight.w600,
                  color: editHabitDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitTargetConfigWeekdayChip extends StatelessWidget {
  const HabitTargetConfigWeekdayChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: _HabitTargetConfigMetrics.weekdayVisualSize,
        height: _HabitTargetConfigMetrics.weekdayVisualSize,
        decoration: BoxDecoration(
          color: selected
              ? editHabitCamel.withOpacitySafe(0.92)
              : Colors.white.withOpacitySafe(0.40),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? editHabitCamel
                : editHabitCamel.withOpacitySafe(0.18),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: _HabitTargetConfigMetrics.weekdayFontSize,
            fontWeight: FontWeight.w700,
            color: selected ? editHabitCream : editHabitDark,
          ),
        ),
      ),
    );
  }
}

class _HabitTargetStepperButton extends StatelessWidget {
  const _HabitTargetStepperButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: SizedBox(
        width: _HabitTargetConfigMetrics.stepperButtonTapSize,
        height: _HabitTargetConfigMetrics.stepperButtonTapSize,
        child: Center(
          child: Container(
            width: _HabitTargetConfigMetrics.stepperButtonVisualSize,
            height: _HabitTargetConfigMetrics.stepperButtonVisualSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacitySafe(0.74),
              shape: BoxShape.circle,
              border: Border.all(color: editHabitCamel.withOpacitySafe(0.20)),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: _HabitTargetConfigMetrics.stepperButtonIconSize,
              color: editHabitDark,
            ),
          ),
        ),
      ),
    );
  }
}
