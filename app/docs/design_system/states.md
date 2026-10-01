# States & Modals

## State Patterns

Located in `lib/core/design_system/components/feedback/` and `components/overlays/`.

### 1. EmptyState & StateRegion
Eliminates ad-hoc positioning hacks (`Spacer()`, `Padding(top: 72)`) by managing vertical viewport space intelligently:

```dart
// First run with primary + secondary CTA
StateRegion(
  child: EmptyState(
    kind: EmptyStateKind.firstRun,
    icon: Icons.sports_cricket,
    title: 'No matches yet',
    description: 'Challenge an opponent or set up your first fixture.',
    primaryAction: StateAction(
      label: 'Create match',
      onPressed: () => openCreateMatch(),
    ),
    secondaryAction: StateAction(
      label: 'Find squads',
      onPressed: () => openExplore(),
    ),
  ),
)

// Section empty (smaller and quieter)
EmptyState(
  kind: EmptyStateKind.section,
  title: 'No recent activity',
)

// Filtered empty
EmptyState(
  kind: EmptyStateKind.filtered,
  title: 'No results found',
  description: 'Try adjusting your search or filters.',
)
```

### 2. ErrorState
Contextual error display with standard retry actions:
```dart
ErrorState(
  kind: ErrorStateKind.offline,
  title: 'Connection lost',
  description: 'Check your internet connection and try again.',
  onRetry: () => reload(),
)
```

### 3. LoadingState & Shimmer
- `LoadingState`: Centered spinner with optional loading message.
- `ShimmerLoading`: Horizontal highlight gradient sweeping across placeholders.
- `ShimmerBox`: Static geometric placeholder for composing domain skeletons (`FixtureCardSkeleton`, `TournamentCardSkeleton`).

---

## Modals & Dialogs

### 1. ConfirmationDialog
Launches a standardized modal with button hierarchy encoding reversibility:
```dart
final confirmed = await showConfirmationDialog(
  context,
  icon: Icons.delete_outline,
  title: 'Delete tournament?',
  body: 'This will remove the tournament and all associated fixtures.',
  confirmLabel: 'Delete tournament',
  cancelLabel: 'Keep tournament',
  destructive: true,
);
```

### 2. AppBottomSheet
Standardized bottom sheet modal shell:
```dart
showAppBottomSheet(
  context,
  builder: (context) => AppBottomSheet(
    header: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Filters', style: context.theme.textTheme.titleMedium),
    ),
    body: FilterForm(),
    footer: ActionButton(
      label: 'Apply Filters',
      onPressed: () => applyFilters(),
    ),
  ),
);
```
