import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_assignment/controllers/task_controller/task_bloc.dart';
import 'package:flutter_application_assignment/controllers/task_controller/task_event.dart';
import 'package:flutter_application_assignment/controllers/task_controller/task_state.dart';
import 'package:flutter_application_assignment/models/task_model.dart';
import 'package:flutter_application_assignment/repositories/task_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class FakeTaskModel extends Fake implements TaskModel {}

void main() {
  late MockTaskRepository repository;

  final now = DateTime(2026, 11, 6, 10, 0);
  final task1 = TaskModel(
    id: 1,
    title: 'Alpha Task',
    description: 'First description',
    category: 'Work',
    priority: TaskPriority.high,
    status: TaskStatus.todo,
    createdAt: now.subtract(const Duration(hours: 2)),
    updatedAt: now.subtract(const Duration(hours: 2)),
  );

  final task2 = TaskModel(
    id: 2,
    title: 'Beta Task',
    description: 'Second description',
    category: 'Personal',
    priority: TaskPriority.low,
    status: TaskStatus.completed,
    createdAt: now.subtract(const Duration(hours: 1)),
    updatedAt: now.subtract(const Duration(hours: 1)),
  );

  setUpAll(() {
    registerFallbackValue(FakeTaskModel());
  });

  setUp(() {
    repository = MockTaskRepository();
  });

  group('TaskBloc', () {
    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskLoaded] on LoadTasks success',
      build: () {
        when(() => repository.getAllTasks())
            .thenAnswer((_) async => [task2, task1]);
        return TaskBloc(repository);
      },
      act: (bloc) => bloc.add(LoadTasks()),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>().having((s) => s.tasks.length, 'tasks.length', 2),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits TaskError when adding duplicate task and preserves existing tasks',
      build: () {
        when(
          () => repository.isDuplicateTask(
            title: any(named: 'title'),
            category: any(named: 'category'),
            excludeId: any(named: 'excludeId'),
          ),
        ).thenAnswer((_) async => true);
        when(() => repository.getAllTasks()).thenAnswer((_) async => [task1]);
        return TaskBloc(repository);
      },
      act: (bloc) => bloc.add(AddTask(task1)),
      expect: () => [
        const TaskError(
          'A task with this title already exists in this category.',
        ),
        isA<TaskLoaded>().having(
          (s) => s.allTasks.length,
          'allTasks.length',
          1,
        ),
      ],
      verify: (_) {
        verifyNever(() => repository.createTask(any()));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'creates task, emits TaskActionSuccess and updates list when AddTask succeeds',
      build: () {
        when(
          () => repository.isDuplicateTask(
            title: any(named: 'title'),
            category: any(named: 'category'),
            excludeId: any(named: 'excludeId'),
          ),
        ).thenAnswer((_) async => false);
        when(() => repository.createTask(any())).thenAnswer((_) async => 3);
        when(() => repository.getAllTasks()).thenAnswer((_) async => [task1]);
        return TaskBloc(repository);
      },
      act: (bloc) => bloc.add(
        AddTask(
          TaskModel(
            title: 'New Task',
            description: 'New Description',
            category: 'Study',
            priority: TaskPriority.medium,
            status: TaskStatus.todo,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ),
      expect: () => [
        const TaskActionSuccess('Task created successfully.'),
        isA<TaskLoaded>(),
      ],
      verify: (_) {
        verify(() => repository.createTask(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'preserves active filters and search query when a task is updated',
      build: () {
        when(() => repository.getAllTasks())
            .thenAnswer((_) async => [task1, task2]);
        when(
          () => repository.isDuplicateTask(
            title: any(named: 'title'),
            category: any(named: 'category'),
            excludeId: any(named: 'excludeId'),
          ),
        ).thenAnswer((_) async => false);
        when(() => repository.updateTask(any())).thenAnswer((_) async => 1);
        return TaskBloc(repository);
      },
      seed: () => TaskLoaded(
        tasks: [task1],
        allTasks: [task1, task2],
        searchQuery: 'Alpha',
        category: 'Work',
        priority: TaskPriority.high,
      ),
      act: (bloc) => bloc.add(
        UpdateTask(task1.copyWith(description: 'Updated Description')),
      ),
      expect: () => [
        const TaskActionSuccess('Task updated successfully.'),
        isA<TaskLoaded>()
            .having((s) => s.searchQuery, 'searchQuery preserved', 'Alpha')
            .having((s) => s.category, 'category preserved', 'Work')
            .having((s) => s.priority, 'priority preserved', TaskPriority.high),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'rejects duplicate task update with different id',
      build: () {
        when(
          () => repository.isDuplicateTask(
            title: any(named: 'title'),
            category: any(named: 'category'),
            excludeId: any(named: 'excludeId'),
          ),
        ).thenAnswer((_) async => true);
        when(() => repository.getAllTasks())
            .thenAnswer((_) async => [task1, task2]);
        return TaskBloc(repository);
      },
      act: (bloc) => bloc.add(
        UpdateTask(
          task1.copyWith(title: task2.title, category: task2.category),
        ),
      ),
      expect: () => [
        const TaskError(
          'Another task with this title already exists in this category.',
        ),
        isA<TaskLoaded>(),
      ],
      verify: (_) {
        verifyNever(() => repository.updateTask(any()));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'filters tasks correctly when SearchTasks is triggered',
      build: () => TaskBloc(repository),
      seed: () => TaskLoaded(tasks: [task1, task2], allTasks: [task1, task2]),
      act: (bloc) => bloc.add(const SearchTasks('Beta')),
      expect: () => [
        isA<TaskLoaded>()
            .having((s) => s.tasks.length, 'tasks.length', 1)
            .having((s) => s.tasks.first.title, 'first title', 'Beta Task')
            .having((s) => s.searchQuery, 'searchQuery', 'Beta'),
      ],
    );
  });
}
