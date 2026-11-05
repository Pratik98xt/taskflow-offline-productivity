import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../models/task_model.dart';

class ImportExportService {
  // EXPORT TASKS

  static Future<void> exportTasks(List<TaskModel> tasks) async {
    try {
      final jsonData = {
        'app': 'TaskFlow',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      final bytes = utf8.encode(jsonString);

      await FilePicker.saveFile(
        dialogTitle: 'Export TaskFlow Tasks',
        fileName: 'taskflow_backup.json',
        bytes: bytes,
      );
    } catch (e) {
      throw Exception('Unable to export tasks: $e');
    }
  }

  static Future<List<TaskModel>> importTasks() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isEmpty) {
        return [];
      }

      final bytes = await files.first.readAsBytes();
      final jsonString = utf8.decode(bytes);
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic> ||
          decoded['app'] != 'TaskFlow' ||
          decoded['version'] != 1 ||
          decoded['tasks'] is! List) {
        throw const FormatException('Invalid TaskFlow backup file.');
      }

      final List<TaskModel> tasks = [];

      for (final item in decoded['tasks']) {
        if (item is! Map<String, dynamic>) continue;

        try {
          final task = TaskModel.fromJson(item);

          if (task.title.trim().isEmpty || task.category.trim().isEmpty) {
            continue;
          }

          tasks.add(task.copyWith(id: null));
        } catch (_) {
          continue;
        }
      }

      return tasks;
    } catch (e) {
      throw Exception('Unable to import tasks: $e');
    }
  }
}
