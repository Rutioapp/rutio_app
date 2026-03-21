import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';

class TodoRichTextController extends TextEditingController {
  TodoRichTextController({
    super.text,
    required this.baseStyle,
  });

  final TextStyle baseStyle;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final resolvedBase = (style ?? baseStyle).merge(baseStyle);
    final children = <InlineSpan>[];
    final source = text;

    var cursor = 0;
    var isBold = false;
    var isItalic = false;
    var isStrikethrough = false;
    var isCheckedChecklistLine = false;

    while (cursor < source.length) {
      final isLineStart = cursor == 0 || source[cursor - 1] == '\n';

      if (isLineStart && _startsWithUncheckedChecklist(source, cursor)) {
        children.addAll(
          _buildChecklistMarker(
            resolvedBase,
            isChecked: false,
            markerLength: 6,
          ),
        );
        isCheckedChecklistLine = false;
        cursor += 6;
        continue;
      }

      if (isLineStart && _startsWithCheckedChecklist(source, cursor)) {
        children.addAll(
          _buildChecklistMarker(
            resolvedBase,
            isChecked: true,
            markerLength: 6,
          ),
        );
        isCheckedChecklistLine = true;
        cursor += 6;
        continue;
      }

      if (source.startsWith('**', cursor)) {
        children.add(
          TextSpan(
            text: _hiddenMarker(2),
            style: _markerStyle(resolvedBase),
          ),
        );
        isBold = !isBold;
        cursor += 2;
        continue;
      }

      if (source.startsWith('~~', cursor)) {
        children.add(
          TextSpan(
            text: _hiddenMarker(2),
            style: _markerStyle(resolvedBase),
          ),
        );
        isStrikethrough = !isStrikethrough;
        cursor += 2;
        continue;
      }

      if (source[cursor] == '_') {
        children.add(
          TextSpan(
            text: _hiddenMarker(1),
            style: _markerStyle(resolvedBase),
          ),
        );
        isItalic = !isItalic;
        cursor += 1;
        continue;
      }

      if (source[cursor] == '\n') {
        children.add(
          TextSpan(
            text: '\n',
            style: resolvedBase.copyWith(
              fontWeight: isBold ? FontWeight.w700 : resolvedBase.fontWeight,
              fontStyle: isItalic ? FontStyle.italic : resolvedBase.fontStyle,
              decoration: (isStrikethrough || isCheckedChecklistLine)
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: resolvedBase.color,
            ),
          ),
        );
        isCheckedChecklistLine = false;
        cursor += 1;
        continue;
      }

      final start = cursor;
      while (cursor < source.length &&
          source[cursor] != '\n' &&
          !source.startsWith('**', cursor) &&
          !source.startsWith('~~', cursor) &&
          !((cursor == 0 || source[cursor - 1] == '\n') &&
              (_startsWithUncheckedChecklist(source, cursor) ||
                  _startsWithCheckedChecklist(source, cursor))) &&
          source[cursor] != '_') {
        cursor += 1;
      }

      children.add(
        TextSpan(
          text: source.substring(start, cursor),
          style: resolvedBase.copyWith(
            fontWeight: isBold ? FontWeight.w700 : resolvedBase.fontWeight,
            fontStyle: isItalic ? FontStyle.italic : resolvedBase.fontStyle,
            decoration: (isStrikethrough || isCheckedChecklistLine)
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: resolvedBase.color,
          ),
        ),
      );
    }

    return TextSpan(style: resolvedBase, children: children);
  }

  TextStyle _markerStyle(TextStyle base) {
    return base.copyWith(
      color: Colors.transparent,
      fontSize: 0.1,
      height: 0.01,
      letterSpacing: 0,
    );
  }

  String _hiddenMarker(int length) {
    return List<String>.filled(length, '\u200B').join();
  }

  bool _startsWithUncheckedChecklist(String source, int index) {
    return source.startsWith('- [ ] ', index);
  }

  bool _startsWithCheckedChecklist(String source, int index) {
    return source.startsWith('- [x] ', index) ||
        source.startsWith('- [X] ', index);
  }

  List<InlineSpan> _buildChecklistMarker(
    TextStyle base, {
    required bool isChecked,
    required int markerLength,
  }) {
    return <InlineSpan>[
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            isChecked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isChecked
                ? TodoStyleResolver.progressValue
                : TodoStyleResolver.textMuted,
          ),
        ),
      ),
      TextSpan(
        text: _hiddenMarker(markerLength),
        style: _markerStyle(base),
      ),
    ];
  }
}
