# Matchday UI Architecture

## Architectural Boundaries

The design system sits at the base of the presentation architecture:

```text
                  ┌───────────────────────┐
                  │ Feature Presentation  │
                  │ (screens, widgets)    │
                  └───────────┬───────────┘
                              │
                              ▼
                  ┌───────────────────────┐
                  │  core/design_system   │
                  │ (primitives, layouts) │
                  └───────────┬───────────┘
                              │
                              ▼
                  ┌───────────────────────┐
                  │ Flutter ThemeData /   │
                  │ ThemeExtension tokens │
                  └───────────────────────┘
```

### Invariant Rules
1. **Design System must NEVER depend on features**:
   - `core/design_system` must have zero imports of `features/*`.
   - Enforced by `test/architecture_test.dart`.
2. **Domain must NEVER depend on Design System**:
   - `features/*/domain` is pure Dart and must not import any UI code.
   - Enforced by `test/architecture_test.dart`.
3. **Features compose Design System**:
   - Features consume `ActionButton`, `Surface`, `StatusBadge`, `SelectionChip`, `TextInput`, `EmptyState`, etc.
   - Domain widgets (e.g. `FixtureCard`, `TournamentCard`) wrap `Surface` instead of rebuilding custom card containers.
4. **ThemeExtension Contract**:
   - Standard layout metrics live in `LayoutTokens` registered in `ThemeData.extensions`.
   - Domain-specific tabular/mono typography lives in `TextTokens`.
   - Accessed conveniently via `context.layout` and `context.textTokens`.
