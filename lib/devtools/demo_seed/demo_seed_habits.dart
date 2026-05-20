import 'demo_seed_dates.dart';

class DemoSeedHabit {
  const DemoSeedHabit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.familyId,
    required this.type,
    required this.target,
    required this.schedule,
    required this.createdAt,
    this.unit,
    this.archived = false,
    this.archivedOn,
    this.preferredHour = 9,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
  final String familyId;
  final String type;
  final num target;
  final String? unit;
  final Map<String, dynamic> schedule;
  final DateTime createdAt;
  final bool archived;
  final DateTime? archivedOn;
  final int preferredHour;

  String get createdAtKey => DemoSeedDates.dateKey(DemoSeedDates.dateOnly(createdAt));

  bool get isCount => type == 'count';
}

class DemoSeedHabits {
  const DemoSeedHabits._();

  static List<DemoSeedHabit> build({required DateTime now}) {
    final today = DemoSeedDates.dateOnly(now.toLocal());
    final recentCreated = today.subtract(const Duration(days: 4));
    final archivedOn = today.subtract(const Duration(days: 58));
    final archivedCreated = DemoSeedDates.firstDayOfMonthMonthsBack(
      now: today,
      monthsBack: 5,
    ).add(const Duration(days: 9));

    return <DemoSeedHabit>[
      DemoSeedHabit(
        id: 'demo_habit_meditation',
        name: 'Meditación',
        emoji: '🧘',
        description: 'Respirar y observar 10 minutos',
        familyId: 'mind',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ),
        preferredHour: 7,
      ),
      DemoSeedHabit(
        id: 'demo_habit_journal',
        name: 'Diario personal',
        emoji: '📓',
        description: 'Escribir 3 líneas del día',
        familyId: 'emotional',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ).add(const Duration(days: 2)),
        preferredHour: 21,
      ),
      DemoSeedHabit(
        id: 'demo_habit_gym',
        name: 'Gimnasio',
        emoji: '🏋️',
        description: 'Entrenamiento de fuerza',
        familyId: 'body',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{
          'type': 'timesPerWeek',
          'timesPerWeek': 3,
          'weekStartsOn': 1,
        },
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ).add(const Duration(days: 4)),
        preferredHour: 17,
      ),
      DemoSeedHabit(
        id: 'demo_habit_walk_focus',
        name: 'Caminar sin mirar el móvil durante media hora',
        emoji: '🚶',
        description: 'Paseo consciente sin pantalla',
        familyId: 'discipline',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{
          'type': 'weekly',
          'weekdays': <int>[1, 3, 5],
        },
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ).add(const Duration(days: 6)),
        preferredHour: 19,
      ),
      DemoSeedHabit(
        id: 'demo_habit_sleep_early',
        name: 'Dormir antes de las 23:30',
        emoji: '🌙',
        description: 'Apagar pantallas antes de dormir',
        familyId: 'spirit',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ).add(const Duration(days: 1)),
        preferredHour: 22,
      ),
      DemoSeedHabit(
        id: 'demo_habit_tidy',
        name: 'Ordenar 10 minutos',
        emoji: '🧹',
        description: 'Orden rápido de casa',
        familyId: 'professional',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 4,
        ),
        preferredHour: 20,
      ),
      DemoSeedHabit(
        id: 'demo_habit_call_someone',
        name: 'Llamar a alguien importante',
        emoji: '📞',
        description: 'Conectar sin prisa',
        familyId: 'social',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{
          'type': 'weekly',
          'weekdays': <int>[2, 6],
        },
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 3,
        ),
        preferredHour: 18,
      ),
      DemoSeedHabit(
        id: 'demo_habit_plan_next_day',
        name: 'Preparar el día siguiente',
        emoji: '🗓️',
        description: 'Dejar claro el plan de mañana',
        familyId: 'professional',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: recentCreated,
        preferredHour: 22,
      ),
      DemoSeedHabit(
        id: 'demo_habit_water',
        name: 'Beber agua',
        emoji: '💧',
        description: 'Vasos de agua durante el día',
        familyId: 'body',
        type: 'count',
        target: 8,
        unit: 'vasos',
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ),
        preferredHour: 13,
      ),
      DemoSeedHabit(
        id: 'demo_habit_read',
        name: 'Leer',
        emoji: '📚',
        description: 'Lectura de enfoque',
        familyId: 'mind',
        type: 'count',
        target: 20,
        unit: 'páginas',
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ).add(const Duration(days: 1)),
        preferredHour: 21,
      ),
      DemoSeedHabit(
        id: 'demo_habit_deep_study',
        name: 'Estudio profundo',
        emoji: '🧠',
        description: 'Bloque sin distracciones',
        familyId: 'mind',
        type: 'count',
        target: 60,
        unit: 'min',
        schedule: const <String, dynamic>{
          'type': 'weekly',
          'weekdays': <int>[1, 2, 3, 4, 5],
        },
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 4,
        ).add(const Duration(days: 7)),
        preferredHour: 15,
      ),
      DemoSeedHabit(
        id: 'demo_habit_steps',
        name: 'Pasos',
        emoji: '👟',
        description: 'Movimiento diario',
        familyId: 'discipline',
        type: 'count',
        target: 8000,
        unit: 'pasos',
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: DemoSeedDates.firstDayOfMonthMonthsBack(
          now: today,
          monthsBack: 5,
        ),
        preferredHour: 18,
      ),
      DemoSeedHabit(
        id: 'demo_habit_stretch_archived',
        name: 'Estirar espalda',
        emoji: '🧍',
        description: 'Movilidad suave en casa',
        familyId: 'body',
        type: 'check',
        target: 1,
        schedule: const <String, dynamic>{'type': 'daily'},
        createdAt: archivedCreated,
        archived: true,
        archivedOn: archivedOn,
        preferredHour: 8,
      ),
    ];
  }

  static List<Map<String, dynamic>> asStateActiveHabits(
    List<DemoSeedHabit> habits,
  ) {
    return habits
        .map(
          (habit) => <String, dynamic>{
            'id': habit.id,
            'createdAt': habit.createdAtKey,
            'name': habit.name,
            'emoji': habit.emoji,
            'description': habit.description,
            'familyId': habit.familyId,
            'allFamilies': false,
            'type': habit.type,
            if (habit.unit != null) 'unit': habit.unit,
            'target': habit.isCount ? habit.target : 1,
            'progress': 0,
            'doneToday': false,
            'skippedToday': false,
            'schedule': Map<String, dynamic>.from(habit.schedule),
            'isCustom': true,
            if (habit.archived) 'archived': true,
          },
        )
        .toList(growable: false);
  }
}
