import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_assignment/models/task_model.dart';

void main() {
  group('JSON Import/Export Logic', () {
    final now = DateTime(2026, 11, 6, 12, 0);

    test('valid backup payload decodes tasks correctly', () {
      final validPayload = jsonEncode({
        'app': 'TaskFlow',
        'version': 1,
        'exportedAt': now.toIso8601String(),
        'tasks': [
          {
            'title': 'Exported Task 1',
            'description': 'Valid task',
            'category': 'Work',
            'priority': 'high',
            'status': 'todo',
            'dueDate': now.add(const Duration(days: 1)).toIso8601String(),
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          {
            'title': 'Exported Task 2',
            'description': 'Another valid task',
            'category': 'Study',
            'priority': 'low',
            'status': 'completed',
            'dueDate': null,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ],
      });

      final decoded = jsonDecode(validPayload) as Map<String, dynamic>;
      expect(decoded['app'], 'TaskFlow');
      expect(decoded['version'], 1);
      expect(decoded['tasks'], isA<List>());

      final tasksList = (decoded['tasks'] as List)
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(tasksList.length, 2);
      expect(tasksList[0].title, 'Exported Task 1');
      expect(tasksList[1].priority, TaskPriority.low);
    });

    test(
      'malformed task records are skipped while valid ones are retained',
      () {
        final rawTasks = [
          // Corrupt record with invalid structure
          'not_a_map',
          // Record with empty title
          {
            'title': '',
            'description': 'No title',
            'category': 'Work',
            'priority': 'high',
            'status': 'todo',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          // Valid record
          {
            'title': 'Legitimate Task',
            'description': 'Fine',
            'category': 'Health',
            'priority': 'medium',
            'status': 'todo',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ];

        final List<TaskModel> validTasks = [];
        for (final item in rawTasks) {
          if (item is! Map<String, dynamic>) continue;
          try {
            final task = TaskModel.fromJson(item);
            if (task.title.trim().isEmpty || task.category.trim().isEmpty) {
              continue;
            }
            validTasks.add(task.copyWith(id: null));
          } catch (_) {}
        }

        expect(validTasks.length, 1);
        expect(validTasks.first.title, 'Legitimate Task');
        expect(validTasks.first.category, 'Health');
      },
    );

    test('deduplication algorithm skips existing keys', () {
      final existingTasks = [
        TaskModel(
          id: 1,
          title: 'Existing Task',
          description: '',
          category: 'Work',
          priority: TaskPriority.medium,
          status: TaskStatus.todo,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final existingKeys = existingTasks
          .map(
            (t) =>
                '${t.title.trim().toLowerCase()}_${t.category.trim().toLowerCase()}',
          )
          .toSet();

      final imported = [
        // Duplicate of existing
        TaskModel(
          title: 'Existing Task',
          description: 'Different desc',
          category: 'Work',
          priority: TaskPriority.high,
          status: TaskStatus.todo,
          createdAt: now,
          updatedAt: now,
        ),
        // New unique task
        TaskModel(
          title: 'New Imported Task',
          description: '',
          category: 'Work',
          priority: TaskPriority.low,
          status: TaskStatus.todo,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      int importedCount = 0;
      int skippedCount = 0;

      for (final task in imported) {
        final key =
            '${task.title.trim().toLowerCase()}_${task.category.trim().toLowerCase()}';
        if (existingKeys.contains(key)) {
          skippedCount++;
          continue;
        }
        existingKeys.add(key);
        importedCount++;
      }

      expect(importedCount, 1);
      expect(skippedCount, 1);
    });
  });
}
