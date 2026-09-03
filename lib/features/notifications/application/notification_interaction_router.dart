import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../../application/bootstrap/bootstrap_controller.dart';
import '../../../screens/diary_v2/diary_v2_entry_editor_screen.dart';
import '../../../stores/user_state_store.dart';
import '../data/local/shared_preferences_notification_install_id_provider.dart';
import '../domain/journal_nudge_prompt_resolver.dart';
import '../domain/notification_payload.dart';
import '../domain/personalized_notification_models.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import '../../weekly_report/domain/weekly_report.dart';
import '../../weekly_report/presentation/screens/weekly_report_history_screen.dart';
import '../../weekly_report/presentation/screens/weekly_report_screen.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationInteractionRouter {
  NotificationInteractionRouter({
    SharedPreferencesNotificationInstallIdProvider? installIdProvider,
    JournalNudgePromptResolver? promptResolver,
    @visibleForTesting
    Future<void> Function(NotificationPayloadV2 payload)? drainForTesting,
  })  : _installIdProvider = installIdProvider ??
            SharedPreferencesNotificationInstallIdProvider(),
        _promptResolver = promptResolver ?? const JournalNudgePromptResolver(),
        _drainForTesting = drainForTesting;

  final SharedPreferencesNotificationInstallIdProvider _installIdProvider;
  final JournalNudgePromptResolver _promptResolver;
  final Future<void> Function(NotificationPayloadV2 payload)? _drainForTesting;

  final List<_PendingInteraction> _pendingInteractions =
      <_PendingInteraction>[];
  String? _lastConsumedInteractionKey;
  DateTime? _lastConsumedAt;
  BuildContext? _attachedContext;
  GlobalKey<NavigatorState>? _attachedNavigatorKey;
  bool _drainScheduled = false;
  bool _consuming = false;
  static const Duration _duplicateWindow = Duration(seconds: 5);

  void receiveNotificationResponse(
    NotificationResponse response, {
    String source = 'foreground',
  }) {
    receiveRawPayload(
      response.payload,
      platformId: response.id,
      source: source,
    );
  }

  void receiveRawPayload(
    String? rawPayload, {
    int? platformId,
    String source = 'foreground',
  }) {
    final payload =
        rawPayload == null ? null : NotificationPayloadV2.tryParse(rawPayload);
    if (payload?.kind != NotificationKind.journalNudge &&
        payload?.kind != NotificationKind.futureWeeklyReport) return;
    final interactionKey =
        '${platformId ?? "raw"}|${_payloadFingerprint(rawPayload!)}';
    final now = DateTime.now();
    final dedupeHit = _lastConsumedInteractionKey == interactionKey &&
        _lastConsumedAt != null &&
        now.difference(_lastConsumedAt!).abs() <= _duplicateWindow;
    _interactionLog(
      'received interactionKey=$interactionKey route=${payload!.route} '
      'source=$source dedupeHit=$dedupeHit',
    );
    if (dedupeHit) return;
    if (_pendingInteractions.any(
      (interaction) => interaction.key == interactionKey,
    )) {
      return;
    }
    _pendingInteractions.add(_PendingInteraction(
      payload: payload,
      key: interactionKey,
      source: source,
      platformId: platformId,
    ));
    _interactionLog('queued interactionKey=$interactionKey');
    _scheduleDrainIfAttached();
  }

  void attach(BuildContext context, GlobalKey<NavigatorState> navigatorKey) {
    _attachedContext = context;
    _attachedNavigatorKey = navigatorKey;
    _scheduleDrainIfAttached();
  }

  void _scheduleDrainIfAttached() {
    final context = _attachedContext;
    final navigatorKey = _attachedNavigatorKey;
    if (_pendingInteractions.isEmpty ||
        _drainScheduled ||
        _consuming ||
        context == null ||
        navigatorKey == null ||
        !context.mounted) {
      return;
    }
    _drainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainScheduled = false;
      final currentContext = _attachedContext;
      final currentNavigatorKey = _attachedNavigatorKey;
      if (currentContext == null || currentNavigatorKey == null) return;
      unawaited(_consumeIfReady(currentContext, currentNavigatorKey));
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _consumeIfReady(
    BuildContext context,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_consuming || _pendingInteractions.isEmpty || !context.mounted) {
      return;
    }
    final interaction = _pendingInteractions.first;
    final payload = interaction.payload;
    _interactionLog('drain start interactionKey=${interaction.key}');

    if (_drainForTesting != null) {
      _consuming = true;
      try {
        _pendingInteractions.removeAt(0);
        _markConsumed(interaction.key);
        await _drainForTesting!(payload);
        _interactionLog('processed interactionKey=${interaction.key}');
      } finally {
        _consuming = false;
        _scheduleDrainIfAttached();
      }
      return;
    }

    final bootstrap = context.read<BootstrapController>();
    final store = context.read<UserStateStore>();
    final navigator = navigatorKey.currentState;
    if (!bootstrap.state.isReady ||
        bootstrap.state.destination != BootstrapDestination.home ||
        store.isLoading ||
        store.state == null ||
        navigator == null ||
        !navigator.mounted) {
      return;
    }

    _consuming = true;
    try {
      final userId = store.activeLocalScopeUserId?.trim();
      final storeUserId = store.userId?.trim();
      if (userId == null ||
          userId.isEmpty ||
          storeUserId != userId ||
          store.scopeEpoch != payload.scopeEpoch) {
        _pendingInteractions.removeAt(0);
        _markConsumed(interaction.key);
        return;
      }

      final installId = await _installIdProvider.getOrCreateInstallId();
      if (!context.mounted) {
        return;
      }
      if (store.scopeEpoch != payload.scopeEpoch ||
          store.activeLocalScopeUserId?.trim() != userId ||
          store.userId?.trim() != storeUserId) {
        _pendingInteractions.removeAt(0);
        _markConsumed(interaction.key);
        return;
      }
      final scope = NotificationScope(
        userId: userId,
        scopeEpoch: store.scopeEpoch,
        installId: installId,
        locale: store.preferredLocale?.languageCode ?? 'es',
      );
      if (scope.scopeHash != payload.scopeHash) {
        _pendingInteractions.removeAt(0);
        _markConsumed(interaction.key);
        return;
      }

      _pendingInteractions.removeAt(0);
      _markConsumed(interaction.key);
      _interactionLog('processed interactionKey=${interaction.key}');
      final prompt = _promptResolver.resolve(
        l10n: AppLocalizations.of(context),
        templateId: payload.templateId,
      );
      if (payload.kind == NotificationKind.futureWeeklyReport) {
        final weekStart = _dateFromPayload(payload.dateKey);
        if (weekStart == null) return;
        _weeklyRouteLog('received weekStart=${payload.dateKey}');
        final repository = context.read<WeeklyReportRepository>();
        var snapshot = await repository.getByWeekStart(weekStart);
        if (snapshot == null && await _isCurrentWeek(store, weekStart)) {
          try {
            snapshot = await repository.refreshProvisional(weekStart);
          } catch (_) {
            snapshot = null;
          }
        }
        if (!context.mounted) return;
        if (snapshot != null) {
          _weeklyRouteLog('resolved weekStart=${payload.dateKey}');
          _weeklyRouteLog('navigate weekStart=${payload.dateKey}');
          await navigator.pushNamed(
            '${WeeklyReportScreen.reportRoutePrefix}${Uri.encodeComponent(snapshot.report.id)}',
          );
        } else {
          _weeklyRouteLog('resolved weekStart=${payload.dateKey} unavailable');
          _weeklyRouteLog('navigate history');
          await navigator.pushNamed(WeeklyReportHistoryScreen.route);
        }
        return;
      }
      final date = _dateFromPayload(payload.dateKey);
      await navigator.push(CupertinoPageRoute<void>(
        builder: (_) => DiaryV2EntryEditorScreen(
          initialDate: date,
          reflectionPrompt: prompt,
          source: 'journalNudge',
          templateId: payload.templateId,
          journalNudgeContext: _contextForTemplate(payload.templateId),
        ),
      ));
    } finally {
      _consuming = false;
      _scheduleDrainIfAttached();
    }
  }

  DateTime? _dateFromPayload(String? dateKey) {
    final parsed = dateKey == null ? null : DateTime.tryParse(dateKey);
    return parsed == null ? null : DateUtils.dateOnly(parsed);
  }

  String _contextForTemplate(String templateId) {
    if (templateId.contains('.milestone.')) return 'habitMilestone';
    if (templateId.contains('.perfect_day.')) return 'perfectDay';
    return 'endOfDay';
  }

  void _markConsumed(String interactionKey) {
    _lastConsumedInteractionKey = interactionKey;
    _lastConsumedAt = DateTime.now();
  }

  String _payloadFingerprint(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }

  void _interactionLog(String message) {
    if (kDebugMode) debugPrint('[NOTIF_INTERACTION] $message');
  }

  void _weeklyRouteLog(String message) {
    if (kDebugMode) debugPrint('[WEEKLY_REPORT_ROUTE] $message');
  }

  Future<bool> _isCurrentWeek(UserStateStore store, DateTime weekStart) async {
    final timezone = await store.getLocalIanaTimeZone();
    if (timezone == null || timezone.trim().isEmpty) return false;
    tzdata.initializeTimeZones();
    final local =
        tz.TZDateTime.from(DateTime.now().toUtc(), tz.getLocation(timezone));
    final current = DateTime(local.year, local.month, local.day)
        .subtract(Duration(days: local.weekday - 1));
    return DateUtils.dateOnly(weekStart) == DateUtils.dateOnly(current);
  }
}

class _PendingInteraction {
  const _PendingInteraction({
    required this.payload,
    required this.key,
    required this.source,
    required this.platformId,
  });

  final NotificationPayloadV2 payload;
  final String key;
  final String source;
  final int? platformId;
}
