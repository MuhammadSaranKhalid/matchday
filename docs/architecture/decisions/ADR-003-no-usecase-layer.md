# ADR-003: Removal of the Use-Case Layer

## Status
Accepted (2026-05-29)

## Context
Canonical Clean Architecture specifies an Interactor / Use-Case layer (`domain/usecases/`) separating presentation controllers from repositories. In practice across Match Day, almost every use case consisted of a single method that merely forwarded arguments to a repository method:

```dart
class GetTeam {
  final TeamRepository repo;
  GetTeam(this.repo);
  Future<Either<Failure, Team>> call(String id) => repo.getTeam(id);
}
```

This boilerplate created:
- An explosion of trivial files (`lib/features/*/domain/usecases/*.dart`).
- An additional layer of provider declarations (`*UseCaseProvider`).
- Friction during navigation and refactoring without providing tangible isolation or testability gains.

## Decision
We removed the Use-Case / Interactor layer from Match Day:
1. **Controllers Depend Directly on Repositories**:
   - Presentation controllers and notifiers call `ref.read(<feature>RepositoryProvider).method(...)`.
2. **Business Rules Live in Repository Implementations**:
   - The repository implementation (`data/repositories/*_repository_impl.dart`) enforces business validation, value-object integrity, and multi-call orchestration.
   - The repository contract in `domain/repositories/` remains pure Dart and returns `Future<Either<Failure, T>>` or `Stream<T>`.
3. **Form-Level Validation**:
   - Simple field validation (e.g. valid email, username format) occurs in the controller before invoking the repository using Value Objects (`domain/value_objects/`).

## Consequences
### Positive
- Substantial reduction in boilerplate and file count.
- Faster code navigation and feature authoring.
- The dependency graph remains strictly acyclic and Clean Architecture boundaries (Domain purity, inward dependencies) are preserved.

### Negative / Trade-offs
- Repository implementations are slightly larger as they carry both data fetching and business rule coordination.
- Automated tests (`test/architecture_test.dart`) must explicitly forbid any re-emergence of `domain/usecases/`.
