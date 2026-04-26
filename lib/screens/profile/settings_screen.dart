import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'widgets/destructive_settings_row.dart';
import 'widgets/secondary_settings_row.dart';
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
            child: AbsorbPointer(
              absorbing: _isSigningOut,
              child: Column(
                children: [
                  SecondarySettingsRow(
                    title: context.l10n.settingsLogoutTitle,
                    onTap: _isSigningOut ? null : _handleSignOut,
                    isLoading: _isSigningOut,
                  ),
                  const SizedBox(height: 10),
                  DestructiveSettingsRow(
                    title: context.l10n.settingsDeleteAccountTitle,
                    onTap: () => _handleDeleteAccount(context),
                  ),
                ],
              ),
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

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;

    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<UserStateStore>();
    final client = Supabase.instance.client;
    final l10n = context.l10n;

    final confirmed = await _showSignOutConfirmation(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSigningOut = true);

    try {
      await client.auth.signOut();
      await store.clearAuthSessionState();
      if (!mounted) return;

      if (client.auth.currentSession != null || client.auth.currentUser != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsLogoutError)),
        );
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLogoutError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
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
      SnackBar(content: Text(l10n.settingsDeleteAccountSuccess)),
    );

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

  Future<bool> _showSignOutConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final result = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: Text(l10n.settingsLogoutTitle),
          message: Text(l10n.settingsLogoutConfirmationBody),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: Text(l10n.settingsLogoutConfirmAction),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
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
