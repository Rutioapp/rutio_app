import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../application/weekly_report_controller.dart';
import '../../domain/weekly_report.dart';
import '../widgets/weekly_report_habits_section.dart';
import '../weekly_report_copy_resolver.dart';
import '../widgets/weekly_report_recommendation.dart';
import '../widgets/weekly_report_reflection.dart';
import '../weekly_report_visuals.dart';
import 'weekly_report_history_screen.dart';
import '../../../../stores/user_state_store.dart';
import '../../../../screens/habit_detail/habit_detail_screen.dart';
import '../../../../utils/family_theme.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({
    super.key,
    this.reportId,
    this.openedFromHistory = false,
  });
  static const route = '/weekly-report';
  static const historyRoute = '/weekly-report/history';
  static const reportRoutePrefix = '/weekly-report/';
  final String? reportId;
  final bool openedFromHistory;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final store = context.read<UserStateStore>();
        return WeeklyReportController(
          context.read<WeeklyReportRepository>(),
          timeZoneResolver: store.getLocalIanaTimeZone,
          refreshCurrentOnLoad: true,
        )..load(reportId: reportId);
      },
      child: _WeeklyReportView(openedFromHistory: openedFromHistory),
    );
  }
}

class _WeeklyReportView extends StatefulWidget {
  const _WeeklyReportView({required this.openedFromHistory});
  final bool openedFromHistory;

  @override
  State<_WeeklyReportView> createState() => _WeeklyReportViewState();
}

class _WeeklyReportViewState extends State<_WeeklyReportView> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<WeeklyReportController>().state;
    final controller = context.read<WeeklyReportController>();
    return Scaffold(
      backgroundColor: WeeklyReportVisuals.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        iconTheme: const IconThemeData(size: 22),
        leading: const BackButton(),
        centerTitle: true,
        title: Text(context.l10n.weeklyReportTitle,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: WeeklyReportVisuals.text)),
        actions: widget.openedFromHistory
            ? null
            : [
                IconButton(
                  key: const Key('weeklyReportHistoryAction'),
                  tooltip: context.l10n.weeklyReportHistory,
                  icon: const Icon(Icons.history_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pushNamed(
                    WeeklyReportHistoryScreen.route,
                  ),
                ),
              ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          WeeklyReportLoading() => const _LoadingView(),
          WeeklyReportEmpty() => _EmptyView(
              onRetry: controller.load,
            ),
          WeeklyReportFailure() => _ErrorView(
              onRetry: controller.load,
            ),
          WeeklyReportDataState() => _ReportContent(
              snapshot: state.snapshot,
            ),
        },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.snapshot,
  });
  final WeeklyReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final report = snapshot.report;
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: context.read<WeeklyReportController>().refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          _WeekRange(week: report.week, isFinal: report.isFinal),
          if (snapshot.isStale) _OfflineBanner(cachedAt: snapshot.cachedAt),
          if (report.isProvisional) const _ProvisionalBanner(),
          if (report.firstPartialWeek) const _FirstWeekBanner(),
          const SizedBox(height: 8),
          _SummaryCard(report: report),
          const SizedBox(height: 8),
          _ChartsCard(report: report),
          if (report.habits.isNotEmpty) ...[
            const SizedBox(height: 10),
            WeeklyReportHabitsSection(habits: report.habits),
          ],
          if (report.isFinal && report.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            WeeklyReportRecommendationCard(
              recommendation: report.recommendations.first,
              habit: _habitFor(report, report.recommendations.first.habitId),
              onReview: () =>
                  _openRecommendation(context, report.recommendations.first),
            ),
          ],
          if (report.isFinal) ...[
            const SizedBox(height: 8),
            WeeklyReportReflection(
              reportId: report.id,
              weekEnd: report.week.weekEndDate,
            ),
          ],
          if (!report.summary.hasScheduledCount)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(l10n.weeklyReportNoScheduled,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF746A60))),
            ),
        ],
      ),
    );
  }

  WeeklyReportHabit? _habitFor(WeeklyReport report, String? id) {
    for (final habit in report.habits) {
      if (habit.habitId == id) return habit;
    }
    return null;
  }

  void _openRecommendation(
      BuildContext context, WeeklyReportRecommendation recommendation) {
    final id = recommendation.habitId;
    if (id == null) return;
    final store = context.read<UserStateStore>();
    final live = store.getActiveHabitById(id);
    if (live == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => HabitDetailScreen(
              habit: live,
              familyColor: FamilyTheme.colorOf(FamilyTheme.fallbackId),
              mode: HabitDetailScreenMode.editOnly,
              proposedPatch: recommendation.proposedPatch,
            )));
  }
}

