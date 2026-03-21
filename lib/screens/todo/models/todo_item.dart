import 'todo_priority.dart';
import 'todo_type.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.notes,
    required this.createdAt,
    required this.categoryId,
    required this.priority,
    required this.type,
    this.dueDate,
    this.linkedHabitId,
    this.xpReward,
    this.hasTime = false,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final String notes;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool hasTime;
  final bool isCompleted;
  final String categoryId;
  final TodoPriority priority;
  final TodoType type;
  final String? linkedHabitId;
  final int? xpReward;

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? hasTime,
    bool? isCompleted,
    String? categoryId,
    TodoPriority? priority,
    TodoType? type,
    Object? linkedHabitId = _sentinel,
    Object? xpReward = _sentinel,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      linkedHabitId: identical(linkedHabitId, _sentinel)
          ? this.linkedHabitId
          : linkedHabitId as String?,
      xpReward:
          identical(xpReward, _sentinel) ? this.xpReward : xpReward as int?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'dueDate': dueDate?.toUtc().toIso8601String(),
        'hasTime': hasTime,
        'isCompleted': isCompleted,
        'categoryId': categoryId,
        'priority': priority.name,
        'type': type.name,
        'linkedHabitId': linkedHabitId,
        'xpReward': xpReward,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {required DateTime fallback}) {
      final raw = value?.toString();
      final parsed = raw == null ? null : DateTime.tryParse(raw);
      return parsed?.toLocal() ?? fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      final raw = value?.toString();
      final parsed = raw == null ? null : DateTime.tryParse(raw);
      return parsed?.toLocal();
    }

    TodoPriority parsePriority(dynamic value) {
      final raw = value?.toString().trim();
      return TodoPriority.values.firstWhere(
        (priority) => priority.name == raw,
        orElse: () => TodoPriority.none,
      );
    }

    TodoType parseType(dynamic value) {
      final raw = value?.toString().trim();
      return TodoType.values.firstWhere(
        (type) => type.name == raw,
        orElse: () => TodoType.free,
      );
    }

    final createdFallback = DateTime.now();

    return TodoItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: parseDate(
        json['createdAt'],
        fallback: createdFallback,
      ),
      dueDate: parseNullableDate(json['dueDate']),
      hasTime: json['hasTime'] == true,
      isCompleted: json['isCompleted'] == true,
      categoryId: (json['categoryId'] ?? '').toString(),
      priority: parsePriority(json['priority']),
      type: parseType(json['type']),
      linkedHabitId: (json['linkedHabitId'] as Object?)?.toString(),
      xpReward: json['xpReward'] is int
          ? json['xpReward'] as int
          : int.tryParse((json['xpReward'] ?? '').toString()),
    );
  }
}

const Object _sentinel = Object();
