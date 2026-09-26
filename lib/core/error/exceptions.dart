/// Low-level exceptions raised by data sources.
///
/// These never cross the Domain boundary. Repository implementations
/// catch them and translate to Failures.
library;

class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Network is unreachable — DNS lookup failed, socket connect failed, or the
/// device is offline entirely. Distinct from [ServerException] (the backend
/// responded but with an unexpected payload / 5xx). The repository translates
/// this to `NetworkFailure` so the UI can show "no internet" copy rather than
/// the (incorrect) "server error."
class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  const CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Unauthorized']);
  final String message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found']);
  final String message;
}

/// An optimistic-lock guard tripped: another writer advanced the row's version
/// since the client read it (Postgres `40001` / HTTP `409`). The caller should
/// refresh from the realtime stream and retry — this is benign, not an error.
class ConflictException implements Exception {
  ConflictException([this.message = 'Conflicting concurrent update']);
  final String message;

  @override
  String toString() => 'ConflictException: $message';
}

/// Request validation failed at the edge / API boundary (HTTP 422 / 400).
class ValidationException implements Exception {
  ValidationException([this.message = 'Validation failed']);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

/// An OS permission was refused or the backing service is disabled (e.g. the
/// user denied location access, or device location services are off).
class PermissionException implements Exception {
  PermissionException([this.message = 'Permission denied']);
  final String message;

  @override
  String toString() => 'PermissionException: $message';
}

/// The operation was aborted or cancelled (e.g. via abortSignal or user cancellation).
class OperationCancelledException implements Exception {
  const OperationCancelledException([this.message = 'Operation was cancelled']);
  final String message;

  @override
  String toString() => 'OperationCancelledException: $message';
}