class _WeekRange extends StatelessWidget {
  const _WeekRange({required this.week, required this.isFinal});
  final dynamic week;
  final bool isFinal;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final start = week.weekStartDate as DateTime;
    final end = week.weekEndDate as DateTime;
    final months = <String>[
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    final monthStart =
        locale == 'es' ? months[start.month] : _month(start.month);
    final monthEnd = locale == 'es' ? months[end.month] : _month(end.month);
    final range = start.month == end.month
        ? '${start.day} – ${end.day} $monthEnd'
        : '${start.day} $monthStart – ${end.day} $monthEnd';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(range,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF173D2C))),
        if (isFinal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: WeeklyReportVisuals.stableSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: WeeklyReportVisuals.success.withValues(alpha: .3)),
            ),
            child: Text(context.l10n.weeklyReportFinalLabel,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: WeeklyReportVisuals.successStrong)),
          ),
      ]),
    );
  }

  String _month(int month) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][month];
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});
  final WeeklyReport report;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = report.summary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: WeeklyReportVisuals.stableSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    size: 18, color: WeeklyReportVisuals.successStrong),
              ),
              const SizedBox(width: 8),
              Text(l10n.weeklyReportSummary,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: WeeklyReportVisuals.text)),
            ]),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(WeeklyReportCopyResolver.summary(l10n, report),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF5F554A))),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _Metric(
                      icon: Icons.check_circle_outline,
                      value: '${summary.completedCount}',
                      label: l10n.weeklyReportCompleted)),
              const _Divider(),
              Expanded(
                  child: _Metric(
                      icon: Icons.percent,
                      value: summary.completionRate == null
                          ? '—'
                          : '${(summary.completionRate! * 100).round()}%',
                      label: l10n.weeklyReportCompletion)),
              const _Divider(),
              Expanded(
                  child: _Metric(
                      icon: Icons.star_border,
                      value: summary.bestDay == null
                          ? '—'
                          : context.l10n
                              .weekdayFull(summary.bestDay!.date.weekday),
                      label: l10n.weeklyReportBestDay)),
            ]),
            if (report.trend.kind != WeeklyReportTrendKind.unavailable) ...[
              const SizedBox(height: 6),
              Text(_trendLabel(context, report.trend),
                  style: const TextStyle(
                      color: WeeklyReportVisuals.successStrong,
                      fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
        const Positioned(
            top: -8, right: -10, child: WeeklyReportBotanicalDecoration()),
      ]),
    );
  }

  String _trendLabel(BuildContext context, WeeklyReportTrend trend) {
    final l10n = context.l10n;
    return trend.kind == WeeklyReportTrendKind.stable
        ? l10n.weeklyReportTrendStable
        : '${trend.delta >= 0 ? '+' : ''}${(trend.delta * 100).round()}% ${l10n.weeklyReportTrendCompared}';
  }
}

