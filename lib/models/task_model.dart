import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, completed }

class TaskModel extends Equatable {
  final int? id;
  final String title;
  final String description;
  final String category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue =>
      dueDate != null &&
      status != TaskStatus.completed &&
      dueDate!.isBefore(DateTime.now());

  bool isOverdueAt(DateTime currentTime) =>
      dueDate != null &&
      status != TaskStatus.completed &&
      dueDate!.isBefore(currentTime);

  static TaskPriority parsePriority(dynamic value) {
    if (value is TaskPriority) return value;
    if (value is String) {
      for (final p in TaskPriority.values) {
        if (p.name.toLowerCase() == value.trim().toLowerCase()) {
          return p;
        }
      }
    }
    return TaskPriority.medium;
  }

  static TaskStatus parseStatus(dynamic value) {
    if (value is TaskStatus) return value;
    if (value is String) {
      for (final s in TaskStatus.values) {
        if (s.name.toLowerCase() == value.trim().toLowerCase()) {
          return s;
        }
      }
    }
    return TaskStatus.todo;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Convert object into SQLite map

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.name,
      'status': status.name,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert SQLite map into object safely handling corrupt/missing values

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return TaskModel(
      id: map['id'] as int?,
      title: (map['title'] as String?)?.trim() ?? '',
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?)?.trim() ?? 'General',
      priority: parsePriority(map['priority']),
      status: parseStatus(map['status']),
      dueDate: _parseDateTime(map['dueDate']),
      createdAt: _parseDateTime(map['createdAt']) ?? now,
      updatedAt: _parseDateTime(map['updatedAt']) ?? now,
    );
  }

  // JSON serialization

  Map<String, dynamic> toJson() => toMap();

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel.fromMap(json);
  }

  // Create modified copy

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    priority,
    status,
    dueDate,
    createdAt,
    updatedAt,
  ];
}
