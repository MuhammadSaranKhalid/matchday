---
trigger: always_on
description: Quality gates, automated verification, and completion reporting requirements. Always active.
---

# Quality Gates & Verification Protocol

No code change or task is complete until it has passed all quality gates and has been verified mechanically.

---

## 1. Pre-Completion Quality Gates

Before declaring any feature, bug fix, or refactor complete, you **MUST** run and pass:

### Gate 1: Static Analysis
```bash
flutter analyze lib/
```
- Must complete with **0 issues found** (0 errors, 0 warnings).
- If any warnings or errors are introduced in `lib/`, they must be resolved before proceeding.

### Gate 2: Clean Architecture Invariants Test
```bash
flutter test test/architecture_test.dart
```
- Must pass all test groups:
  - Layer direction (the Dependency Rule)
  - Domain must not import data or presentation
  - Data must not import presentation
  - Domain must not import core widgets/theme
  - Removed architecture must stay removed (no use cases)
  - No import cycles anywhere in `lib/`
  - Cross-feature data layer isolation

### Gate 3: Domain Package Purity Check
```bash
v=$(grep -rlE 'package:(flutter|flutter_riverpod|riverpod_annotation|supabase_flutter|supabase|drift|go_router|dio|http)/' lib/features/*/domain 2>/dev/null)
```
- Output must be empty. Any match is an immediate architectural violation.

---

## 2. Git Diff Audit

Before submitting changes:
1. Inspect `git status` and `git diff` for the modified files.
2. Confirm that:
   - No unrelated files were modified.
   - No debug statements (`print()`, temporary logs) were left in source code.
   - No existing comments, license headers, or docstrings were deleted.
   - All new Freezed DTOs or Riverpod providers have generated code updated if needed (`dart run build_runner build --delete-conflicting-outputs`).

---

## 3. Mandatory Completion Report

Your final response to the user for any code modification must include:

1. **What Changed**: Clear summary of modified/created files and their architectural role.
2. **Architectural Justification**: Why this structure was chosen over alternatives, how it fits existing feature boundaries, and how it upholds Clean Architecture.
3. **Verification Results**: Exact output/status of `flutter analyze lib/`, `flutter test test/architecture_test.dart`, and domain purity checks.
4. **Remaining Risks / Follow-up**: Any non-critical follow-ups, pending migrations, or Edge Function deployments needed in the Supabase Dashboard.
