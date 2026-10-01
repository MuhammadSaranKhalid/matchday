# Migration Guide

## Principles

1. **Architecture first, screens second**: Introduce the underlying system and compatibility bridges before touching existing screen layouts.
2. **Zero breaking changes**: Legacy symbols (`CkColors`, `CkRadii`, `CkType`, `buildCirckTheme()`) remain available as forwarding facades until screen migrations are complete.
3. **Clean responsibility naming**:
   - `CkButton` → `ActionButton`
   - `CkIconButton` → `ActionIconButton`
   - `CkSurface` → `Surface`
   - `CkBadge` → `StatusBadge`
   - `CkChip` → `SelectionChip`
   - `CkTextField` → `TextInput`
   - `CkSearchField` → `SearchField`
   - `CkEmptyState` → `EmptyState`
   - `CkConfirmDialog` → `ConfirmationDialog`
   - `CkBottomSheet` → `AppBottomSheet`

---

## Migration Phases

- [x] **Phase 1**: Foundations (`Palette`, `Spacing`, `Radii`, `Sizing`, `Motion`), `AppTheme`, `LayoutTokens`, `TextTokens`, architecture boundary rules, zero visual changes.
- [x] **Phase 2**: Core primitives (`ActionButton`, `ActionIconButton`, `Surface`, `TextInput`, `SearchField`, `SelectionChip`, `StatusBadge`, `Avatar`, `AppDivider`).
- [x] **Phase 3**: Patterns & Layout (`EmptyState`, `ErrorState`, `AppBottomSheet`, `ConfirmationDialog`, Headers, Screen layouts, accessibility tap target enforcement).
- [x] **Phase 4**: Widgetbook nested package + golden/accessibility tests + drift tests.
- [x] **Phase 5**: Migrate My Matches & My Tournaments (including screen shells, list rhythm, and domain components: `FixtureCard`, `PastCard`, `HubCard`, `HubStatusPill`, and `TournamentCardShimmer`).
- [ ] **Phase 6**: Migrate Messages (remove `ChatTheme`) & Profile.
- [ ] **Phase 7**: Migrate Teams, Explore, Notifications, Posts (decompose `v2_kit.dart`).
- [ ] **Phase 8**: Tournament & Match operational flows, scoring chrome.
- [ ] **Phase 9**: Delete legacy compatibility layers.

---

## Pre-Phase 6 Hardening & Polish Pass

Before proceeding to Phase 6 (Messages/Profile), two rounds of architectural review and hardening were performed to lock in quality, accessibility, visual regression baselines, and semantic correctness:

### 1. Secondary Text Contrast & Semantic Tokens
- **Problem**: `scheme.outline` (`#E6E2D9`, border line) was inadvertently used for secondary text in multiple components, yielding an unusable ~1.24:1 contrast ratio against `#FBFAF6` paper.
- **Resolution**:
  - `scheme.outline` and `scheme.outlineVariant` are strictly reserved for borders and hairlines.
  - Configured `scheme.onSurfaceVariant` to `Palette.ink2` (`#4A4339`), delivering ~8.5:1 contrast on paper (surpassing WCAG AA 4.5:1).
  - Migrated `EmptyState`, `ErrorState`, `ChoiceCard`, `WizardHeader`, `PushHeader`, `SelectionTile`, `SearchField`, `SegmentedControl`, and `SectionHeader` to `scheme.onSurfaceVariant`.

### 2. Complete Material 3 ColorScheme Specification
- Avoided default fallbacks by explicitly providing all core Material 3 color roles in `AppTheme.buildAppTheme()`:
  - `onSurfaceVariant: Palette.ink2`
  - `errorContainer: Palette.redSurface`
  - `onErrorContainer: Palette.redInk`
  - `surfaceContainerLowest: Palette.surface`
  - `surfaceContainerLow: Palette.paper`
  - `surfaceContainer: Palette.paper2`
  - `surfaceContainerHigh: Palette.card`
  - `surfaceContainerHighest: Palette.line`
  - `shadow: Palette.ink`
  - `scrim: Palette.ink`
  - `surfaceTint: Colors.transparent`

### 3. Decoupling Destructive Actions from Live Semantics
- Separated `ActionButton.destructive` and `ConfirmationDialog` destructive styling from `StatusColors.live`.
- Destructive actions now consistently consume `scheme.error`, `scheme.errorContainer`, and `scheme.onErrorContainer`.

### 4. Warning Badge Contrast
- Updated `StatusColors.warning` from `Palette.amberInk` (4.11:1 on cream) to `Palette.amberDark` (`#6B5414`), achieving ~6.16:1 contrast for small status labels.

### 5. Accessibility Testing with Text Contrast Guidelines
- Integrated `meetsGuideline(textContrastGuideline)` into `test/core/design_system/accessibility_test.dart` for:
  - `EmptyState`, `ErrorState`, `ChoiceCard`, `TextInput`, `SearchField`, `SegmentedControl`, `StatusBadge` (live, success, warning, neutral), `PushHeader`, and `WizardHeader`.
- All text contrast checks pass with zero violations.

### 6. Golden Regression Test Baseline
- Added canonical golden snapshot tests in `test/core/design_system/golden_test.dart` covering:
  - `ActionButton` variants and sizes
  - `SegmentedControl`
  - `EmptyState` variants
  - `StatusBadge` tones
  - `SearchField` variants
  - `ConfirmationDialog`
  - `PushHeader`
- Baseline master images stored in `test/core/design_system/goldens/`.

### 7. Layout Layer Theme & Density Adoption
- Modernized `ScreenLayout`, `ScrollScreenLayout`, `Section`, `StickyFooter`, `AppBottomSheet`, and `LoadingState`:
  - Consumes `context.layout` (`screenGutter`, `cardPadding`, `screenBottom`, `inlineGap`, `sectionGap`) and `context.colorScheme`.
  - In `Section`, `spacing` and `bottomGap` are nullable and dynamically resolve against layout tokens when unspecified.

### 8. Phase 5 Domain Components Modernization
- Domain components in My Matches and My Tournaments migrated to consume the new design system directly:
  - `FixtureCard`: uses `Surface`, `context.layout`, `context.colorScheme`, and semantic text tokens.
  - `PastCard`: uses `Material` surface, `context.layout`, and `StatusBadge`.
  - `HubCard`: consumes `Surface` and layout tokens.
  - `HubStatusPill`: unified with `StatusBadge`.
  - `TournamentCardShimmer`: unified with `ShimmerLoading` and `ShimmerBox`.
- Purged legacy `circk_theme.dart` and `Ck*` references from My Matches and My Tournaments domain card widgets.

### 9. Screen-Level Spacing Cleanup
- Replaced all 23 direct `Spacing.*` references in `my_tournaments_screen.dart` and remaining references in `my_matches_screen.dart` with `context.layout.*`.

### 10. Motion Tokens & Documentation Clarification
- Updated `SegmentedControl` animation to use `Motion.durationFast` and `Motion.curveFast`.
- Clarified `SelectionChip` documentation to state it is for filter facets and multi-select tags, not mutually exclusive primary screen navigation (which uses `SegmentedControl`).


