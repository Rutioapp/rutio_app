import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'section_card.dart';

class SettingsLanguageSection extends StatelessWidget {
  const SettingsLanguageSection({
    super.key,
    required this.selectedLanguageCode,
    required this.onLanguageSelected,
  });

  final String selectedLanguageCode;
  final Future<void> Function(String languageCode) onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.settingsLanguageSectionTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            children: [
              _LanguageOptionTile(
                title: context.l10n.settingsLanguageOptionSpanish,
                isSelected: selectedLanguageCode == 'es',
                onTap: () => onLanguageSelected('es'),
              ),
              const SizedBox(height: 10),
              _LanguageOptionTile(
                title: context.l10n.settingsLanguageOptionEnglish,
                isSelected: selectedLanguageCode == 'en',
                onTap: () => onLanguageSelected('en'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFEFEFEF),
            width: isSelected ? 1.4 : 1,
          ),
          color: isSelected ? const Color(0xFFF1EEFF) : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF2E236C)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF6C5CE7)
                  : const Color(0xFFB8B8B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
