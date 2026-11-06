import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_assignment/core/database/database_helper.dart';
import 'package:flutter_application_assignment/core/errors/app_exception.dart';
import 'package:flutter_application_assignment/models/task_model.dart';
import 'package:flutter_application_assignment/repositories/task_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockHelper;
  late MockDatabase mockDb;
  late TaskRepository repository;

  final now = DateTime(2026, 11, 6, 10, 0);
  final sampleTask = TaskModel(
    id: 1,
    title: 'Code Review',
    description: 'Review PRs',
    category: 'Work',
    priority: TaskPriority.high,
    status: TaskStatus.todo,
    dueDate: now.add(const Duration(days: 1)),
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockHelper = MockDatabaseHelper();
    mockDb = MockDatabase();
    when(() => mockHelper.database).thenAnswer((_) async => mockDb);
    repository = TaskRepository(databaseHelper: mockHelper);
  });

  group('TaskRepository CRUD & Validation', () {
    test('createTask inserts record and returns generated id', () async {
      when(() => mockDb.insert('tasks', any())).thenAnswer((_) async => 42);

      final id = await repository.createTask(sampleTask);

      expect(id, 42);
      verify(() => mockDb.insert('tasks', any())).called(1);
    });

    test('getAllTasks returns parsed task models', () async {
      when(() => mockDb.query('tasks', orderBy: 'createdAt DESC'))
          .thenAnswer((_) async => [sampleTask.toMap()]);

      final tasks = await repository.getAllTasks();

      expect(tasks.length, 1);
      expect(tasks.first.title, 'Code Review');
      expect(tasks.first.priority, TaskPriority.high);
    });

    test('getTaskById returns task when exists and null when absent', () async {
      when(
        () => mockDb.query('tasks', where: 'id = ?', whereArgs: [1], limit: 1),
      ).thenAnswer((_) async => [sampleTask.toMap()]);
      when(
        () => mockDb.query('tasks', where: 'id = ?', whereArgs: [99], limit: 1),
      ).thenAnswer((_) async => []);

      final found = await repository.getTaskById(1);
      final missing = await repository.getTaskById(99);

      expect(found, isNotNull);
      expect(found!.id, 1);
      expect(missing, isNull);
    });

    test('updateTask updates existing record and throws ValidationException if id is null', () async {
      when(() => mockDb.update('tasks', any(), where: 'id = ?', whereArgs: [1]))
          .thenAnswer((_) async => 1);

      final count = await repository.updateTask(sampleTask);
      expect(count, 1);

      final taskWithoutId = TaskModel(
        title: 'No Id',
        description: '',
        category: 'General',
        priority: TaskPriority.low,
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () => repository.updateTask(taskWithoutId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleteTask deletes record by id', () async {
      when(() => mockDb.delete('tasks', where: 'id = ?', whereArgs: [1]))
          .thenAnswer((_) async => 1);

      final count = await repository.deleteTask(1);
      expect(count, 1);
      verify(() => mockDb.delete('tasks', where: 'id = ?', whereArgs: [1]))
          .called(1);
    });

    test('isDuplicateTask correctly queries database for title and category matches', () async {
      when(
        () => mockDb.query(
          'tasks',
          where: 'LOWER(TRIM(title)) = ? AND LOWER(TRIM(category)) = ?',
          whereArgs: ['code review', 'work'],
          limit: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'id': 1},
        ],
      );

      when(
        () => mockDb.query(
          'tasks',
          where: 'LOWER(TRIM(title)) = ? AND LOWER(TRIM(category)) = ?',
          whereArgs: ['unique task', 'work'],
          limit: 1,
        ),
      ).thenAnswer((_) async => []);

      final exists = await repository.isDuplicateTask(
        title: '  Code Review  ',
        category: 'Work',
      );
      final notExists = await repository.isDuplicateTask(
        title: 'Unique Task',
        category: 'Work',
      );

      expect(exists, isTrue);
      expect(notExists, isFalse);
    });

    test(
      'isDuplicateTask excludes specified id during update validation',
      () async {
        when(
          () => mockDb.query(
            'tasks',
            where: 'LOWER(TRIM(title)) = ? AND LOWER(TRIM(category)) = ? AND id != ?',
            whereArgs: ['code review', 'work', 1],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        final isSelfDuplicate = await repository.isDuplicateTask(
          title: 'Code Review',
          category: 'Work',
          excludeId: 1,
        );

        expect(isSelfDuplicate, isFalse);
      },
    );
  });
}
