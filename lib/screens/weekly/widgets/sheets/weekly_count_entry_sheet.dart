import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutio/l10n/l10n.dart';

class WeeklyCountEntrySheet extends StatefulWidget {
  const WeeklyCountEntrySheet({
    super.key,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.unitLabel,
    required this.initialValue,
    required this.allowDecimal,
  });

  final Color accentColor;
  final String title;
  final String subtitle;
  final String unitLabel;
  final num? initialValue;
  final bool allowDecimal;

  @override
  State<WeeklyCountEntrySheet> createState() => _WeeklyCountEntrySheetState();
}

class _WeeklyCountEntrySheetState extends State<WeeklyCountEntrySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialValue == null
        ? ''
        : (widget.initialValue! % 1 == 0
            ? widget.initialValue!.toInt().toString()
            : widget.initialValue!.toString());
    _controller = TextEditingController(text: initialText);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final invalidNumberMessage = context.l10n.weeklyInvalidNumberMessage;
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = invalidNumberMessage);
      return;
    }

    final parsed = num.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) {
      setState(() => _errorText = invalidNumberMessage);
      return;
    }

    final safeValue = parsed < 0 ? 0 : parsed;
    final result =
        widget.allowDecimal ? safeValue.toDouble() : safeValue.toInt();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (widget.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.56),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.allowDecimal,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(widget.allowDecimal ? r'[0-9,.]' : r'[0-9]'),
                    ),
                  ],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  placeholder: widget.allowDecimal ? '0.0' : '0',
                  suffix: widget.unitLabel.trim().isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Text(
                            widget.unitLabel.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor.withValues(alpha: 0.90),
                            ),
                          ),
                        ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: CupertinoColors.systemGrey5.resolveFrom(context),
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          context.l10n.commonCancel,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.76),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _submit,
                        child: Text(
                          context.l10n.commonSave,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
