import 'package:equatable/equatable.dart';

import '../../models/task_model.dart';
import 'task_state.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final TaskModel task;

  const AddTask(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TaskEvent {
  final TaskModel task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final int id;

  const DeleteTask(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchTasks extends TaskEvent {
  final String query;

  const SearchTasks(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterTasks extends TaskEvent {
  final TaskPriority? priority;
  final TaskStatus? status;
  final String? category;
  final DateTime? dueDate;

  const FilterTasks({this.priority, this.status, this.category, this.dueDate});

  @override
  List<Object?> get props => [priority, status, category, dueDate];
}

class SortTasks extends TaskEvent {
  final TaskSortOption sortOption;

  const SortTasks(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

class ClearTaskFilters extends TaskEvent {}
