import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/weekly_report.dart';
import 'weekly_report_screen.dart';

class WeeklyReportHistoryScreen extends StatefulWidget {
  const WeeklyReportHistoryScreen({super.key});
  static const route = WeeklyReportScreen.historyRoute;

  @override
  State<WeeklyReportHistoryScreen> createState() =>
      _WeeklyReportHistoryScreenState();
}

class _WeeklyReportHistoryScreenState extends State<WeeklyReportHistoryScreen> {
  final _items = <WeeklyReportHistoryItem>[];
  DateTime? _cursor;
  WeeklyReportSnapshot? _latest;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _cursor = null;
    });
    try {
      final repo = context.read<WeeklyReportRepository>();
      final latest = await repo.getLatest().catchError((_) => null);
      if (mounted) setState(() => _latest = latest);
      final page = await repo.getHistory(limit: 20);
      if (!mounted) return;
      _append(page);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await context.read<WeeklyReportRepository>().getHistory(
            beforeWeekStart: _cursor,
            limit: 20,
          );
      if (!mounted) return;
      _append(page);
      setState(() {
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = error;
      });
    }
  }

  void _append(WeeklyReportHistoryPage page) {
    final ids = _items.map((item) => item.reportId).toSet();
    for (final item in page.items) {
      if (ids.add(item.reportId)) _items.add(item);
    }
    _items.sort((a, b) => b.week.weekStartDate.compareTo(a.week.weekStartDate));
    _cursor = page.nextBeforeWeekStart;
  }

  @override
  Widget build(BuildContext context) {
    final latestId = _latest?.report.id;
    final previous = _items.where((item) =>
        item.status == WeeklyReportStatus.finalized &&
        item.reportId != latestId);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.weeklyReportHistory),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty && _latest == null
                ? _Message(
                    text: l10n.weeklyReportHistoryError,
                    onRetry: _loadFirstPage)
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    children: [
                      if (_latest != null) ...[
                        _SectionTitle(l10n.weeklyReportThisWeek),
                        _ReportRow(report: _latest!.report, current: true),
                        const SizedBox(height: 16),
                      ],
                      _SectionTitle(l10n.weeklyReportPreviousWeeks),
                      if (previous.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(l10n.weeklyReportNoPreviousWeeks,
                              textAlign: TextAlign.center),
                        )
                      else
                        ...previous.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ReportRow(item: item),
                            )),
                      if (_error != null &&
                          (_items.isNotEmpty || _latest != null))
                        TextButton(
                            onPressed: _loadFirstPage,
                            child: Text(l10n.weeklyReportRetry)),
                      if (_cursor != null)
                        OutlinedButton(
                          onPressed: _loadingMore ? null : _loadMore,
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(l10n.weeklyReportLoadMore),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      );
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({this.item, this.report, this.current = false});
  final WeeklyReportHistoryItem? item;
  final WeeklyReport? report;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final week = report?.week ?? item!.week;
    final rate = report?.summary.completionRate ?? item!.completionRate;
    final completed = report?.summary.completedCount ?? item!.completedCount;
    final scheduled = report?.summary.scheduledCount ?? item!.scheduledCount;
    final rateText = scheduled == 0 || rate == null
        ? context.l10n.weeklyReportNoScheduleShort
        : '${(rate * 100).round()}% · $completed/$scheduled';
    final id = report?.id ?? item!.reportId;
    return Semantics(
      button: true,
      label:
          '${_formatRange(context, week.weekStartDate, week.weekEndDate)}. $rateText. ${context.l10n.weeklyReportViewReport}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => WeeklyReportScreen(
            reportId: id,
            openedFromHistory: true,
          ),
        )),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9E3D9)),
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      _formatRange(
                          context, week.weekStartDate, week.weekEndDate),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(rateText,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF665D53))),
                ])),
            if (current)
              Chip(label: Text(context.l10n.weeklyReportInProgress))
            else
              const Icon(Icons.chevron_right, size: 20),
          ]),
        ),
      ),
    );
  }

  String _formatRange(BuildContext context, DateTime start, DateTime end) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sameMonth = start.month == end.month && start.year == end.year;
    final left = DateFormat(sameMonth ? 'd' : 'd MMM', locale).format(start);
    final right = DateFormat('d MMM', locale).format(end);
    final range = '$left – $right';
    return start.year == end.year ? range : '$range ${end.year}';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Center(child: Text(text)),
          Center(
              child: TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.weeklyReportRetry))),
        ],
      );
}
