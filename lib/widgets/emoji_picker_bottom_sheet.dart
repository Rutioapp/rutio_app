import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

Future<String?> showEmojiPickerBottomSheet(
  BuildContext context, {
  String? currentEmoji,
  Color? accentColor,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _EmojiPickerBottomSheet(
        currentEmoji: currentEmoji,
        accentColor: accentColor,
      );
    },
  );
}

class _EmojiPickerBottomSheet extends StatelessWidget {
  const _EmojiPickerBottomSheet({
    required this.currentEmoji,
    required this.accentColor,
  });

  final String? currentEmoji;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;
    final surface = colorScheme.surface;
    final outline = theme.dividerColor.withValues(alpha: 0.14);
    final mutedText =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62) ??
            Colors.black.withValues(alpha: 0.62);
    final pickerBackground = Color.alphaBlend(
      accent.withValues(alpha: 0.03),
      surface,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 28,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.emojiPickerTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentEmoji?.trim().isNotEmpty == true
                                ? l10n.emojiPickerCurrent(currentEmoji!)
                                : l10n.emojiPickerBrowseSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(CupertinoIcons.xmark),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: outline),
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: EmojiPicker(
                    onEmojiSelected: (_, emoji) {
                      Navigator.of(context).pop(emoji.emoji);
                    },
                    config: Config(
                      height: double.infinity,
                      checkPlatformCompatibility: true,
                      viewOrderConfig: const ViewOrderConfig(
                        top: EmojiPickerItem.searchBar,
                        middle: EmojiPickerItem.emojiView,
                        bottom: EmojiPickerItem.categoryBar,
                      ),
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig: CategoryViewConfig(
                        initCategory: Category.RECENT,
                        backgroundColor: pickerBackground,
                        indicatorColor: accent,
                        iconColor: mutedText,
                        iconColorSelected: accent,
                      ),
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: pickerBackground,
                        emojiSizeMax: 30,
                        columns: 8,
                        recentsLimit: 28,
                        replaceEmojiOnLimitExceed: true,
                        buttonMode: ButtonMode.CUPERTINO,
                        noRecents: Text(
                          l10n.emojiPickerNoRecents,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedText,
                          ),
                        ),
                      ),
                      bottomActionBarConfig: const BottomActionBarConfig(
                        enabled: false,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: pickerBackground,
                        buttonIconColor: mutedText,
                        hintText: l10n.emojiPickerSearchHint,
                        hintTextStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: mutedText,
                        ),
                        inputTextStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
