import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_event.dart';
import '../../controllers/task_controller/task_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }

          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _buildSettings(context),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Data Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(
          'Backup or restore your TaskFlow data.',
          style: TextStyle(color: Colors.grey.shade600),
        ),

        const SizedBox(height: 20),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.upload_file,
              color: Colors.blue,
              size: 30,
            ),
            title: const Text('Export Tasks'),
            subtitle: const Text('Save all tasks as a JSON backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.read<TaskBloc>().add(ExportTasks());
            },
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.download, color: Colors.green, size: 30),
            title: const Text('Import Tasks'),
            subtitle: const Text('Restore tasks from a JSON backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.read<TaskBloc>().add(ImportTasks());
            },
          ),
        ),

        const SizedBox(height: 24),

        Card(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About TaskFlow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('Offline Productivity Manager'),
                Text('Version 1.0.0'),
                SizedBox(height: 8),
                Text(
                  'Your tasks are stored locally on your device.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
