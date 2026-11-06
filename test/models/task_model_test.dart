import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_assignment/models/task_model.dart';

void main() {
  group('TaskModel', () {
    final testDate = DateTime(2026, 11, 10, 14, 30);
    final createdAt = DateTime(2026, 11, 1, 9, 0);
    final updatedAt = DateTime(2026, 11, 2, 10, 0);

    final sampleTask = TaskModel(
      id: 1,
      title: 'Complete Project',
      description: 'Finish final review',
      category: 'Work',
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      dueDate: testDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('toMap and fromMap preserves all fields correctly', () {
      final map = sampleTask.toMap();
      final reconstituted = TaskModel.fromMap(map);

      expect(reconstituted.id, sampleTask.id);
      expect(reconstituted.title, sampleTask.title);
      expect(reconstituted.description, sampleTask.description);
      expect(reconstituted.category, sampleTask.category);
      expect(reconstituted.priority, TaskPriority.high);
      expect(reconstituted.status, TaskStatus.inProgress);
      expect(reconstituted.dueDate, testDate);
      expect(reconstituted.createdAt, createdAt);
      expect(reconstituted.updatedAt, updatedAt);
      expect(reconstituted, equals(sampleTask));
    });

    test('toJson and fromJson performs round-trip serialization', () {
      final json = sampleTask.toJson();
      final fromJson = TaskModel.fromJson(json);

      expect(fromJson, equals(sampleTask));
    });

    test(
      'handles invalid enum values safely without throwing ArgumentError',
      () {
        final corruptMap = {
          'id': 2,
          'title': 'Test Corrupt',
          'description': '',
          'category': 'General',
          'priority': 'extremeUrgent', // invalid enum
          'status': 'archivedStatus', // invalid enum
          'dueDate': null,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String(),
        };

        final parsed = TaskModel.fromMap(corruptMap);
        expect(parsed.priority, TaskPriority.medium); // Safe fallback
        expect(parsed.status, TaskStatus.todo); // Safe fallback
      },
    );

    test('handles null and missing fields gracefully in fromMap', () {
      final minimalMap = {'title': 'Minimal'};

      final parsed = TaskModel.fromMap(minimalMap);
      expect(parsed.title, 'Minimal');
      expect(parsed.description, '');
      expect(parsed.category, 'General');
      expect(parsed.priority, TaskPriority.medium);
      expect(parsed.status, TaskStatus.todo);
      expect(parsed.dueDate, isNull);
    });

    test('copyWith updates fields and handles clearDueDate', () {
      final updated = sampleTask.copyWith(
        title: 'Updated Title',
        priority: TaskPriority.low,
        clearDueDate: true,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.priority, TaskPriority.low);
      expect(updated.dueDate, isNull);
      expect(updated.category, sampleTask.category);
    });

    test('isOverdue and isOverdueAt correctly detects overdue tasks', () {
      final pastDate = DateTime(2026, 11, 1, 10, 0);
      final futureDate = DateTime(2026, 11, 20, 10, 0);
      final referenceMoment = DateTime(2026, 11, 6, 12, 0);

      final overdueTask = sampleTask.copyWith(
        dueDate: pastDate,
        status: TaskStatus.todo,
      );

      final completedTask = sampleTask.copyWith(
        dueDate: pastDate,
        status: TaskStatus.completed,
      );

      final upcomingTask = sampleTask.copyWith(
        dueDate: futureDate,
        status: TaskStatus.inProgress,
      );

      final noDueDateTask = sampleTask.copyWith(
        clearDueDate: true,
        status: TaskStatus.todo,
      );

      expect(overdueTask.isOverdueAt(referenceMoment), isTrue);
      expect(
        completedTask.isOverdueAt(referenceMoment),
        isFalse,
      ); // Completed is not overdue
      expect(upcomingTask.isOverdueAt(referenceMoment), isFalse);
      expect(noDueDateTask.isOverdueAt(referenceMoment), isFalse);
    });
  });
}
