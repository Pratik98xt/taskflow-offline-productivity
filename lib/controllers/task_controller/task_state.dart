import 'package:equatable/equatable.dart';

import '../../models/task_model.dart';

enum TaskSortOption { newest, oldest, dueDate, priority }

class TaskInitial extends TaskState {}

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final List<TaskModel> allTasks;

  final String searchQuery;
  final TaskPriority? priority;
  final TaskStatus? status;
  final String? category;
  final DateTime? dueDate;

  final TaskSortOption sortOption;

  const TaskLoaded({
    required this.tasks,
    required this.allTasks,
    this.searchQuery = '',
    this.priority,
    this.status,
    this.category,
    this.dueDate,
    this.sortOption = TaskSortOption.newest,
  });

  @override
  List<Object?> get props => [
    tasks,
    allTasks,
    searchQuery,
    priority,
    status,
    category,
    dueDate,
    sortOption,
  ];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskActionSuccess extends TaskState {
  final String message;

  const TaskActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
