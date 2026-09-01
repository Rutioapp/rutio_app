import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/bootstrap/bootstrap_controller.dart';
import '../../../screens/diary_v2/diary_v2_entry_editor_screen.dart';
import '../../../stores/user_state_store.dart';
import '../data/local/shared_preferences_notification_install_id_provider.dart';
import '../domain/journal_nudge_prompt_resolver.dart';
import '../domain/notification_payload.dart';
import '../domain/personalized_notification_models.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

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

  NotificationPayloadV2? _pendingPayload;
  NotificationPayloadV2? _lastConsumedPayload;
  BuildContext? _attachedContext;
  GlobalKey<NavigatorState>? _attachedNavigatorKey;
  bool _drainScheduled = false;
  bool _consuming = false;

  void receiveRawPayload(String? rawPayload) {
    final payload =
        rawPayload == null ? null : NotificationPayloadV2.tryParse(rawPayload);
    if (payload?.kind != NotificationKind.journalNudge) return;
    if (payload == _lastConsumedPayload) return;
    if (_pendingPayload == payload) return;
    _pendingPayload = payload;
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
    if (_pendingPayload == null ||
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
  }

  Future<void> _consumeIfReady(
    BuildContext context,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_consuming || _pendingPayload == null || !context.mounted) return;

    if (_drainForTesting != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      _lastConsumedPayload = payload;
      await _drainForTesting!(payload);
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

    final payload = _pendingPayload!;
    _consuming = true;
    try {
      final userId = store.activeLocalScopeUserId?.trim();
      final storeUserId = store.userId?.trim();
      if (userId == null ||
          userId.isEmpty ||
          storeUserId != userId ||
          store.scopeEpoch != payload.scopeEpoch) {
        _pendingPayload = null;
        _lastConsumedPayload = payload;
        return;
      }

      final installId = await _installIdProvider.getOrCreateInstallId();
      if (!context.mounted) {
        return;
      }
      if (store.scopeEpoch != payload.scopeEpoch ||
          store.activeLocalScopeUserId?.trim() != userId ||
          store.userId?.trim() != storeUserId) {
        _pendingPayload = null;
        _lastConsumedPayload = payload;
        return;
      }
      final scope = NotificationScope(
        userId: userId,
        scopeEpoch: store.scopeEpoch,
        installId: installId,
        locale: store.preferredLocale?.languageCode ?? 'es',
      );
      if (scope.scopeHash != payload.scopeHash) {
        _pendingPayload = null;
        _lastConsumedPayload = payload;
        return;
      }

      _pendingPayload = null;
      _lastConsumedPayload = payload;
      final prompt = _promptResolver.resolve(
        l10n: AppLocalizations.of(context),
        templateId: payload.templateId,
      );
      final date = _dateFromPayload(payload.dateKey);
      await navigator.push(
        CupertinoPageRoute<void>(
          builder: (_) => DiaryV2EntryEditorScreen(
            initialDate: date,
            reflectionPrompt: prompt,
            source: 'journalNudge',
            templateId: payload.templateId,
            journalNudgeContext: _contextForTemplate(payload.templateId),
          ),
        ),
      );
    } finally {
      _consuming = false;
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
}
