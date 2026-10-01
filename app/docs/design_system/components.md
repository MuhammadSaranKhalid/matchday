# Primitives & Components

## Core Primitives

Located in `lib/core/design_system/components/`.

### 1. ActionButton
Standardized button primitive supporting four intent variants and three standardized control sizes:
```dart
ActionButton(
  label: 'Create tournament',
  onPressed: () {},
)

ActionButton.secondary(
  label: 'Cancel',
  onPressed: () {},
)

ActionButton.ghost(
  label: 'Skip',
  onPressed: () {},
)

ActionButton.destructive(
  label: 'Delete tournament',
  onPressed: () {},
)
```
- **Control Sizes**:
  - `ControlSize.compact`: 40.0 visual height (interaction target is automatically padded to >= 48.0).
  - `ControlSize.standard`: 48.0 height.
  - `ControlSize.large`: 52.0 height (default for prominent CTAs).
- **Parameters**: `label`, `onPressed`, `variant`, `size`, `icon`, `loading` (shows spinner and disables tap), `expand` (stretches to full width).

---

### 2. ActionIconButton
Standardized header and navigation action button ensuring minimum 48x48 dp touch target regardless of compact visual affordance (36.0):
```dart
ActionIconButton(
  icon: Icons.arrow_back,
  onPressed: () => context.pop(),
)

ActionIconButton.outlined(
  icon: Icons.tune,
  onPressed: () => openFilters(),
)

ActionIconButton.subtle(
  icon: Icons.more_horiz,
  onPressed: () => showOptions(),
)
```

---

### 3. Surface
Standardized card and container chrome primitive:
```dart
Surface(
  density: SurfaceDensity.standard,
  variant: SurfaceVariant.outlined,
  onTap: () => viewMatch(),
  child: FixtureCardContent(...),
)
```
- **Densities**:
  - `SurfaceDensity.compact`: 12.0 padding.
  - `SurfaceDensity.standard`: 16.0 padding.
  - `SurfaceDensity.comfortable`: 20.0 padding.
- **Variants**: `plain`, `outlined`, `subtle`, `raised`, `accent`.

---

### 4. StatusBadge
Informational status badges (LIVE, FINAL, CAPTAIN, OWNER, DRAFT, UPCOMING):
```dart
StatusBadge(
  label: 'LIVE',
  tone: StatusTone.live,
)

StatusBadge(
  label: 'CAPTAIN',
  tone: StatusTone.neutral,
)
```
- **Tones**: `neutral`, `ink`, `live`, `success`, `warning`, `destructive`.

---

### 5. SelectionChip
Interactive filter chips and category toggles:
```dart
SelectionChip(
  label: 'Upcoming',
  selected: isSelected,
  count: 3,
  onPressed: () => toggleFilter(),
)
```

---

### 6. TextInput
Labeled single and multi-line text input fields:
```dart
TextInput(
  label: 'Team name',
  hint: 'e.g. Lahore Lions',
  controller: nameController,
)

TextInput.multiline(
  label: 'Description',
  hint: 'Tournament rules and details...',
  maxLines: 4,
  controller: descController,
)
```

---

### 7. SearchField
Encapsulated search input with clear button, loading spinner, and contextual styles:
```dart
// Standard search
SearchField(
  controller: searchController,
  onChanged: (query) => onSearch(query),
)

// Pill search (Inbox / Messages)
SearchField(
  variant: SearchFieldVariant.pill,
  hintText: 'Search chats...',
  controller: chatSearchController,
)

// Prominent search (Explore)
SearchField(
  variant: SearchFieldVariant.prominent,
  hintText: 'Search players, teams, matches...',
  controller: exploreController,
)
```

---

### 8. Avatar
User and team avatar with remote thumbnail caching and typographic monogram fallback:
```dart
Avatar(
  mono: 'SL',
  imageUrl: player.avatarUrl,
  size: 40,
  tone: AvatarTone.paper,
)
```
