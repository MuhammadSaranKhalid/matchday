/// Typed errors that flow from Data → Domain → Presentation.
///
/// Why sealed: the compiler forces the UI to handle every case in a switch.
/// Why a base class: lets repository signatures stay generic — `Either<Failure, T>`.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// No connectivity, DNS, socket errors.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Backend reachable, but returned 5xx or an unexpected payload.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

/// 401/403, invalid credentials, expired session.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

/// Local cache / DB read or write failed.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

/// Value object construction failed (invalid email, weak password, etc).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 404 from the backend, or expected row missing locally.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// An OS-level permission was denied (location, camera, contacts, …), or the
/// underlying service is switched off. The UI typically responds by prompting
/// the user to grant access or open settings.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

/// Optimistic-lock conflict — a concurrent writer advanced the version
/// (HTTP 409 / Postgres 40001). Benign: the realtime stream already delivers
/// the fresh state, so the UI can refresh and retry without alarming the user.
class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Updated elsewhere — please retry']);
}

/// Catch-all for anything we genuinely didn't see coming.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}

/// The operation was deliberately cancelled before completing (e.g. superseded by a newer query).
class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'Operation cancelled']);
}


/// Adapts a [Failure] into a throwable so it can travel as an error through a
/// `Stream` or `AsyncNotifier`, then be recovered in the UI via
/// `error is FailureWrapper`. Keeps the typed [Failure] intact across the
/// reactive boundary, where only `Object` errors are allowed.
class FailureWrapper implements Exception {
  const FailureWrapper(this.failure);
  final Failure failure;

  @override
  String toString() => 'FailureWrapper(${failure.message})';
}

/// The user-facing message for an `AsyncError` / stream error: the typed
/// [Failure] message when one survived the reactive boundary, else the raw
/// error's string form.
String failureMessageOf(Object error) => switch (error) {
      FailureWrapper(:final failure) => failure.message,
      Failure(:final message) => message,
      _ => error.toString(),
    };
