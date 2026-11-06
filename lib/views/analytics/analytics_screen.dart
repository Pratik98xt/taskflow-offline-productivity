import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_state.dart';
import '../../models/task_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
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
            return _buildAnalytics(context, state.allTasks);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context, List<TaskModel> tasks) {
    final now = DateTime.now();

    final total = tasks.length;

    final completed = tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;

    final overdue = tasks.where((task) => task.isOverdueAt(now)).length;

    final pending = total - completed - overdue;

    final completionRate = total == 0 ? 0.0 : (completed / total) * 100;
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No analytics available yet',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create tasks and track your progress to see productivity insights here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Productivity',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Track your task progress at a glance.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Tasks', total, Icons.task_alt, Colors.blue),
              _buildStatCard(
                'Completed',
                completed,
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Pending',
                pending,
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                'Overdue',
                overdue,
                Icons.warning_amber,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completion Rate',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: completionRate / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${completionRate.toStringAsFixed(1)}% completed',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildStatusChart(tasks),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Text(
              '$count',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(List<TaskModel> tasks) {
    final todo = tasks.where((task) => task.status == TaskStatus.todo).length;

    final inProgress = tasks
        .where((task) => task.status == TaskStatus.inProgress)
        .length;

    final completed = tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Distribution',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (tasks.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(child: Text('No tasks available for analysis')),
              )
            else
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 35,
                    sections: [
                      PieChartSectionData(
                        value: todo.toDouble(),
                        title: '$todo',
                        color: Colors.blue,
                        radius: 55,
                      ),
                      PieChartSectionData(
                        value: inProgress.toDouble(),
                        title: '$inProgress',
                        color: Colors.orange,
                        radius: 55,
                      ),
                      PieChartSectionData(
                        value: completed.toDouble(),
                        title: '$completed',
                        color: Colors.green,
                        radius: 55,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            _buildLegend('To Do', Colors.blue, todo),
            _buildLegend('In Progress', Colors.orange, inProgress),
            _buildLegend('Completed', Colors.green, completed),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
