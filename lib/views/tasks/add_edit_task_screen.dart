import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_event.dart';
import '../../models/task_model.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key});

  @override
  State<AddEditTaskScreen> createState() =>
      _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  TaskPriority priority = TaskPriority.medium;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void saveTask() {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter task title')),
      );
      return;
    }

    final now = DateTime.now();

    final task = TaskModel(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: 'General',
      priority: priority,
      status: TaskStatus.todo,
      createdAt: now,
      updatedAt: now,
    );

    context.read<TaskBloc>().add(AddTask(task));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<TaskPriority>(
              initialValue: priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
              ),
              items: TaskPriority.values.map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => priority = value);
                }
              },
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: saveTask,
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}