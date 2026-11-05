import 'package:flutter_bloc/flutter_bloc.dart';

//import '../../models/task_model.dart';
import '../../repositories/task_repository.dart';
import '../../core/errors/app_exception.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

  TaskBloc(this.repository) : super(TaskInitial()) {
    on<LoadTasks>(_loadTasks);
    on<AddTask>(_addTask);
    on<UpdateTask>(_updateTask);
    on<DeleteTask>(_deleteTask);
  }

  Future<void> _loadTasks(
    LoadTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());

    try {
      final tasks = await repository.getAllTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError('Unable to load tasks.'));
    }
  }

  Future<void> _addTask(
    AddTask event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await repository.createTask(event.task);

      final tasks = await repository.getAllTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError(
        e is AppException ? e.message : 'Unable to add task.',
      ));
    }
  }

  Future<void> _updateTask(
    UpdateTask event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await repository.updateTask(event.task);

      final tasks = await repository.getAllTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError(
        e is AppException ? e.message : 'Unable to update task.',
      ));
    }
  }

  Future<void> _deleteTask(
    DeleteTask event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await repository.deleteTask(event.id);

      final tasks = await repository.getAllTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError(
        e is AppException ? e.message : 'Unable to delete task.',
      ));
    }
  }
}