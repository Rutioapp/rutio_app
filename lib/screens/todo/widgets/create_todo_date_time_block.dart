import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/widgets/todo_section_label.dart';

class CreateTodoDateTimeBlock extends StatelessWidget {
  const CreateTodoDateTimeBlock({
    super.key,
    required this.sectionLabel,
    required this.dateLabel,
    required this.dateValue,
    required this.timeLabel,
    required this.timeValue,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String sectionLabel;
  final String dateLabel;
  final String dateValue;
  final String timeLabel;
  final String timeValue;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TodoSectionLabel(label: sectionLabel),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Column(
            children: <Widget>[
              _DateTimeRow(
                icon: CupertinoIcons.calendar,
                label: dateLabel,
                value: dateValue,
                onTap: onDateTap,
              ),
              const Divider(height: 1, color: Color(0x22CBAE88)),
              _DateTimeRow(
                icon: CupertinoIcons.time,
                label: timeLabel,
                value: timeValue,
                onTap: onTimeTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: TodoStyleResolver.neutralChip,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: TodoStyleResolver.accent),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: TodoStyleResolver.accentSoft,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Color(0xFFC6B8A8),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: Color(0xCCCFBDAA),
            ),
          ],
        ),
      ),
    );
  }
}
