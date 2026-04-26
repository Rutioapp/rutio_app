import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'widgets/account_action_settings_row.dart';
import 'widgets/destructive_settings_row.dart';
import 'widgets/section_card.dart';
import 'widgets/settings_language_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final activeLanguageCode = store.preferredLanguageCode ??
        _supportedLanguageCode(Localizations.localeOf(context));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F6FF),
        elevation: 0,
        surfaceTintColor: const Color(0xFFF7F6FF),
        title: Text(context.l10n.settingsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SettingsLanguageSection(
            selectedLanguageCode: activeLanguageCode,
            onLanguageSelected: store.setPreferredLanguageCode,
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.settingsAccountSectionTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: [
                AccountActionSettingsRow(
                  title: context.l10n.settingsLogOut,
                  onTap: () => _handleLogOut(context),
                ),
                const SizedBox(height: 8),
                DestructiveSettingsRow(
                  title: context.l10n.settingsDeleteAccountTitle,
                  onTap: () => _handleDeleteAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              context.l10n.settingsDeleteAccountHelperText,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF7A7A7A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogOut(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('[settings] logout tapped');
    }

    final confirmed = await _showLogOutConfirmation(context);
    if (!confirmed) {
      if (kDebugMode) {
        debugPrint('[settings] logout cancelled');
      }
      return;
    }

    if (!context.mounted) return;
    if (kDebugMode) {
      debugPrint('[settings] post-logout route decision: WelcomeScreen');
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/root', (_) => false);
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await _showDeleteAccountConfirmation(context);
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.settingsDeleteAccountDeleting)),
            ],
          ),
        ),
      ),
    );

    try {
      await context.read<UserStateStore>().deleteAccount();
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsDeleteAccountError)),
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsDeleteAccountSuccess)));

    Navigator.of(context).pushNamedAndRemoveUntil('/root', (_) => false);
  }

  Future<bool> _showDeleteAccountConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;
    final requiredConfirmationWord =
        Localizations.localeOf(context).languageCode == 'es'
            ? 'ELIMINAR'
            : 'DELETE';
    final textController = TextEditingController();

    bool matchesConfirmation() =>
        textController.text.trim().toUpperCase() == requiredConfirmationWord;

    try {
      if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
        final result = await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (modalContext, setModalState) => CupertinoAlertDialog(
              title: Text(l10n.settingsDeleteAccountConfirmationTitle),
              content: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(l10n.settingsDeleteAccountMessage),
                  const SizedBox(height: 12),
                  Text(l10n.settingsDeleteAccountTypeToConfirm),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: textController,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setModalState(() {}),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.commonCancel),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: matchesConfirmation()
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(l10n.settingsDeleteAccountConfirm),
                ),
              ],
            ),
          ),
        );
        return result == true;
      }

      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (modalContext, setModalState) => AlertDialog(
            title: Text(l10n.settingsDeleteAccountConfirmationTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsDeleteAccountMessage),
                const SizedBox(height: 12),
                Text(l10n.settingsDeleteAccountTypeToConfirm),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setModalState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: matchesConfirmation()
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC43C3C),
                ),
                child: Text(l10n.settingsDeleteAccountConfirm),
              ),
            ],
          ),
        ),
      );

      return result == true;
    } finally {
      textController.dispose();
    }
  }

  Future<bool> _showLogOutConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;
    final messenger = ScaffoldMessenger.of(context);
    var isSubmitting = false;

    Future<void> submitLogOut(
      BuildContext actionContext,
      void Function(void Function()) setModalState,
    ) async {
      if (isSubmitting) return;
      setModalState(() => isSubmitting = true);

      if (kDebugMode) {
        debugPrint('[settings] logout confirmed');
      }

      try {
        await context.read<UserStateStore>().clearAuthSessionState();
        if (kDebugMode) {
          debugPrint('[settings] signOut success');
        }
        if (actionContext.mounted) {
          Navigator.of(actionContext).pop(true);
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[settings] signOut failure: $error');
          debugPrintStack(
              label: '[settings] signOut failure', stackTrace: stackTrace);
        }
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsLogOutError)),
        );
        if (actionContext.mounted) {
          setModalState(() => isSubmitting = false);
        }
      }
    }

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (modalContext, setModalState) => CupertinoAlertDialog(
            title: Text(l10n.settingsLogOutTitle),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.settingsLogOutMessage),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: false,
                onPressed: isSubmitting
                    ? null
                    : () => submitLogOut(dialogContext, setModalState),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(),
                      )
                    : Text(l10n.settingsLogOutConfirm),
              ),
            ],
          ),
        ),
      );
      return result == true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => AlertDialog(
          title: Text(l10n.settingsLogOutTitle),
          content: Text(l10n.settingsLogOutMessage),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => submitLogOut(dialogContext, setModalState),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.settingsLogOutConfirm),
            ),
          ],
        ),
      ),
    );

    return result == true;
  }

  String _supportedLanguageCode(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'en';
      case 'es':
      default:
        return 'es';
    }
  }
}
