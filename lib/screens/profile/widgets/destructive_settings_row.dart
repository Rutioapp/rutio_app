import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DestructiveSettingsRow extends StatelessWidget {
  const DestructiveSettingsRow({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0D5D5)),
            color: const Color(0xFFFFFBFB),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEA),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.delete_simple,
                  size: 18,
                  color: Color(0xFFC43C3C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC43C3C),
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: Color(0xFFD09A9A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
