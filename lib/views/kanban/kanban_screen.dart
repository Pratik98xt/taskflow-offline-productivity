import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_event.dart';
import '../../controllers/task_controller/task_state.dart';
import '../../models/task_model.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kanban Board',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TaskError) {
            return Center(child: Text(state.message));
          }

          if (state is TaskLoaded) {
            return _buildBoard(context, state.tasks);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBoard(BuildContext context, List<TaskModel> tasks) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildColumn(context, 'To Do', TaskStatus.todo, tasks, Colors.blue),

          _buildColumn(
            context,
            'In Progress',
            TaskStatus.inProgress,
            tasks,
            Colors.orange,
          ),

          _buildColumn(
            context,
            'Completed',
            TaskStatus.completed,
            tasks,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String title,
    TaskStatus status,
    List<TaskModel> tasks,
    Color color,
  ) {
    final columnTasks = tasks.where((task) => task.status == status).toList();

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) {
        return details.data.status != status;
      },

      onAcceptWithDetails: (details) {
        final task = details.data;

        context.read<TaskBloc>().add(
          UpdateTask(task.copyWith(status: status, updatedAt: DateTime.now())),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.title} moved to $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },

      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;

        return Container(
          width: 290,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: isDraggingOver
                ? color.withValues(alpha: 0.12)
                : Colors.grey.shade100,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: isDraggingOver ? color : Colors.grey.shade300,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  CircleAvatar(
                    radius: 13,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      '${columnTasks.length}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: columnTasks.isEmpty
                    ? Center(
                        child: Text(
                          'Drop tasks here',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: columnTasks.length,

                        itemBuilder: (context, index) {
                          return _buildTaskCard(columnTasks[index], color);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task, Color color) {
    return LongPressDraggable<TaskModel>(
      data: task,

      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),

        child: SizedBox(width: 250, child: _taskCardContent(task, color)),
      ),

      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _taskCardContent(task, color),
      ),

      child: _taskCardContent(task, color),
    );
  }

  Widget _taskCardContent(TaskModel task, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 1,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              task.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),

              Text(
                task.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],

            const SizedBox(height: 12),

            Wrap(
              spacing: 6,
              runSpacing: 6,

              children: [
                Chip(
                  label: Text(
                    task.priority.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),

                  backgroundColor: color.withValues(alpha: 0.12),

                  visualDensity: VisualDensity.compact,
                ),

                Chip(
                  label: Text(
                    task.category,
                    style: const TextStyle(fontSize: 10),
                  ),

                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            if (task.dueDate != null) ...[
              const SizedBox(height: 5),

              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13),

                  const SizedBox(width: 5),

                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
