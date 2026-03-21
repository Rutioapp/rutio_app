import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class AvatarSection extends StatelessWidget {
  final ValueListenable<String> avatarPath;
  final VoidCallback onTap;

  const AvatarSection({
    super.key,
    required this.avatarPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: avatarPath,
      builder: (context, path, _) {
        final hasPath = path.trim().isNotEmpty;

        Widget avatarChild;
        if (!hasPath) {
          avatarChild = _buildAvatarPlaceholder(context);
        } else if (path.trim().startsWith('http')) {
          avatarChild = Image.network(
            path.trim(),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context),
          );
        } else {
          final localPath = path.trim().startsWith('file://')
              ? path.trim().substring(7)
              : path.trim();
          avatarChild = Image.file(
            File(localPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context),
          );
        }

        return Column(
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(child: avatarChild),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(
                hasPath
                    ? context.l10n.editProfileChangePhoto
                    : context.l10n.editProfileAddPhoto,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Center(
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
