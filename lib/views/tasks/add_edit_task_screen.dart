import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/task_controller/task_bloc.dart';
import '../../controllers/task_controller/task_event.dart';
import '../../models/task_model.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  final List<String> categories = [
    'General',
    'Work',
    'Personal',
    'Study',
    'Health',
    'Other',
  ];

  late TaskPriority priority;
  late TaskStatus status;
  late String category;

  DateTime? dueDate;
  TimeOfDay? dueTime;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    titleController = TextEditingController(text: task?.title ?? '');

    descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    priority = task?.priority ?? TaskPriority.medium;
    status = task?.status ?? TaskStatus.todo;
    category = task?.category ?? 'General';

    dueDate = task?.dueDate;

    if (task?.dueDate != null) {
      dueTime = TimeOfDay.fromDateTime(task!.dueDate!);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectDueDate() async {
    final now = DateTime.now();

    final initialDate = dueDate != null && dueDate!.isBefore(now)
        ? now
        : dueDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        dueDate = selectedDate;
      });
    }
  }

  Future<void> selectDueTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: dueTime ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        dueTime = selectedTime;
      });
    }
  }

  String? validateDeadline() {
    if (dueDate == null) return null;

    final selectedDeadline = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime?.hour ?? 23,
      dueTime?.minute ?? 59,
    );

    if (selectedDeadline.isBefore(DateTime.now())) {
      return 'Please select a future deadline.';
    }

    return null;
  }

  void saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final deadlineError = validateDeadline();

    if (deadlineError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(deadlineError), backgroundColor: Colors.red),
      );
      return;
    }

    final now = DateTime.now();

    final task = TaskModel(
      id: widget.task?.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: category,
      priority: priority,
      status: status,
      dueDate: dueDate == null
          ? null
          : DateTime(
              dueDate!.year,
              dueDate!.month,
              dueDate!.day,
              dueTime?.hour ?? 23,
              dueTime?.minute ?? 59,
            ),
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      context.read<TaskBloc>().add(UpdateTask(task));
    } else {
      context.read<TaskBloc>().add(AddTask(task));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Create Task')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'Enter task title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title.';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must contain at least 3 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      category = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<TaskPriority>(
                initialValue: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: TaskPriority.values.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.name[0].toUpperCase() + item.name.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      priority = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<TaskStatus>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                items: TaskStatus.values.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.name == 'inProgress'
                          ? 'In Progress'
                          : item.name[0].toUpperCase() + item.name.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      status = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Deadline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: selectDueDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        dueDate == null
                            ? 'Select Date'
                            : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: dueDate == null ? null : selectDueTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        dueTime == null
                            ? 'Select Time'
                            : dueTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),

              if (dueDate != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        dueDate = null;
                        dueTime = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Remove deadline'),
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveTask,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? 'Update Task' : 'Create Task'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
