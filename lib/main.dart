import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/utils/notification_service.dart';
import 'controllers/task_controller/task_event.dart';
import 'core/theme/app_theme.dart';
import 'controllers/task_controller/task_bloc.dart';
import 'repositories/task_repository.dart';
import 'views/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => TaskRepository(),
      child: BlocProvider(
        create: (context) =>
            TaskBloc(context.read<TaskRepository>())..add(LoadTasks()),
        child: MaterialApp(
          title: 'TaskFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
