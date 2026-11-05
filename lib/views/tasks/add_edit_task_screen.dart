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
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        dueDate = selectedDate;
      });
    }
  }

  void saveTask() {
    if (!_formKey.currentState!.validate()) {
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
      dueDate: dueDate,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Title',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: titleController,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Enter task title',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task title is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: descriptionController,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter task description',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: categories.map((value) {
                  return DropdownMenuItem(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => category = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<TaskPriority>(
                initialValue: priority,
                decoration: const InputDecoration(),
                items: TaskPriority.values.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => priority = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Task Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<TaskStatus>(
                initialValue: status,
                decoration: const InputDecoration(),
                items: TaskStatus.values.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => status = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Due Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: selectDueDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  dueDate == null
                      ? 'Select Due Date'
                      : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                ),
              ),

              if (dueDate != null)
                TextButton(
                  onPressed: () {
                    setState(() => dueDate = null);
                  },
                  child: const Text('Remove due date'),
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveTask,
                  child: Text(isEditing ? 'Update Task' : 'Save Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
