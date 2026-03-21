import 'notification_models.dart';

class NotificationCopyLibrary {
  static const String _title = 'Rutio';

  static NotificationCopy habitReminder({
    required String habitId,
    required String habitName,
  }) {
    final trimmed = habitName.trim();
    final variants = trimmed.isEmpty
        ? const <String>[
            'Tu siguiente paso sigue aqui.',
            'Hay un habito esperando tu momento.',
            'Un pequeno gesto tambien cuenta hoy.',
          ]
        : <String>[
            'Tu momento para $trimmed puede empezar ahora.',
            'Hoy le toca a $trimmed.',
            '$trimmed tambien suma cuando lo haces a tu ritmo.',
            'Un paso breve con $trimmed ya cuenta.',
            'Si te viene bien, este es un buen momento para $trimmed.',
          ];

    return NotificationCopy(
      title: _title,
      body: variants[_stableVariantIndex(habitId, variants.length)],
    );
  }

  static NotificationCopy dayClosure({required int pendingHabits}) {
    final variants = pendingHabits > 1
        ? <String>[
            'Aun estas a tiempo de cerrar el dia. Te quedan $pendingHabits habitos pendientes.',
            'El dia aun puede quedar redondo. Quedan $pendingHabits habitos por cerrar.',
            'Todavia puedes dejar el dia en orden. Tienes $pendingHabits habitos pendientes.',
          ]
        : const <String>[
            'Aun estas a tiempo de cerrar el dia.',
            'Todavia puedes darle un buen cierre al dia.',
            'Queda margen para cerrar el dia con calma.',
          ];

    return NotificationCopy(
      title: _title,
      body: variants[pendingHabits % variants.length],
    );
  }

  static NotificationCopy streakRisk({
    required String habitName,
    required int streakLength,
  }) {
    final trimmed = habitName.trim();
    final focus = trimmed.isEmpty ? '' : ' con $trimmed';
    final streak =
        streakLength > 0 ? ' Llevas $streakLength dias seguidos.' : '';
    final variants = <String>[
      'Hoy puedes mantener viva tu racha$focus.$streak',
      'Tu racha sigue abierta$focus.$streak',
      'Si hoy completas$focus, tu racha sigue en pie.$streak',
    ];

    return NotificationCopy(
      title: _title,
      body: variants[streakLength % variants.length],
    );
  }

  static NotificationCopy streakCelebration({
    required String habitName,
    required int milestone,
  }) {
    final trimmed = habitName.trim();
    final focus = trimmed.isEmpty ? '' : ' con $trimmed';
    final variants = <String>[
      'Has alcanzado $milestone dias seguidos$focus.',
      'Otro hito para tu ritmo: $milestone dias seguidos$focus.',
      'Has dado otro paso importante: $milestone dias seguidos$focus.',
    ];

    return NotificationCopy(
      title: _title,
      body: variants[milestone % variants.length],
    );
  }

  static NotificationCopy inactivityReengagement() {
    return const NotificationCopy(
      title: _title,
      body: 'Volver tambien es avanzar.',
    );
  }

  static NotificationCopy dailyMotivation(String body) {
    final trimmed = body.trim();
    return NotificationCopy(
      title: _title,
      body: trimmed.isEmpty
          ? 'Hoy es un buen dia para cuidar tu ritmo.'
          : trimmed,
    );
  }

  static int _stableVariantIndex(String seed, int length) {
    if (length <= 1) return 0;
    return (seed.hashCode & 0x7fffffff) % length;
  }
}
