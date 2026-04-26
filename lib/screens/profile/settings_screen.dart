import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'widgets/account_action_settings_row.dart';
import 'widgets/destructive_settings_row.dart';
import 'widgets/section_card.dart';
import 'widgets/settings_language_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSigningOut = false;

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
                  title: context.l10n.settingsLogoutTitle,
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
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    final confirmed = await _showLogoutConfirmation(context);
    if (!confirmed) {
      if (context.mounted) {
        setState(() => _isSigningOut = false);
      }
      return;
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await context.read<UserStateStore>().clearAuthSessionState();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsLogoutError)),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await _showDeleteAccountConfirmation(context);
    if (!confirmed || !context.mounted) return;

    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    var isLoadingDialogOpen = false;

    void closeLoadingDialog() {
      if (!isLoadingDialogOpen) return;
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      isLoadingDialogOpen = false;
    }

    showDialog<void>(
      context: context,
      useRootNavigator: true,
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
    isLoadingDialogOpen = true;

    try {
      await context.read<UserStateStore>().deleteAccount();
      closeLoadingDialog();
      if (!context.mounted) return;
      navigator.pushNamedAndRemoveUntil('/welcome', (_) => false);
    } catch (_) {
      closeLoadingDialog();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsDeleteAccountError)),
        );
      }
    } finally {
      closeLoadingDialog();
    }
  }

  Future<bool> _showDeleteAccountConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;
    final requiredConfirmationWord =
        Localizations.localeOf(context).languageCode == 'es'
            ? 'ELIMINAR'
            : 'DELETE';
    var confirmationInput = '';

    bool matchesConfirmation() =>
        confirmationInput.trim().toUpperCase() == requiredConfirmationWord;

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
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    confirmationInput = value;
                    setModalState(() {});
                  },
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
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  confirmationInput = value;
                  setModalState(() {});
                },
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
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.settingsLogoutTitle),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.settingsLogoutConfirmationBody),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settingsLogoutConfirmAction),
            ),
          ],
        ),
      );
      return result == true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsLogoutTitle),
        content: Text(l10n.settingsLogoutConfirmationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsLogoutConfirmAction),
          ),
        ],
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
