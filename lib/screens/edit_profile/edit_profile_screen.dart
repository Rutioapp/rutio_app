import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import '../../utils/app_theme.dart';
import 'edit_profile_controller.dart';
import 'widgets/avatar_section.dart';
import 'widgets/profile_fields.dart';
import 'widgets/stats_row.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController _c;

  @override
  void initState() {
    super.initState();
    _c = EditProfileController();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet(UserStateStore store) async {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: _c.avatarPath,
          builder: (_, avatarPath, __) {
            final hasAvatar = avatarPath.trim().isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(l10n.editProfileTakePhoto),
                  onTap: () {
                    Navigator.pop(ctx);
                    _c.pickAvatar(
                      context: context,
                      source: ImageSource.camera,
                      store: store,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(l10n.editProfileGallery),
                  onTap: () {
                    Navigator.pop(ctx);
                    _c.pickAvatar(
                      context: context,
                      source: ImageSource.gallery,
                      store: store,
                    );
                  },
                ),
                if (hasAvatar)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      l10n.editProfileRemovePhoto,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _c.removeAvatar();
                    },
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    final shouldPop = await _c.onWillPop(context);
    if (shouldPop && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateStore>(
      builder: (context, store, _) {
        final l10n = context.l10n;
        _c.ensureInitFromStore(store);

        return ValueListenableBuilder<bool>(
          valueListenable: _c.hasChanges,
          builder: (context, hasChanges, _) {
            return PopScope(
              canPop: !hasChanges,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                unawaited(_handleBack(context));
              },
              child: Scaffold(
                backgroundColor: AppColors.cream,
                body: store.isLoading && store.state == null
                    ? const Center(child: CircularProgressIndicator())
                    : SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _BackButton(
                                    onTap: () => _handleBack(context),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      l10n.editProfileTitle,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.serifFamily,
                                        fontSize: 20,
                                        height: 1.08,
                                        color: AppColors.ink,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Form(
                                key: _c.formKey,
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    6,
                                    20,
                                    20,
                                  ),
                                  children: [
                                    AvatarSection(
                                      avatarPath: _c.avatarPath,
                                      nameCtrl: _c.nameCtrl,
                                      goalCtrl: _c.goalCtrl,
                                      onTap: () => _showImageSourceSheet(store),
                                    ),
                                    const SizedBox(height: 22),
                                    StatsRow.fromStore(context, store),
                                    const SizedBox(height: 22),
                                    ProfileFields(
                                      nameCtrl: _c.nameCtrl,
                                      bioCtrl: _c.bioCtrl,
                                      onAnyFieldChanged: _c.markChanged,
                                    ),
                                    const SizedBox(height: 22),
                                    ProfileGoalField(
                                      goalCtrl: _c.goalCtrl,
                                      onChanged: _c.markChanged,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                bottomNavigationBar: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _c.saving,
                    builder: (_, saving, __) {
                      return FilledButton.icon(
                        key: const Key('editProfileSaveButton'),
                        onPressed: (saving || !hasChanges)
                            ? null
                            : () => _c.save(context: context, store: store),
                        icon: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          saving
                              ? l10n.editProfileSaving
                              : l10n.editProfileSaveChanges,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: AppColors.earth,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3E8D8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 60,
          height: 60,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 26,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
