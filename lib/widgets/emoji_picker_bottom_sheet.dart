import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'emoji_picker/habit_emoji_catalog.dart';
import 'emoji_picker/habit_emoji_search.dart';

Future<String?> showEmojiPickerBottomSheet(
  BuildContext context, {
  String? currentEmoji,
  String? currentHabitName,
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
        currentHabitName: currentHabitName,
        accentColor: accentColor,
      );
    },
  );
}

class _EmojiPickerBottomSheet extends StatefulWidget {
  const _EmojiPickerBottomSheet({
    required this.currentEmoji,
    required this.currentHabitName,
    required this.accentColor,
  });

  final String? currentEmoji;
  final String? currentHabitName;
  final Color? accentColor;

  @override
  State<_EmojiPickerBottomSheet> createState() => _EmojiPickerBottomSheetState();
}

class _EmojiPickerBottomSheetState extends State<_EmojiPickerBottomSheet> {
  late final TextEditingController _searchController;
  late String _selectedEmoji;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedEmoji = widget.currentEmoji?.trim().isNotEmpty == true
        ? widget.currentEmoji!.trim()
        : kHabitEmojiOptions.first.emoji;
    _selectedCategory = HabitEmojiRecentsStore.values.isNotEmpty
        ? HabitEmojiCategories.recent
        : HabitEmojiCategories.frequent;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final accent = widget.accentColor ?? colorScheme.primary;
    final surface = colorScheme.surface;
    final outline = theme.dividerColor.withValues(alpha: 0.14);
    final mutedText =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62) ??
            Colors.black.withValues(alpha: 0.62);
    final pickerBackground = Color.alphaBlend(
      accent.withValues(alpha: 0.03),
      surface,
    );

    final query = _searchController.text;
    final recentEmojis = HabitEmojiRecentsStore.values;
    final visibleCategories = kHabitEmojiCategoryOrder
        .where(
          (category) =>
              category != HabitEmojiCategories.recent || recentEmojis.isNotEmpty,
        )
        .toList(growable: false);
    final visibleOptions = resolveEmojiPickerOptions(
      query: query,
      selectedCategory: _selectedCategory,
      recentEmojis: recentEmojis,
    );

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
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
                            l10n.emojiPickerHabitSubtitle,
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
                  child: ColoredBox(
                    color: pickerBackground,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _CurrentHabitCard(
                            emoji: _selectedEmoji,
                            title: widget.currentHabitName,
                            fallbackTitle: widget.currentEmoji?.trim().isNotEmpty == true
                                ? l10n.emojiPickerCurrent(widget.currentEmoji!.trim())
                                : l10n.emojiPickerBrowseSubtitle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: l10n.emojiPickerSearchHint,
                              prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                              suffixIcon: query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: l10n.diaryCloseSearchTooltip,
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                                    ),
                              filled: true,
                              fillColor: surface.withValues(alpha: 0.92),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: accent.withValues(alpha: 0.55)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final category = visibleCategories[index];
                              final selected = category == _selectedCategory;
                              return ChoiceChip(
                                label: Text(l10n.emojiPickerCategoryLabel(category)),
                                selected: selected,
                                onSelected: (_) => setState(() {
                                  _selectedCategory = category;
                                }),
                                selectedColor: accent.withValues(alpha: 0.16),
                                backgroundColor: surface.withValues(alpha: 0.92),
                                labelStyle: theme.textTheme.bodySmall?.copyWith(
                                  color: selected ? accent : colorScheme.onSurface,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? accent.withValues(alpha: 0.28)
                                      : outline,
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemCount: visibleCategories.length,
                          ),
                        ),
                        Expanded(
                          child: visibleOptions.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      query.isEmpty &&
                                              _selectedCategory ==
                                                  HabitEmojiCategories.recent
                                          ? l10n.emojiPickerNoRecents
                                          : l10n.emojiPickerNoResults,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: mutedText,
                                      ),
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: visibleOptions.length,
                                  itemBuilder: (context, index) {
                                    final option = visibleOptions[index];
                                    final selected = option.emoji == _selectedEmoji;
                                    return _EmojiGridTile(
                                      option: option,
                                      isSelected: selected,
                                      accent: accent,
                                      outline: outline,
                                      surface: surface,
                                      onTap: () => setState(() {
                                        _selectedEmoji = option.emoji;
                                      }),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(l10n.commonCancel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    HabitEmojiRecentsStore.register(_selectedEmoji);
                                    Navigator.of(context).pop(_selectedEmoji);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: ThemeData.estimateBrightnessForColor(
                                              accent,
                                            ) ==
                                            Brightness.dark
                                        ? Colors.white
                                        : colorScheme.onPrimary,
                                  ),
                                  child: Text(l10n.commonSave),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _CurrentHabitCard extends StatelessWidget {
  const _CurrentHabitCard({
    required this.emoji,
    required this.title,
    required this.fallbackTitle,
  });

  final String emoji;
  final String? title;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final resolvedTitle = title?.trim().isNotEmpty == true ? title!.trim() : fallbackTitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E7D5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resolvedTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiGridTile extends StatelessWidget {
  const _EmojiGridTile({
    required this.option,
    required this.isSelected,
    required this.accent,
    required this.outline,
    required this.surface,
    required this.onTap,
  });

  final EmojiOption option;
  final bool isSelected;
  final Color accent;
  final Color outline;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accent.withValues(alpha: 0.16) : surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? accent.withValues(alpha: 0.32) : outline,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            option.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}
