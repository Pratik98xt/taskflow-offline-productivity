TaskFlow — Offline Productivity & Task Management App

TaskFlow is a Flutter-based offline productivity application designed to help users organize, manage, and track their daily tasks efficiently.

The application provides task management, Kanban workflow visualization, productivity analytics, local notifications, and JSON backup functionality. All application data is stored locally using SQLite, allowing the app to work without an internet connection or cloud services.

Features

1. Task Management

* Create, edit, and delete tasks.
* Set task titles and descriptions.
* Organize tasks using categories.
* Assign Low, Medium, or High priority.
* Set deadlines with date and time.
* Update task status.

2. Kanban Board

* Visualize tasks across three workflow stages:
    * To Do
    * In Progress
    * Completed
* Move tasks between columns using drag and drop.
* View task counts for each stage.

3. Search, Filter & Sort

* Search tasks by title and description.
* Filter by priority, status, category, and due date.
* Sort by newest, oldest, due date, and priority.
* Clear filters to restore the complete task list.

4. Productivity Analytics

* View total tasks.
* Track completed tasks.
* Monitor pending and overdue tasks.
* View task completion percentage.
* Visualize task distribution using charts.

5. Local Notifications

* Schedule reminders for task deadlines.
* Receive local notifications.
* Update or cancel reminders when task details change.
* Cancel reminders when tasks are completed or deleted.

6. Import & Export

* Export tasks as JSON backup files.
* Import previously exported TaskFlow backups.
* Validate backup file structure.
* Prevent duplicate tasks during import.

7. Offline-First Architecture

* SQLite local database.
* No Firebase or cloud backend.
* No external API dependency.
* Application data remains available offline.

Technology Stack

Technology	Purpose
Flutter	Cross-platform UI development
Dart	Programming language
SQLite (sqflite)	Local database
BLoC	State management
Equatable	State and event comparison
fl_chart	Analytics visualization
flutter_local_notifications	Local notifications
timezone	Notification scheduling
file_picker	JSON import and export
intl	Date formatting

Architecture

TaskFlow follows a combination of:

* MVC Architecture
* BLoC State Management
* Repository Pattern

Application Data Flow

          Views (UI)
              |
              v
        BLoC Controller
              |
              v
        Task Repository
              |
              v
       Database Helper
              |
              v
          SQLite

The UI communicates with BLoC through events. BLoC handles application logic and communicates with the repository. The repository manages data operations through the SQLite database helper.

Project Structure

lib/
├── core/
│   ├── database/
│   ├── errors/
│   ├── theme/
│   └── utils/
│
├── models/
│   └── task_model.dart
│
├── views/
│   ├── dashboard/
│   ├── tasks/
│   ├── kanban/
│   ├── analytics/
│   └── settings/
│
├── controllers/
│   ├── task_controller/
│   ├── dashboard_controller/
│   └── analytics_controller/
│
├── repositories/
│   └── task_repository.dart
│
└── main.dart

Screenshots

Dashboard

Kanban Board

Analytics

Installation and Setup

Prerequisites

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android Emulator or physical Android device

Clone Repository

git clone https://github.com/Pratik98xt/taskflow-offline-productivity.git

Navigate to the project:

cd flutter_application_assignment

Install dependencies:

flutter pub get

Run the application:

flutter run

Build APK

To generate a release APK:

flutter build apk --release

The generated APK will be available at:

build/app/outputs/flutter-apk/app-release.apk

Error Handling

The application includes handling for:

* Invalid task input.
* Duplicate task creation.
* Database operation failures.
* Invalid or corrupted JSON backups.
* Import and export cancellation.
* Invalid deadlines.
* Notification scheduling failures.
* Empty task lists and search results.
* Loading and error states.

Privacy and Data Storage

TaskFlow uses local SQLite storage to maintain task information.

The application does not require:

* User registration.
* Cloud synchronization.
* Firebase or Supabase.
* External backend services.

Task data remains on the user’s device unless manually exported.

Future Improvements

Potential enhancements include:

* Recurring tasks.
* Custom notification preferences.
* Advanced productivity reports.
* Calendar-based task visualization.
* Additional backup and restore options.

Author

Developed as part of the Flutter Developer Internship Technical Assessment at Torchit.

⸻

TaskFlow — Plan Better. Work Smarter. Stay Productive.