import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../errors/app_exception.dart';
import '../../models/task_model.dart';

class ImportExportService {
  // EXPORT TASKS

  static Future<bool> exportTasks(List<TaskModel> tasks) async {
    try {
      final jsonData = {
        'app': 'TaskFlow',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(jsonString);

      final result = await FilePicker.saveFile(
        dialogTitle: 'Export TaskFlow Tasks',
        fileName: 'taskflow_backup.json',
        bytes: bytes,
      );

      // Null means the user cancelled the save dialog.
      return result != null;
    } catch (e) {
      throw ImportExportException(
        'Unable to export tasks.',
        details: e.toString(),
      );
    }
  }

  // IMPORT TASKS

  static Future<List<TaskModel>?> importTasks() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // Empty list means the user cancelled.
      if (files.isEmpty) {
        return null;
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
        if (item is! Map<String, dynamic>) {
          continue;
        }

        try {
          final task = TaskModel.fromJson(item);

          if (task.title.trim().isEmpty || task.category.trim().isEmpty) {
            continue;
          }

          tasks.add(task.copyWith(id: null));
        } catch (_) {
          // Skip invalid records.
        }
      }

      return tasks;
    } catch (e) {
      throw ImportExportException(
        'Unable to import tasks. Please select a valid TaskFlow backup.',
        details: e.toString(),
      );
    }
  }
}
