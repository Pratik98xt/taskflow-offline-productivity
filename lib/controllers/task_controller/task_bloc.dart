import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/notification_service.dart';
import '../../models/task_model.dart';
import '../../repositories/task_repository.dart';
import '../../core/errors/app_exception.dart';

import 'task_event.dart';
import 'task_state.dart';
import '../../core/utils/import_export_service.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

  TaskBloc(this.repository) : super(TaskInitial()) {
    on<LoadTasks>(_loadTasks);
    on<AddTask>(_addTask);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);

    on<SearchTasks>(_searchTasks);
    on<FilterTasks>(_filterTasks);
    on<SortTasks>(_sortTasks);
    on<ClearTaskFilters>(_clearFilters);
    on<ExportTasks>(_exportTasks);
    on<ImportTasks>(_importTasks);
  }

  Future<void> _loadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());

    try {
      final tasks = await repository.getAllTasks();

      emit(_buildLoadedState(tasks));
    } catch (e) {
      emit(TaskError('Unable to load tasks.'));
    }
  }

  Future<void> _addTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      final taskId = await repository.createTask(event.task);

      if (event.task.dueDate != null &&
          event.task.status != TaskStatus.completed) {
        await NotificationService.scheduleTaskNotification(
          taskId: taskId,
          title: event.task.title,
          dueDate: event.task.dueDate!,
        );
      }

      final tasks = await repository.getAllTasks();
      emit(_buildLoadedState(tasks));
    } catch (e) {
      emit(TaskError(e is AppException ? e.message : 'Unable to add task.'));
    }
  }

  Future<void> _updateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await repository.updateTask(event.task);

      final task = event.task;

      if (task.id != null) {
        if (task.status == TaskStatus.completed ||
            task.dueDate == null ||
            task.dueDate!.isBefore(DateTime.now())) {
          await NotificationService.cancelTaskNotification(task.id!);
        } else {
          await NotificationService.scheduleTaskNotification(
            taskId: task.id!,
            title: task.title,
            dueDate: task.dueDate!,
          );
        }
      }

      final tasks = await repository.getAllTasks();
      emit(_buildLoadedState(tasks));
    } catch (e) {
      emit(TaskError(e is AppException ? e.message : 'Unable to update task.'));
    }
  }

  Future<void> _deleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await repository.deleteTask(event.id);

      await NotificationService.cancelTaskNotification(event.id);

      final tasks = await repository.getAllTasks();
      emit(_buildLoadedState(tasks));
    } catch (e) {
      emit(TaskError(e is AppException ? e.message : 'Unable to delete task.'));
    }
  }

  // SEARCH

  void _searchTasks(SearchTasks event, Emitter<TaskState> emit) {
    if (state is! TaskLoaded) return;

    final current = state as TaskLoaded;

    emit(
      _buildLoadedState(
        current.allTasks,
        searchQuery: event.query,
        priority: current.priority,
        status: current.status,
        category: current.category,
        dueDate: current.dueDate,
        sortOption: current.sortOption,
      ),
    );
  }

  // FILTER

  void _filterTasks(FilterTasks event, Emitter<TaskState> emit) {
    if (state is! TaskLoaded) return;

    final current = state as TaskLoaded;

    emit(
      _buildLoadedState(
        current.allTasks,
        searchQuery: current.searchQuery,
        priority: event.priority,
        status: event.status,
        category: event.category,
        dueDate: event.dueDate,
        sortOption: current.sortOption,
      ),
    );
  }

  // SORT

  void _sortTasks(SortTasks event, Emitter<TaskState> emit) {
    if (state is! TaskLoaded) return;

    final current = state as TaskLoaded;

    emit(
      _buildLoadedState(
        current.allTasks,
        searchQuery: current.searchQuery,
        priority: current.priority,
        status: current.status,
        category: current.category,
        dueDate: current.dueDate,
        sortOption: event.sortOption,
      ),
    );
  }

  // CLEAR FILTERS

  void _clearFilters(ClearTaskFilters event, Emitter<TaskState> emit) {
    if (state is! TaskLoaded) return;

    final current = state as TaskLoaded;

    emit(_buildLoadedState(current.allTasks));
  }

  Future<void> _exportTasks(ExportTasks event, Emitter<TaskState> emit) async {
    try {
      final tasks = await repository.getAllTasks();

      if (tasks.isEmpty) {
        emit(const TaskActionSuccess('No tasks available to export.'));
      } else {
        await ImportExportService.exportTasks(tasks);
        emit(const TaskActionSuccess('Tasks exported successfully!'));
      }

      emit(_buildLoadedState(tasks));
    } catch (e) {
      emit(TaskError('Export failed: $e'));
    }
  }

  Future<void> _importTasks(ImportTasks event, Emitter<TaskState> emit) async {
    try {
      final importedTasks = await ImportExportService.importTasks();

      if (importedTasks.isEmpty) {
        emit(const TaskActionSuccess('No valid tasks found to import.'));
        emit(_buildLoadedState(await repository.getAllTasks()));
        return;
      }

      final existingTasks = await repository.getAllTasks();

      final existingKeys = existingTasks
          .map(
            (task) =>
                '${task.title.trim().toLowerCase()}_${task.category.trim().toLowerCase()}',
          )
          .toSet();

      int importedCount = 0;
      int skippedCount = 0;

      for (final task in importedTasks) {
        final key =
            '${task.title.trim().toLowerCase()}_${task.category.trim().toLowerCase()}';

        if (existingKeys.contains(key)) {
          skippedCount++;
          continue;
        }

        await repository.createTask(task);
        existingKeys.add(key);
        importedCount++;
      }

      final updatedTasks = await repository.getAllTasks();

      emit(
        TaskActionSuccess('Imported: $importedCount | Skipped: $skippedCount'),
      );

      emit(_buildLoadedState(updatedTasks));
    } catch (e) {
      emit(TaskError('Import failed: $e'));
    }
  }
  // FILTERING AND SORTING ENGINE

  TaskLoaded _buildLoadedState(
    List<TaskModel> allTasks, {
    String searchQuery = '',
    TaskPriority? priority,
    TaskStatus? status,
    String? category,
    DateTime? dueDate,
    TaskSortOption sortOption = TaskSortOption.newest,
  }) {
    List<TaskModel> filtered = allTasks.where((task) {
      final query = searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      final matchesPriority = priority == null || task.priority == priority;

      final matchesStatus = status == null || task.status == status;

      final matchesCategory = category == null || task.category == category;

      final matchesDate =
          dueDate == null ||
          (task.dueDate != null &&
              task.dueDate!.year == dueDate.year &&
              task.dueDate!.month == dueDate.month &&
              task.dueDate!.day == dueDate.day);

      return matchesSearch &&
          matchesPriority &&
          matchesStatus &&
          matchesCategory &&
          matchesDate;
    }).toList();

    // SORTING

    switch (sortOption) {
      case TaskSortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case TaskSortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;

      case TaskSortOption.dueDate:
        filtered.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;

          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;

      case TaskSortOption.priority:
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }

    return TaskLoaded(
      tasks: filtered,
      allTasks: allTasks,
      searchQuery: searchQuery,
      priority: priority,
      status: status,
      category: category,
      dueDate: dueDate,
      sortOption: sortOption,
    );
  }
}
