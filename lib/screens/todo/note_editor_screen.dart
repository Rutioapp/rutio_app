import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/helpers/todo_rich_text_controller.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/utils/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.initialValue,
  });

  final String initialValue;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TodoRichTextController _controller;
  late final FocusNode _focusNode;
  final GlobalKey<EditableTextState> _editableTextKey =
      GlobalKey<EditableTextState>();
  late final ScrollController _editorScrollController;

  bool _isBoldActive = false;
  bool _isItalicActive = false;
  bool _isStrikethroughActive = false;

  TextStyle get _editorTextStyle => AppTextStyles.fieldInput.copyWith(
        fontSize: 16,
        height: 1.55,
        color: TodoStyleResolver.textPrimary,
      );

  @override
  void initState() {
    super.initState();
    _controller = TodoRichTextController(
      text: widget.initialValue,
      baseStyle: _editorTextStyle,
    );
    _focusNode = FocusNode();
    _editorScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: TodoStyleResolver.sheetChrome,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(34),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: TodoStyleResolver.shell,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  _NoteEditorNavBar(
                    title: l10n.todoNotes,
                    cancelLabel: l10n.todoCancel,
                    saveLabel: l10n.todoSave,
                    onCancel: () => Navigator.of(context).maybePop(),
                    onSave: _save,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: _FormattingToolbar(
                      isBoldActive: _isBoldActive,
                      isItalicActive: _isItalicActive,
                      isStrikethroughActive: _isStrikethroughActive,
                      onBold: _toggleBold,
                      onItalic: _toggleItalic,
                      onStrikethrough: _toggleStrikethrough,
                      onBulletList: () => _prefixSelectedLines('\u2022 '),
                      onChecklist: () => _prefixSelectedLines('- [ ] '),
                      onToggleChecklist: _toggleChecklistOnSelectedLines,
                      onNumberedList: _insertNumberedList,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        18 + bottomSafeArea,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: TodoStyleResolver.stroke),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final editorMinHeight = (constraints.maxHeight - 36)
                                .clamp(0.0, double.infinity)
                                .toDouble();

                            return SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding:
                                  const EdgeInsets.fromLTRB(18, 18, 18, 18),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: editorMinHeight,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapUp: _handleEditorTapUp,
                                    child: Stack(
                                      children: <Widget>[
                                        if (_controller.text.isEmpty)
                                          IgnorePointer(
                                            child: Text(
                                              l10n.todoAddNote,
                                              style: AppTextStyles.fieldHint
                                                  .copyWith(
                                                fontSize: 16,
                                                height: 1.55,
                                                color:
                                                    TodoStyleResolver.textMuted,
                                              ),
                                            ),
                                          ),
                                        EditableText(
                                          key: _editableTextKey,
                                          controller: _controller,
                                          focusNode: _focusNode,
                                          scrollController:
                                              _editorScrollController,
                                          style: _editorTextStyle,
                                          cursorColor: TodoStyleResolver.accent,
                                          backgroundCursorColor:
                                              TodoStyleResolver.textMuted,
                                          selectionColor: TodoStyleResolver
                                              .accent
                                              .withValues(alpha: 0.18),
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          maxLines: null,
                                          minLines: 1,
                                          expands: false,
                                          textAlign: TextAlign.start,
                                          textDirection: TextDirection.ltr,
                                          cursorRadius:
                                              const Radius.circular(2),
                                          selectionControls:
                                              cupertinoTextSelectionHandleControls,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _handleEditorTapUp(TapUpDetails details) {
    final editableState = _editableTextKey.currentState;
    if (editableState == null) return;

    final renderEditable = editableState.renderEditable;
    final localPosition = renderEditable.globalToLocal(details.globalPosition);
    if (localPosition.dx > 30) return;

    TextPosition textPosition;
    try {
      textPosition = renderEditable.getPositionForPoint(localPosition);
    } on RangeError {
      return;
    }

    final offset = textPosition.offset;
    if (offset < 0 || offset > _controller.text.length) return;

    final lineRange = _selectedLineRange(_controller.text, offset, offset);
    final line = _controller.text.substring(lineRange.start, lineRange.end);

    if (!_isChecklistLine(line)) return;

    _toggleChecklistAtOffset(offset);
  }

  void _toggleBold() {
    _toggleInlineMarker(
      marker: '**',
      isActive: _isBoldActive,
      onChanged: (value) => _isBoldActive = value,
    );
  }

  void _toggleItalic() {
    _toggleInlineMarker(
      marker: '_',
      isActive: _isItalicActive,
      onChanged: (value) => _isItalicActive = value,
    );
  }

  void _toggleStrikethrough() {
    _toggleInlineMarker(
      marker: '~~',
      isActive: _isStrikethroughActive,
      onChanged: (value) => _isStrikethroughActive = value,
    );
  }

  void _toggleInlineMarker({
    required String marker,
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    _focusNode.requestFocus();
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);

    if (!selection.isCollapsed) {
      final selectedText = value.text.substring(selection.start, selection.end);
      final updatedText = value.text.replaceRange(
        selection.start,
        selection.end,
        '$marker$selectedText$marker',
      );

      _controller.value = value.copyWith(
        text: updatedText,
        selection: TextSelection(
          baseOffset: selection.start + marker.length,
          extentOffset: selection.end + marker.length,
        ),
        composing: TextRange.empty,
      );
      setState(() {});
      return;
    }

    final updatedText =
        value.text.replaceRange(selection.start, selection.end, marker);
    final nextOffset = selection.start + marker.length;

    _controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );

    setState(() {
      onChanged(!isActive);
    });
  }

  void _prefixSelectedLines(String prefix) {
    _focusNode.requestFocus();
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final lineRange =
        _selectedLineRange(value.text, selection.start, selection.end);
    final segment = value.text.substring(lineRange.start, lineRange.end);
    final lines = segment.split('\n');
    final updatedSegment =
        lines.map((line) => line.isEmpty ? prefix : '$prefix$line').join('\n');
    final updatedText =
        value.text.replaceRange(lineRange.start, lineRange.end, updatedSegment);

    _controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection(
        baseOffset: lineRange.start,
        extentOffset: lineRange.start + updatedSegment.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _toggleChecklistOnSelectedLines() {
    _focusNode.requestFocus();
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final lineRange =
        _selectedLineRange(value.text, selection.start, selection.end);
    final segment = value.text.substring(lineRange.start, lineRange.end);
    final updatedSegment =
        segment.split('\n').map(_toggleChecklistLine).join('\n');
    final updatedText =
        value.text.replaceRange(lineRange.start, lineRange.end, updatedSegment);

    _controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection(
        baseOffset: lineRange.start,
        extentOffset: lineRange.start + updatedSegment.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _toggleChecklistAtOffset(int offset) {
    _focusNode.requestFocus();
    final value = _controller.value;
    final lineRange = _selectedLineRange(value.text, offset, offset);
    final line = value.text.substring(lineRange.start, lineRange.end);
    final updatedLine = _toggleChecklistLine(line);
    final updatedText =
        value.text.replaceRange(lineRange.start, lineRange.end, updatedLine);

    _controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset:
            (lineRange.start + updatedLine.length).clamp(0, updatedText.length),
      ),
      composing: TextRange.empty,
    );
    setState(() {});
  }

  String _toggleChecklistLine(String line) {
    if (line.startsWith('- [ ] ')) {
      return line.replaceFirst('- [ ] ', '- [x] ');
    }
    if (line.startsWith('- [x] ')) {
      return line.replaceFirst('- [x] ', '- [ ] ');
    }
    if (line.startsWith('- [X] ')) {
      return line.replaceFirst('- [X] ', '- [ ] ');
    }
    if (line.trim().isEmpty) {
      return '- [ ] ';
    }
    return '- [ ] $line';
  }

  bool _isChecklistLine(String line) {
    return line.startsWith('- [ ] ') ||
        line.startsWith('- [x] ') ||
        line.startsWith('- [X] ');
  }

  void _insertNumberedList() {
    _focusNode.requestFocus();
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final lineRange =
        _selectedLineRange(value.text, selection.start, selection.end);
    final lines =
        value.text.substring(lineRange.start, lineRange.end).split('\n');
    final updatedSegment = lines.asMap().entries.map((entry) {
      final number = entry.key + 1;
      final line = entry.value;
      return line.isEmpty ? '$number. ' : '$number. $line';
    }).join('\n');
    final updatedText =
        value.text.replaceRange(lineRange.start, lineRange.end, updatedSegment);

    _controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection(
        baseOffset: lineRange.start,
        extentOffset: lineRange.start + updatedSegment.length,
      ),
      composing: TextRange.empty,
    );
  }

  _LineRange _selectedLineRange(String text, int start, int end) {
    final safeStart =
        start < 0 ? 0 : (start > text.length ? text.length : start);
    final safeEnd = end < 0 ? 0 : (end > text.length ? text.length : end);
    final lineStart = text.lastIndexOf('\n', safeStart - 1);
    final startIndex = lineStart == -1 ? 0 : lineStart + 1;
    final lineEnd = text.indexOf('\n', safeEnd);
    final endIndex = lineEnd == -1 ? text.length : lineEnd;
    return _LineRange(startIndex, endIndex);
  }
}

class _NoteEditorNavBar extends StatelessWidget {
  const _NoteEditorNavBar({
    required this.title,
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: <Widget>[
          _HeaderButton(
            label: cancelLabel,
            onPressed: onCancel,
            filled: false,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.welcomeTitle.copyWith(
                fontSize: 17,
                color: TodoStyleResolver.textPrimary,
              ),
            ),
          ),
          _HeaderButton(
            label: saveLabel,
            onPressed: onSave,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minWidth: 92, minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? TodoStyleResolver.accent
              : Colors.white.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? TodoStyleResolver.accent : TodoStyleResolver.stroke,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonPrimary.copyWith(
            color: filled
                ? TodoStyleResolver.surface
                : TodoStyleResolver.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FormattingToolbar extends StatelessWidget {
  const _FormattingToolbar({
    required this.isBoldActive,
    required this.isItalicActive,
    required this.isStrikethroughActive,
    required this.onBold,
    required this.onItalic,
    required this.onStrikethrough,
    required this.onBulletList,
    required this.onChecklist,
    required this.onToggleChecklist,
    required this.onNumberedList,
  });

  final bool isBoldActive;
  final bool isItalicActive;
  final bool isStrikethroughActive;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrikethrough;
  final VoidCallback onBulletList;
  final VoidCallback onChecklist;
  final VoidCallback onToggleChecklist;
  final VoidCallback onNumberedList;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _ToolbarChip(
            icon: CupertinoIcons.bold,
            onTap: onBold,
            isActive: isBoldActive,
          ),
          _ToolbarChip(
            icon: CupertinoIcons.italic,
            onTap: onItalic,
            isActive: isItalicActive,
          ),
          _ToolbarChip(
            icon: CupertinoIcons.strikethrough,
            onTap: onStrikethrough,
            isActive: isStrikethroughActive,
          ),
          _ToolbarChip(
            icon: CupertinoIcons.list_bullet,
            onTap: onBulletList,
          ),
          _ToolbarChip(
            icon: CupertinoIcons.check_mark_circled,
            onTap: onChecklist,
          ),
          _ToolbarChip(
            icon: CupertinoIcons.checkmark_rectangle,
            onTap: onToggleChecklist,
          ),
          _ToolbarChip(
            icon: CupertinoIcons.list_number,
            onTap: onNumberedList,
          ),
        ],
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isActive
                ? TodoStyleResolver.accent.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? TodoStyleResolver.accent.withValues(alpha: 0.32)
                  : TodoStyleResolver.stroke,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 19,
            color: isActive
                ? TodoStyleResolver.accent
                : TodoStyleResolver.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LineRange {
  const _LineRange(this.start, this.end);

  final int start;
  final int end;
}
