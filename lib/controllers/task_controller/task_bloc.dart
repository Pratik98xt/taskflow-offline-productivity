import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/import_export_service.dart';
import '../../core/utils/notification_service.dart';
import '../../models/task_model.dart';
import '../../repositories/task_repository.dart';

import 'task_event.dart';
import 'task_state.dart';

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

  TaskLoaded? get _currentLoadedState =>
      state is TaskLoaded ? state as TaskLoaded : null;

  // LOAD TASKS

  Future<void> _loadTasks(
    LoadTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());

    try {
      final tasks = await repository.getAllTasks();
      emit(_buildLoadedState(tasks));
    } catch (e) {
      emit(
        TaskError(
          e is AppException ? e.message : 'Unable to load tasks.',
        ),
      );
    }
  }

  // ADD TASK

  Future<void> _addTask(
    AddTask event,
    Emitter<TaskState> emit,
  ) async {
    final currentLoaded = _currentLoadedState;
    try {
      final task = event.task;

      final isDuplicate = await repository.isDuplicateTask(
        title: task.title,
        category: task.category,
      );

      if (isDuplicate) {
        emit(
          const TaskError(
            'A task with this title already exists in this category.',
          ),
        );

        final existingTasks = await repository.getAllTasks();
        _emitPreservedLoadedState(
          existingTasks,
          emit,
          previousState: currentLoaded,
        );
        return;
      }

      final taskId = await repository.createTask(task);

      // Notification failure must not undo successful task creation.
      if (task.dueDate != null &&
          task.status != TaskStatus.completed) {
        try {
          await NotificationService.scheduleTaskNotification(
            taskId: taskId,
            title: task.title,
            dueDate: task.dueDate!,
          );
        } catch (_) {
          // Task is already saved.
        }
      }

      emit(const TaskActionSuccess('Task created successfully.'));
      final tasks = await repository.getAllTasks();
      _emitPreservedLoadedState(tasks, emit, previousState: currentLoaded);
    } catch (e) {
      emit(
        TaskError(
          e is AppException ? e.message : 'Unable to add task.',
        ),
      );
    }
  }

  // UPDATE TASK

  Future<void> _updateTask(
    UpdateTask event,
    Emitter<TaskState> emit,
  ) async {
    final currentLoaded = _currentLoadedState;
    try {
      final task = event.task;

      final isDuplicate = await repository.isDuplicateTask(
        title: task.title,
        category: task.category,
        excludeId: task.id,
      );

      if (isDuplicate) {
        emit(
          const TaskError(
            'Another task with this title already exists in this category.',
          ),
        );

        final existingTasks = await repository.getAllTasks();
        _emitPreservedLoadedState(
          existingTasks,
          emit,
          previousState: currentLoaded,
        );
        return;
      }

      await repository.updateTask(task);

      // Notification failure must not undo successful task update.
      if (task.id != null) {
        try {
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
        } catch (_) {
          // Task update is already saved.
        }
      }

      emit(const TaskActionSuccess('Task updated successfully.'));
      final tasks = await repository.getAllTasks();
      _emitPreservedLoadedState(tasks, emit, previousState: currentLoaded);
    } catch (e) {
      emit(
        TaskError(
          e is AppException ? e.message : 'Unable to update task.',
        ),
      );
    }
  }

  // DELETE TASK

  Future<void> _deleteTask(
    DeleteTask event,
    Emitter<TaskState> emit,
  ) async {
    final currentLoaded = _currentLoadedState;
    try {
      await repository.deleteTask(event.id);

      // Notification cancellation failure must not undo deletion.
      try {
        await NotificationService.cancelTaskNotification(event.id);
      } catch (_) {
        // Task is already deleted.
      }

      emit(const TaskActionSuccess('Task deleted successfully.'));
      final tasks = await repository.getAllTasks();
      _emitPreservedLoadedState(tasks, emit, previousState: currentLoaded);
    } catch (e) {
      emit(
        TaskError(
          e is AppException ? e.message : 'Unable to delete task.',
        ),
      );
    }
  }

  // SEARCH

  void _searchTasks(
    SearchTasks event,
    Emitter<TaskState> emit,
  ) {
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

  void _filterTasks(
    FilterTasks event,
    Emitter<TaskState> emit,
  ) {
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

  void _sortTasks(
    SortTasks event,
    Emitter<TaskState> emit,
  ) {
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

  void _clearFilters(
    ClearTaskFilters event,
    Emitter<TaskState> emit,
  ) {
    if (state is! TaskLoaded) return;

    final current = state as TaskLoaded;

    emit(_buildLoadedState(current.allTasks));
  }

  // EXPORT TASKS

  Future<void> _exportTasks(
    ExportTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentLoaded = _currentLoadedState;
    try {
      final tasks = await repository.getAllTasks();

      if (tasks.isEmpty) {
        emit(const TaskActionSuccess('No tasks available to export.'));
        _emitPreservedLoadedState(tasks, emit, previousState: currentLoaded);
        return;
      }

      final exported = await ImportExportService.exportTasks(tasks);

      emit(
        TaskActionSuccess(
          exported ? 'Tasks exported successfully!' : 'Export cancelled.',
        ),
      );

      _emitPreservedLoadedState(tasks, emit, previousState: currentLoaded);
    } catch (e) {
      emit(
        TaskError(
          e is AppException ? e.message : 'Export failed.',
        ),
      );
    }
  }

  // IMPORT TASKS

  Future<void> _importTasks(
    ImportTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentLoaded = _currentLoadedState;
    try {
      final importedTasks = await ImportExportService.importTasks();

      // User cancelled the file picker.
      if (importedTasks == null) {
        emit(const TaskActionSuccess('Import cancelled.'));
        _emitPreservedLoadedState(
          await repository.getAllTasks(),
          emit,
          previousState: currentLoaded,
        );
        return;
      }

      if (importedTasks.isEmpty) {
        emit(const TaskActionSuccess('No valid tasks found in backup.'));
        _emitPreservedLoadedState(
          await repository.getAllTasks(),
          emit,
          previousState: currentLoaded,
        );
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
        TaskActionSuccess(
          'Imported: $importedCount | Skipped: $skippedCount',
        ),
      );

      _emitPreservedLoadedState(updatedTasks, emit, previousState: currentLoaded);
    } catch (e) {
      emit(
        TaskError(
          e is AppException ? e.message : 'Import failed.',
        ),
      );
    }
  }

  // EMIT LOADED STATE PRESERVING FILTERS AND SORTING

  void _emitPreservedLoadedState(
    List<TaskModel> allTasks,
    Emitter<TaskState> emit, {
    TaskLoaded? previousState,
  }) {
    final current = previousState ?? (state is TaskLoaded ? state as TaskLoaded : null);
    if (current != null) {
      emit(
        _buildLoadedState(
          allTasks,
          searchQuery: current.searchQuery,
          priority: current.priority,
          status: current.status,
          category: current.category,
          dueDate: current.dueDate,
          sortOption: current.sortOption,
        ),
      );
    } else {
      emit(_buildLoadedState(allTasks));
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
    final filtered = allTasks.where((task) {
      final query = searchQuery.trim().toLowerCase();

      // Search by title and description.
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      // Priority filter.
      final matchesPriority =
          priority == null || task.priority == priority;

      // Status filter.
      final matchesStatus =
          status == null || task.status == status;

      // Category filter.
      final matchesCategory =
          category == null || task.category == category;

      // Due date filter.
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
        filtered.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        break;

      case TaskSortOption.oldest:
        filtered.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
        break;

      case TaskSortOption.dueDate:
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;

          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;

      case TaskSortOption.priority:
        filtered.sort(
          (a, b) => b.priority.index.compareTo(a.priority.index),
        );
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