class _ChartsCard extends StatelessWidget {
  const _ChartsCard({required this.report});
  final WeeklyReport report;
  @override
  Widget build(BuildContext context) =>
      _Card(child: LayoutBuilder(builder: (context, c) {
        final stacked = c.maxWidth < 350;
        final ring = _CompletionRing(report: report);
        final bars = _DailyBars(days: report.days);
        return stacked
            ? Column(children: [
                ring,
                const SizedBox(height: 8),
                SizedBox(height: 145, child: bars)
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: c.maxWidth * .38, child: ring),
                const SizedBox(width: 10),
                Expanded(child: SizedBox(height: 145, child: bars))
              ]);
      }));
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.report});
  final WeeklyReport report;
  @override
  Widget build(BuildContext context) {
    final rate = report.summary.completionRate;
    final label = rate == null
        ? context.l10n.weeklyReportNoScheduled
        : '${(rate * 100).round()}%';
    return Semantics(
        label: rate == null
            ? context.l10n.weeklyReportNoScheduled
            : '${(rate * 100).round()}% ${context.l10n.weeklyReportCompletion}, ${report.summary.completedCount} ${context.l10n.weeklyReportOf} ${report.summary.scheduledCount}',
        child: Column(children: [
          Text(context.l10n.weeklyReportCompletion,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SizedBox(
              width: 94,
              height: 94,
              child: CustomPaint(
                  painter: _RingPainter(rate),
                  child: Center(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF173D2C))))))
        ]));
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.days});
  final List<WeeklyReportDay> days;
  @override
  Widget build(BuildContext context) {
    final byDay = {for (final day in days) day.date.weekday: day};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.l10n.weeklyReportDaily,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Expanded(
          child: Semantics(
              container: true,
              label: context.l10n.weeklyReportDaily,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final day = byDay[i + 1];
                    return _DayBar(
                        day: day,
                        label: context.l10n.weekdayLetter(i + 1),
                        fullLabel: context.l10n.weekdayFull(i + 1));
                  }))))
    ]);
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar(
      {required this.day, required this.label, required this.fullLabel});
  final WeeklyReportDay? day;
  final String label;
  final String fullLabel;
  @override
  Widget build(BuildContext context) {
    final d = day;
    final noPlan = d == null ||
        d.state == WeeklyReportDayState.noPlan ||
        d.scheduledCount == 0;
    final completionRate = d?.completionRate;
    final fraction = noPlan ? 0.0 : (completionRate ?? 0).clamp(0.0, 1.0);
    final semantics = noPlan
        ? '$fullLabel, ${context.l10n.weeklyReportNoScheduled}'
        : '$fullLabel, ${d.completedCount} ${context.l10n.weeklyReportOf} ${d.scheduledCount} ${context.l10n.weeklyReportCompleted}';
    return Semantics(
        label: semantics,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      width: 18,
                      height: 76 * (noPlan ? .08 : math.max(.08, fraction)),
                      decoration: BoxDecoration(
                          color: WeeklyReportVisuals.barColor(
                            noPlan
                                ? WeeklyReportVisualBarState.noPlan
                                : WeeklyReportVisualBarState.planned,
                            completionRate,
                          ),
                          border: noPlan
                              ? null
                              : Border.all(
                                  color: WeeklyReportVisuals.completionColor(
                                      completionRate),
                                  width: .5),
                          borderRadius: BorderRadius.circular(7))))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10))
        ]));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(10),
      decoration: WeeklyReportVisuals.cardDecoration(),
      child: child);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 20, color: WeeklyReportVisuals.success),
        const SizedBox(height: 3),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WeeklyReportVisuals.text)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF5F554A)))
      ]);
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 50, color: WeeklyReportVisuals.divider);
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.rate);
  final double? rate;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = WeeklyReportVisuals.neutral;
    canvas.drawArc(rect.deflate(8), -math.pi / 2, math.pi * 2, false, p);
    if (rate != null) {
      final progressRect = rect.deflate(8);
      p.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          WeeklyReportVisuals.completionColor(rate),
          Color.lerp(WeeklyReportVisuals.completionColor(rate), Colors.white,
                  .12) ??
              WeeklyReportVisuals.completionColor(rate),
        ],
      ).createShader(progressRect);
      canvas.drawArc(rect.deflate(8), -math.pi / 2,
          math.pi * 2 * rate!.clamp(0, 1), false, p);
      p.shader = null;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rate != rate;
}

class _ProvisionalBanner extends StatelessWidget {
  const _ProvisionalBanner();
  @override
  Widget build(BuildContext context) => _Banner(
      icon: Icons.sync, text: context.l10n.weeklyReportProvisionalMessage);
}

class _FirstWeekBanner extends StatelessWidget {
  const _FirstWeekBanner();
  @override
  Widget build(BuildContext context) => _Banner(
      icon: Icons.wb_sunny_outlined, text: context.l10n.weeklyReportFirstWeek);
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.cachedAt});
  final DateTime? cachedAt;
  @override
  Widget build(BuildContext context) => _Banner(
      icon: Icons.cloud_off_outlined, text: context.l10n.weeklyReportOffline);
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: WeeklyReportVisuals.stableSoft.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: WeeklyReportVisuals.success.withValues(alpha: .2))),
      child: Row(children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: WeeklyReportVisuals.surface.withValues(alpha: .78),
              shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: WeeklyReportVisuals.successStrong),
        ),
        const SizedBox(width: 7),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: WeeklyReportVisuals.text,
                    fontWeight: FontWeight.w500)))
      ]));
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _MessageView(
        title: context.l10n.weeklyReportEmpty,
        button: context.l10n.weeklyReportRetry,
        onRetry: onRetry,
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _MessageView(
        title: context.l10n.weeklyReportError,
        button: context.l10n.weeklyReportRetry,
        onRetry: onRetry,
      );
}

class _MessageView extends StatelessWidget {
  const _MessageView(
      {required this.title, required this.button, required this.onRetry});
  final String title, button;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: Text(button)),
          ])));
}
