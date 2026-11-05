class AppException implements Exception {
  final String message;
  final String? details;

  AppException(this.message, {this.details});

  @override
  String toString() => message;
}

class DatabaseAppException extends AppException {
  DatabaseAppException(super.message, {super.details});
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class ImportExportException extends AppException {
  ImportExportException(super.message, {super.details});
}