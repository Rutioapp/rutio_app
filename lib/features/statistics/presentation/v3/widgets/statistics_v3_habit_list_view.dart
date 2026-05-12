import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

class StatisticsV3HabitListView extends StatefulWidget {
  const StatisticsV3HabitListView({
    super.key,
    required this.items,
    required this.onHabitTap,
    required this.onPlusTap,
  });

  final List<StatisticsV3HabitListItem> items;
  final ValueChanged<StatisticsV3HabitListItem> onHabitTap;
  final VoidCallback onPlusTap;

  @override
  State<StatisticsV3HabitListView> createState() =>
      _StatisticsV3HabitListViewState();
}

class _StatisticsV3HabitListViewState extends State<StatisticsV3HabitListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFamilyId = '';

  static const Color _titleColor = Color(0xFF573F2E);
  static const Color _cardBorder = Color(0xFFEDE4D8);
  static const Color _metric = Color(0xFF574A3F);
  static const Color _streak = Color(0xFFB87333);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredItems = _filteredItems();
    final familyFilters = _familyFilters(items: widget.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.statisticsV3HabitListTitle,
                style: const TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPlusTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC88E44),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSearchField(l10n),
        const SizedBox(height: 12),
        _buildFamilyFilters(
          l10n: l10n,
          families: familyFilters,
        ),
        const SizedBox(height: 16),
        if (widget.items.isEmpty)
          _HabitListEmptyState(
            title: l10n.statisticsV3HabitListEmptyTitle,
            subtitle: l10n.statisticsV3HabitListEmptySubtitle,
          )
        else if (filteredItems.isEmpty)
          _HabitListEmptyState(
            title: l10n.statisticsV3HabitListNoResultsTitle,
            subtitle: l10n.statisticsV3HabitListNoResultsSubtitle,
          )
        else
          ...filteredItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HabitListCard(
                item: item,
                onTap: () => widget.onHabitTap(item),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _cardBorder),
      ),
      child: TextField(
        key: const Key('statisticsV3HabitSearchField'),
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4F443A),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFFA89C8F),
          ),
          hintText: l10n.statisticsV3HabitListSearchPlaceholder,
          hintStyle: const TextStyle(
            color: Color(0xFFA89C8F),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyFilters({
    required AppLocalizations l10n,
    required List<_HabitFamilyFilter> families,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FamilyChip(
            key: const Key('statisticsV3HabitChip-all'),
            label: l10n.statisticsV3HabitListAllChip,
            selected: _selectedFamilyId.isEmpty,
            onTap: () => setState(() => _selectedFamilyId = ''),
            color: const Color(0xFF6C4022),
          ),
          ...families.map(
            (family) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FamilyChip(
                key: Key('statisticsV3HabitChip-${family.id}'),
                label: family.label,
                selected: _selectedFamilyId == family.id,
                onTap: () => setState(() => _selectedFamilyId = family.id),
                color: family.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_HabitFamilyFilter> _familyFilters({
    required List<StatisticsV3HabitListItem> items,
  }) {
    final byFamily = <String, _HabitFamilyFilter>{};
    for (final item in items) {
      byFamily[item.familyId] = _HabitFamilyFilter(
        id: item.familyId,
        label: item.familyName,
        color: item.familyColor,
      );
    }
    final entries = byFamily.values.toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return entries;
  }

  List<StatisticsV3HabitListItem> _filteredItems() {
    final normalizedSearch = _searchQuery.toLowerCase();
    final byFamily = widget.items.where((item) {
      if (_selectedFamilyId.isEmpty) return true;
      return item.familyId == _selectedFamilyId;
    });
    final bySearch = byFamily.where((item) {
      if (normalizedSearch.isEmpty) return true;
      return item.title.toLowerCase().contains(normalizedSearch);
    });
    return bySearch.toList(growable: false);
  }
}

class _HabitListCard extends StatelessWidget {
  const _HabitListCard({
    required this.item,
    required this.onTap,
  });

  final StatisticsV3HabitListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('statisticsV3HabitCard-${item.habitId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _StatisticsV3HabitListViewState._cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0x332F2418),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _HabitEmojiTile(emoji: item.emoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D3228),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.familyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.familyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A6E63),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.mainMetric,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _StatisticsV3HabitListViewState._metric,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.secondaryMetric,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _StatisticsV3HabitListViewState._streak,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFF978878),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitEmojiTile extends StatelessWidget {
  const _HabitEmojiTile({
    required this.emoji,
  });

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF4F3EE),
            Color(0xFFEAE7DF),
          ],
        ),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 25),
      ),
    );
  }
}

class _FamilyChip extends StatelessWidget {
  const _FamilyChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF6C6055);
    final background = selected ? const Color(0xFF6C4022) : Colors.white;
    final border = selected ? const Color(0xFF6C4022) : const Color(0xFFE6DBCF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background.withValues(alpha: selected ? 1 : 0.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitListEmptyState extends StatelessWidget {
  const _HabitListEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _StatisticsV3HabitListViewState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF43362A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.3,
              color: Color(0xFF72675D),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitFamilyFilter {
  const _HabitFamilyFilter({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}
