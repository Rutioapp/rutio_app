import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'edit_profile_controller.dart';
import 'widgets/avatar_section.dart';
import 'widgets/profile_fields.dart';
import 'widgets/section_header.dart';
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

  Future<void> _showImageSourceSheet() async {
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
                    _c.pickAvatar(context: context, source: ImageSource.camera);
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
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                final shouldPop = await _c.onWillPop(context);
                if (shouldPop && context.mounted) Navigator.pop(context);
              },
              child: Scaffold(
                appBar: AppBar(
                  title: Text(l10n.editProfileTitle),
                  actions: [
                    if (hasChanges)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _c.saving,
                          builder: (_, saving, __) {
                            return TextButton.icon(
                              onPressed: saving
                                  ? null
                                  : () =>
                                      _c.save(context: context, store: store),
                              icon: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(l10n.editProfileSave),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                body: (store.isLoading && store.state == null)
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                        key: _c.formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            AvatarSection(
                              avatarPath: _c.avatarPath,
                              onTap: _showImageSourceSheet,
                            ),
                            const SizedBox(height: 24),
                            StatsRow.fromStore(store),
                            const SizedBox(height: 32),
                            SectionHeader(
                              icon: Icons.person_outline,
                              title: l10n.editProfilePersonalInfoTitle,
                            ),
                            const SizedBox(height: 16),
                            ProfileFields(
                              nameCtrl: _c.nameCtrl,
                              bioCtrl: _c.bioCtrl,
                              onAnyFieldChanged: _c.markChanged,
                            ),
                            const SizedBox(height: 32),
                            SectionHeader(
                              icon: Icons.flag_outlined,
                              title: l10n.editProfileGoalSectionTitle,
                            ),
                            const SizedBox(height: 16),
                            ProfileGoalField(
                              goalCtrl: _c.goalCtrl,
                              onChanged: _c.markChanged,
                            ),
                            const SizedBox(height: 32),
                            ValueListenableBuilder<bool>(
                              valueListenable: _c.saving,
                              builder: (_, saving, __) {
                                return FilledButton.icon(
                                  onPressed: (saving || !hasChanges)
                                      ? null
                                      : () => _c.save(
                                            context: context,
                                            store: store,
                                          ),
                                  icon: saving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_rounded),
                                  label: Text(
                                    saving
                                        ? l10n.editProfileSaving
                                        : l10n.editProfileSaveChanges,
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
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
