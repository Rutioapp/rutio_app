import 'package:flutter/material.dart';

import 'weekly_habit_data_helper.dart';

String buildWeeklyCountPrompt(
  BuildContext context,
  Map<String, dynamic> habit,
) {
  final locale = Localizations.localeOf(context).languageCode.toLowerCase();
  final title =
      (habit['title'] ?? habit['name'] ?? habit['habitName'] ?? '').toString();
  final unit = WeeklyHabitDataHelper.resolveCountUnit(habit);

  if (locale.startsWith('es')) {
    return _buildSpanishCountPrompt(title: title, unit: unit);
  }

  return _buildEnglishCountPrompt(title: title, unit: unit);
}

String _buildSpanishCountPrompt({
  required String title,
  required String unit,
}) {
  final normalizedTitle = title.trim().toLowerCase();
  final normalizedUnit = unit.trim().toLowerCase();
  final combined = '$normalizedTitle $normalizedUnit';

  String participle = 'hecho';
  if (combined.contains('beber') ||
      combined.contains('tomar') ||
      combined.contains('agua') ||
      combined.contains('vaso')) {
    participle = 'tomado';
  } else if (combined.contains('leer') ||
      combined.contains('libro') ||
      combined.contains('pagina') ||
      combined.contains('p\u00E1gina')) {
    participle = 'leido';
  } else if (combined.contains('minuto') ||
      combined.contains('hora') ||
      combined.contains('tiempo')) {
    participle = 'dedicado';
  }

  if (normalizedUnit.isEmpty) {
    if (participle == 'leido') {
      return '\u00BFCu\u00E1nto has le\u00EDdo hoy?';
    }
    if (participle == 'tomado') {
      return '\u00BFCu\u00E1nto has tomado hoy?';
    }
    if (participle == 'dedicado') {
      return '\u00BFCu\u00E1nto tiempo has dedicado hoy?';
    }
    return '\u00BFCu\u00E1nto has hecho hoy?';
  }

  final feminineUnits = <String>{
    'pagina',
    'paginas',
    'p\u00E1gina',
    'p\u00E1ginas',
    'hora',
    'horas',
    'repeticion',
    'repeticiones',
    'serie',
    'series',
  };
  final quantifier =
      feminineUnits.contains(normalizedUnit) ? 'Cu\u00E1ntas' : 'Cu\u00E1ntos';
  final visibleUnit = normalizedUnit
      .replaceAll('p\u00E1gina', 'p\u00E1gina')
      .replaceAll('pagina', 'p\u00E1gina');
  return '\u00BF$quantifier $visibleUnit has $participle hoy?';
}

String _buildEnglishCountPrompt({
  required String title,
  required String unit,
}) {
  final normalizedTitle = title.trim().toLowerCase();
  final normalizedUnit = unit.trim();
  if (normalizedUnit.isNotEmpty) {
    if (normalizedTitle.contains('read') ||
        normalizedUnit.toLowerCase().contains('page')) {
      return 'How many $normalizedUnit have you read today?';
    }
    if (normalizedTitle.contains('drink') ||
        normalizedUnit.toLowerCase().contains('glass')) {
      return 'How many $normalizedUnit have you had today?';
    }
    return 'How many $normalizedUnit have you done today?';
  }

  if (normalizedTitle.contains('read')) {
    return 'How much have you read today?';
  }
  if (normalizedTitle.contains('drink')) {
    return 'How much have you had today?';
  }
  return 'How much have you done today?';
}
