# Layout & Navigation

## Layout Components

Located in `lib/core/design_system/layout/`.

### 1. ScreenLayout
Non-scrolling screen wrapper with header, bottom navigation bar, and sticky footer:
```dart
ScreenLayout(
  header: PushHeader(title: 'Edit Profile'),
  body: Center(child: Text('Content')),
  stickyFooter: StickyFooter(
    child: ActionButton(label: 'Save Changes', onPressed: () {}),
  ),
)
```

### 2. ScrollScreenLayout
Standard scrolling screen layout with built-in pull-to-refresh, standard padding (`context.layout.screenGutter`), and safe area handling:
```dart
ScrollScreenLayout(
  header: PushHeader(title: 'My Matches'),
  onRefresh: () async => ref.refresh(myMatchesProvider),
  children: [
    Section(
      title: 'Upcoming',
      child: UpcomingMatchesList(),
    ),
    Section(
      title: 'Past Matches',
      child: PastMatchesList(),
    ),
  ],
)
```

### 3. Section
Structural content block that standardizes section header hierarchy and inter-section vertical rhythm:
```dart
Section(
  title: 'Tournament Squad',
  eyebrow: '15 Players',
  actionLabel: 'Add player',
  onAction: () => openAddPlayerSheet(),
  child: SquadGrid(),
)
```

### 4. StickyFooter
Pinned bottom action container with hairline top border, background fill, and safe area insets:
```dart
StickyFooter(
  child: ActionButton(
    label: 'Confirm Selection',
    onPressed: () {},
  ),
)
```

---

## Navigation Headers

Located in `lib/core/design_system/navigation/`.

1. **`RootHeader`**: Top-level tab header (Home, Explore, Matches, Messages, Profile) with wordmark/title and icon action slots.
2. **`PushHeader`**: Standard back navigation (`ActionIconButton.subtle`) + title + subtitle + trailing actions.
3. **`WizardHeader`**: Multi-step flow header with back button, step eyebrow ("Step 2 of 4"), fractional progress bar, large title, and description.
4. **`ComposerHeader`**: Modal creator header with cancel button, title, and compact primary CTA ("Publish", "Post").
