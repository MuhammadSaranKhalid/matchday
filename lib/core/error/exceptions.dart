/// Low-level exceptions raised by data sources.
///
/// These never cross the Domain boundary. Repository implementations
/// catch them and translate to Failures.
library;

class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Unauthorized']);
  final String message;
}

class NotFoundException implements Exception {
  NotFoundException([this.message = 'Not found']);
  final String message;
}

/// An OS permission was refused or the backing service is disabled (e.g. the
/// user denied location access, or device location services are off).
class PermissionException implements Exception {
  PermissionException([this.message = 'Permission denied']);
  final String message;

  @override
  String toString() => 'PermissionException: $message';
}
