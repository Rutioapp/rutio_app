import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SecondarySettingsRow extends StatelessWidget {
  const SecondarySettingsRow({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1 : 0.72,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAF6)),
              color: const Color(0xFFFDFDFF),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF2FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.square_arrow_right,
                    size: 18,
                    color: Color(0xFF43507E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A3152),
                    ),
                  ),
                ),
                isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(radius: 8),
                      )
                    : const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 16,
                        color: Color(0xFF92A0C6),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
