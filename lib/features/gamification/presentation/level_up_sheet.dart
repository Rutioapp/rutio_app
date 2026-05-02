import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../domain/level_event.dart';

const Color _cream = Color(0xFFF6F2E9);
const Color _ink = Color(0xFF2F1E12);
const Color _inkSoft = Color(0xA62F1E12);
const Color _earth = Color(0xFF9E7540);

Future<T?> showLevelUpSheet<T>(
  BuildContext context, {
  required LevelEvent event,
  VoidCallback? onContinue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
    ),
    builder: (_) => _LevelUpSheet(
      event: event,
      onContinue: onContinue,
    ),
  );
}

class _LevelUpSheet extends StatelessWidget {
  const _LevelUpSheet({
    required this.event,
    this.onContinue,
  });

  final LevelEvent event;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final l10n = context.l10n;
    final copy = _copyForEvent(context, event);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _ink.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A2F1E12),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _earth.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _earth.withValues(alpha: 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${event.level}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  copy.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _inkSoft,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onContinue?.call();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: _cream,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l10n.levelUpContinueButton),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    // TODO: Hook this button into the future share flow.
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: _earth,
                      disabledForegroundColor: _earth.withValues(alpha: 0.55),
                      side: BorderSide(
                        color: _earth.withValues(alpha: 0.26),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(l10n.levelUpShareButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelUpCopy {
  const _LevelUpCopy({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

_LevelUpCopy _copyForEvent(BuildContext context, LevelEvent event) {
  final l10n = context.l10n;
  switch (event.type) {
    case LevelEventType.firstMilestone:
      return _LevelUpCopy(
        title: l10n.levelUpFirstMilestoneTitle,
        subtitle: l10n.levelUpFirstMilestoneSubtitle(event.level),
      );
    case LevelEventType.majorMilestone:
      return _LevelUpCopy(
        title: l10n.levelUpMajorMilestoneTitle,
        subtitle: l10n.levelUpMajorMilestoneSubtitle(event.level),
      );
    case LevelEventType.normalLevelUp:
      return _LevelUpCopy(
        title: l10n.levelUpNormalTitle,
        subtitle: l10n.levelUpNormalSubtitle(event.level),
      );
  }
}
