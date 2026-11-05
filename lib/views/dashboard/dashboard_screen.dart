import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_event.dart';
import '../../controllers/task_controller/task_state.dart';
import '../../models/task_model.dart';
import '../tasks/add_edit_task_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final TextEditingController searchController =
      TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // DELETE TASK

  Future<void> deleteTask(
    BuildContext context,
    TaskModel task,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true &&
        task.id != null &&
        context.mounted) {
      context.read<TaskBloc>().add(
        DeleteTask(task.id!),
      );
    }
  }

  // PRIORITY COLORS

  Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;

      case TaskPriority.medium:
        return Colors.orange;

      case TaskPriority.high:
        return Colors.red;
    }
  }
    // FILTER BOTTOM SHEET

  void showFilterSheet(
    BuildContext context,
    TaskLoaded state,
  ) {
    TaskPriority? priority = state.priority;
    TaskStatus? status = state.status;
    String? category = state.category;
    DateTime? dueDate = state.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context)
                        .viewInsets.bottom +
                    20,
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Filter Tasks',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PRIORITY

                    DropdownButtonFormField<TaskPriority?>(
                      initialValue: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All priorities'),
                        ),
                        ...TaskPriority.values.map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          priority = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // STATUS

                    DropdownButtonFormField<TaskStatus?>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All statuses'),
                        ),
                        ...TaskStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          status = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // CATEGORY

                    DropdownButtonFormField<String?>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...[
                          'General',
                          'Work',
                          'Personal',
                          'Study',
                          'Health',
                          'Other',
                        ].map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          category = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // DUE DATE

                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              dueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (selected != null) {
                          setModalState(() {
                            dueDate = selected;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_month,
                      ),
                      label: Text(
                        dueDate == null
                            ? 'Filter by due date'
                            : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                      ),
                    ),

                    if (dueDate != null)
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            dueDate = null;
                          });
                        },
                        child: const Text(
                          'Remove date filter',
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ACTION BUTTONS

                    Row(
                      children: [

                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<TaskBloc>().add(
                                ClearTaskFilters(),
                              );

                              searchController.clear();

                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Clear'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<TaskBloc>().add(
                                FilterTasks(
                                  priority: priority,
                                  status: status,
                                  category: category,
                                  dueDate: dueDate,
                                ),
                              );

                              Navigator.pop(sheetContext);
                            },
                            child: const Text(
                              'Apply Filters',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
    // MAIN BUILD METHOD

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'TaskFlow',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: BlocConsumer<TaskBloc, TaskState>(

        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },

        builder: (context, state) {

          // LOADING

          if (state is TaskLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ERROR

          if (state is TaskError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Text(state.message),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () {
                      context.read<TaskBloc>().add(
                        LoadTasks(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // TASK LOADED

          if (state is TaskLoaded) {
            return Column(
              children: [

                // SEARCH BAR

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 8,
                  ),

                  child: TextField(
                    controller: searchController,

                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),

                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          if (searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                searchController.clear();

                                context.read<TaskBloc>().add(
                                  const SearchTasks(''),
                                );

                                setState(() {});
                              },
                            ),

                          IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () {
                              showFilterSheet(
                                context,
                                state,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    onChanged: (value) {
                      context.read<TaskBloc>().add(
                        SearchTasks(value),
                      );

                      setState(() {});
                    },
                  ),
                ),

                // SORTING AND RESULT COUNT

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [

                      Text(
                        '${state.tasks.length} tasks found',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      PopupMenuButton<TaskSortOption>(
                        onSelected: (value) {
                          context.read<TaskBloc>().add(
                            SortTasks(value),
                          );
                        },

                        itemBuilder: (context) => const [

                          PopupMenuItem(
                            value: TaskSortOption.newest,
                            child: Text('Newest First'),
                          ),

                          PopupMenuItem(
                            value: TaskSortOption.oldest,
                            child: Text('Oldest First'),
                          ),

                          PopupMenuItem(
                            value: TaskSortOption.dueDate,
                            child: Text('Due Date'),
                          ),

                          PopupMenuItem(
                            value: TaskSortOption.priority,
                            child: Text('Priority'),
                          ),
                        ],

                        child: const Row(
                          children: [
                            Icon(Icons.sort),
                            SizedBox(width: 5),
                            Text('Sort'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // TASK LIST STARTS IN CHUNK 4

                Expanded(
                  child: _buildTaskList(context, state),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),

      // ADD TASK BUTTON

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditTaskScreen(),
            ),
          );
        },

        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
    // TASK LIST

  Widget _buildTaskList(
    BuildContext context,
    TaskLoaded state,
  ) {

    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Icon(
              Icons.search_off,
              size: 55,
              color: Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              state.allTasks.isEmpty
                  ? 'No tasks yet!\nCreate your first task.'
                  : 'No matching tasks found.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

            if (state.allTasks.isNotEmpty)
              TextButton(
                onPressed: () {
                  searchController.clear();

                  context.read<TaskBloc>().add(
                    ClearTaskFilters(),
                  );
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),

      itemCount: state.tasks.length,

      itemBuilder: (context, index) {
        final task = state.tasks[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),

          child: Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // TITLE AND ACTIONS

                Row(
                  children: [

                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditTaskScreen(
                              task: task,
                            ),
                          ),
                        );
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        deleteTask(context, task);
                      },
                    ),
                  ],
                ),

                // DESCRIPTION

                Text(task.description),

                const SizedBox(height: 12),

                // TASK DETAILS

                Wrap(
                  spacing: 8,
                  runSpacing: 8,

                  children: [

                    Chip(
                      label: Text(
                        task.priority.name,
                      ),

                      backgroundColor:
                          getPriorityColor(task.priority)
                              .withValues(alpha: 0.15),
                    ),

                    Chip(
                      label: Text(task.category),
                    ),

                    if (task.dueDate != null)
                      Chip(
                        avatar: const Icon(
                          Icons.calendar_today,
                          size: 16,
                        ),

                        label: Text(
                          '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // STATUS DROPDOWN

                DropdownButtonFormField<TaskStatus>(
                  initialValue: task.status,

                  decoration: const InputDecoration(
                    labelText: 'Task Status',

                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),

                  items: TaskStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.name),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value != null) {
                      context.read<TaskBloc>().add(
                        UpdateTask(
                          task.copyWith(
                            status: value,
                            updatedAt: DateTime.now(),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}