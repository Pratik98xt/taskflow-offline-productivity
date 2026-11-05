import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_event.dart';
import '../../controllers/task_controller/task_state.dart';
import '../../models/task_model.dart';
import '../tasks/add_edit_task_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> deleteTask(
    BuildContext context,
    TaskModel task,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && task.id != null && context.mounted) {
      context.read<TaskBloc>().add(DeleteTask(task.id!));
    }
  }

  Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskFlow',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },

        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TaskError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TaskBloc>().add(LoadTasks());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TaskLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(
                child: Text(
                  'No tasks yet!\nCreate your first task.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tasks.length,

              itemBuilder: (context, index) {
                final task = state.tasks[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

                  child: Padding(
                    padding: const EdgeInsets.all(12),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddEditTaskScreen(task: task),
                                  ),
                                );
                              },
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                deleteTask(context, task);
                              },
                            ),
                          ],
                        ),

                        Text(task.description),

                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(task.priority.name),
                              backgroundColor:
                                  getPriorityColor(task.priority)
                                      .withValues(alpha: 0.15),
                            ),

                            Chip(
                              label: Text(task.category),
                            ),

                            if (task.dueDate != null)
                              Chip(
                                avatar: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: Text(
                                  '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<TaskStatus>(
                          initialValue: task.status,
                          decoration: const InputDecoration(
                            labelText: 'Task Status',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: TaskStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              context.read<TaskBloc>().add(
                                UpdateTask(
                                  task.copyWith(
                                    status: value,
                                    updatedAt: DateTime.now(),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditTaskScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}