import 'package:flutter/material.dart';

/// Single source of truth for Rutio family metadata.
///
/// IMPORTANT:
/// - The IDs (keys) MUST remain stable and in English, because they are what you
///   store in habits as `familyId` (e.g. "mind", "body"...).
/// - Only the visible labels (names) should be translated.
class FamilyTheme {
  /// If an unknown familyId arrives, we fallback to this.
  static const String fallbackId = 'mind';

  /// Stable family IDs used across the app + storage.
  static const String mind = 'mind';
  static const String spirit = 'spirit';
  static const String body = 'body';
  static const String emotional = 'emotional';
  static const String social = 'social';
  static const String discipline = 'discipline';
  static const String professional = 'professional';

  static const Map<String, Color> colors = {
    mind: Color(0xFF7C6BAE),         // lavanda cálida
    spirit: Color(0xFF6A9E7F),       // sage verde
    body: Color(0xFFC97048),         // terracota
    emotional: Color(0xFFC4687A),    // rosa viejo
    social: Color(0xFF5A8FAD),       // azul pizarra
    discipline: Color(0xFFC09A3A),   // mostaza dorada
    professional: Color(0xFF6B7D72), // gris verde
  };

  /// Visible labels in Spanish (UI).
  static const Map<String, String> names = {
    mind: 'Mente',
    spirit: 'Espíritu',
    body: 'Cuerpo',
    emotional: 'Emocional',
    social: 'Social',
    discipline: 'Disciplina',
    professional: 'Profesional',
  };

  static const Map<String, String> emojis = {
    mind: '🧠',
    spirit: '🧘',
    body: '💪',
    emotional: '💖',
    social: '🧑‍🤝‍🧑',
    discipline: '🎯',
    professional: '💼',
  };

  /// Ordered list to display in pickers.
  static const List<String> order = [
    mind,
    spirit,
    body,
    emotional,
    social,
    discipline,
    professional,
  ];

  static Color colorOf(String? familyId) =>
      colors[familyId] ?? colors[fallbackId]!;

  static String nameOf(String? familyId) =>
      names[familyId] ?? names[fallbackId]!;

  static String emojiOf(String? familyId) =>
      emojis[familyId] ?? emojis[fallbackId]!;
}