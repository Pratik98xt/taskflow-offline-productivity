import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    try {
      _database = await _initDB('taskflow.db');
      return _database!;
    } catch (e) {
      throw Exception('Database initialization failed: $e');
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

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}