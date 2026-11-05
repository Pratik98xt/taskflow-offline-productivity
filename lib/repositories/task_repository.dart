import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/errors/app_exception.dart';
import '../models/task_model.dart';

class TaskRepository {
  final DatabaseHelper databaseHelper;

  TaskRepository({
    DatabaseHelper? databaseHelper,
  }) : databaseHelper =
            databaseHelper ?? DatabaseHelper.instance;

  // CREATE TASK

  Future<int> createTask(TaskModel task) async {
    try {
      final db = await databaseHelper.database;

      return await db.insert(
        'tasks',
        task.toMap()..remove('id'),
      );
    } on DatabaseException catch (e) {
      throw DatabaseAppException(
        'Unable to create task.',
        details: e.toString(),
      );
    }
  }

  // GET ALL TASKS

  Future<List<TaskModel>> getAllTasks() async {
    try {
      final db = await databaseHelper.database;

      final result = await db.query(
        'tasks',
        orderBy: 'createdAt DESC',
      );

      return result.map(TaskModel.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatabaseAppException(
        'Unable to retrieve tasks.',
        details: e.toString(),
      );
    } on FormatException catch (e) {
      throw DatabaseAppException(
        'Invalid task data found.',
        details: e.toString(),
      );
    }
  }

  // GET TASK BY ID

  Future<TaskModel?> getTaskById(int id) async {
    try {
      final db = await databaseHelper.database;

      final result = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      return TaskModel.fromMap(result.first);
    } on DatabaseException catch (e) {
      throw DatabaseAppException(
        'Unable to retrieve task.',
        details: e.toString(),
      );
    } on FormatException catch (e) {
      throw DatabaseAppException(
        'Invalid task data found.',
        details: e.toString(),
      );
    }
  }

  // UPDATE TASK

  Future<int> updateTask(TaskModel task) async {
    try {
      if (task.id == null) {
        throw ValidationException(
          'Task ID is required for updating.',
        );
      }

      final db = await databaseHelper.database;

      final data = task.toMap()
        ..remove('id');

      final count = await db.update(
        'tasks',
        data,
        where: 'id = ?',
        whereArgs: [task.id],
      );

      return count;
    } on DatabaseException catch (e) {
      throw DatabaseAppException(
        'Unable to update task.',
        details: e.toString(),
      );
    }
  }

  // DELETE TASK

  Future<int> deleteTask(int id) async {
    try {
      final db = await databaseHelper.database;

      return await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      throw DatabaseAppException(
        'Unable to delete task.',
        details: e.toString(),
      );
    }
  }
}