import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../errors/app_exception.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;
  static Completer<Database>? _dbOpenCompleter;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    if (_dbOpenCompleter != null) {
      return _dbOpenCompleter!.future;
    }

    final completer = Completer<Database>();
    _dbOpenCompleter = completer;

    try {
      _database = await _initDB('taskflow.db');
      completer.complete(_database!);
      _dbOpenCompleter = null;
      return _database!;
    } catch (e) {
      _dbOpenCompleter = null;
      throw DatabaseAppException(
        'Database initialization failed.',
        details: e.toString(),
      );
    }
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        priority TEXT NOT NULL
          CHECK(priority IN ('low', 'medium', 'high')),
        status TEXT NOT NULL
          CHECK(status IN ('todo', 'inProgress', 'completed')),
        dueDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_status
      ON tasks(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_priority
      ON tasks(priority)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_dueDate
      ON tasks(dueDate)
    ''');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration handling for future database versions
    // Example: sequential version migrations (v1 -> v2 -> v3) can be applied here
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
    _dbOpenCompleter = null;
  }
}
