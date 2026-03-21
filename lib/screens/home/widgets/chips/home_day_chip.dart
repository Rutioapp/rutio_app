/// HomeDayChip representa un día seleccionable dentro de la tira semanal.
///
/// Controla el estado seleccionado, el estilo tipográfico y el callback de tap
/// para mantener la navegación por días aislada del layout principal.
library;

import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

class HomeDayChip extends StatelessWidget {
  const HomeDayChip({
    super.key,
    required this.day,
    required this.selected,
    required this.primaryDark,
    required this.dayFont,
    required this.numFont,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final Color primaryDark;
  final double dayFont;
  final double numFont;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // IOS-FIRST IMPROVEMENT START
    final bg = selected
        ? primaryDark.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.18);
    final border = selected
        ? primaryDark.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.24);
    final txt = selected ? primaryDark : Colors.black.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IosCornerRadius.chip),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(IosCornerRadius.chip),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.weekdayShort(day.weekday),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dayFont,
                  fontWeight: FontWeight.w800,
                  color: txt,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: numFont,
                  fontWeight: FontWeight.w900,
                  color: txt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }
}
