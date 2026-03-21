import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final Color accent;
  final ImageProvider? image;

  const ProfileAvatar({
    super.key,
    required this.accent,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final img = image;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
        image: img == null
            ? null
            : DecorationImage(
                image: img,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
      ),
      child: ClipOval(
        child: img != null
            ? Image(
                image: img,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: 64,
                height: 64,
              )
            : Center(
                child: Icon(Icons.person,
                    size: 34, color: accent.withValues(alpha: 0.7)),
              ),
      ),
    );
  }
}
