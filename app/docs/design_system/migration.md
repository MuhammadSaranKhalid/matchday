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
- [x] **Phase 5**: Migrate My Matches & My Tournaments.
- [ ] **Phase 6**: Migrate Messages (remove `ChatTheme`) & Profile.
- [ ] **Phase 7**: Migrate Teams, Explore, Notifications, Posts (decompose `v2_kit.dart`).
- [ ] **Phase 8**: Tournament & Match operational flows, scoring chrome.
- [ ] **Phase 9**: Delete legacy compatibility layers.

---

## Architecture Review & Hardening (Pre-Phase 6)

Before proceeding to Phase 6 (Messages/Profile), 14 architectural findings were addressed to ensure long-term integrity:

1. **Semantic Tokens Integration**:
   - Primitives and patterns now consume `context.layout`, `context.colorScheme`, `context.statusColors`, `context.textTokens`, and `context.textTheme` instead of hardcoded raw tokens (`Palette.*`, `Spacing.*`, `Radii.*`).
2. **Single Source of Truth**:
   - `AppTheme` owns default Material theme data (`FilledButtonTheme`, `OutlinedButtonTheme`, `InputDecorationTheme`). Primitives provide semantic variants without conflicting with core radii and borders.
3. **Compatibility Layer Visual Fidelity**:
   - `CkButton.ghost` preserves red text (`Palette.red`).
   - `CkTextField` preserves 12px corner radius for unmigrated screens.
   - `showCkConfirmDialog` restores full-width red destructive button and outline cancel button.
4. **Primary Navigation vs Filter Facets**:
   - Added `SegmentedControl<T>` for primary view switching (e.g. Confirmed | Past in Matches; Organising | Playing | Following in Tournaments).
   - `SelectionChip` is strictly reserved for faceted filtering and multi-select tags.
5. **CI Enforcement**:
   - Added automated CI gates to `.github/workflows/ci.yml` running design system tests (`test/core/design_system/`) and Widgetbook web release builds.
6. **Frozen Drift Baseline Map**:
   - Replaced scalar count check with a frozen per-file map of all 35 legacy files containing `.styleFrom()`. Any new file or count increase fails CI immediately.
7. **Pull-to-Refresh on Empty States**:
   - Created `ScrollableStateRegion` (`CustomScrollView` + `AlwaysScrollableScrollPhysics` + `SliverFillRemaining`) to allow `RefreshIndicator` triggers on empty/error states.
8. **Interactive Accessibility**:
   - Guaranteed 48dp touch targets on `SectionHeader` actions, `SelectionTile`, `SearchField`, and `SegmentedControl`.
   - Added explicit `Semantics(selected: ..., button: true)` to selection components.
9. **Widgetbook Font Packaging**:
   - Fonts declared and bundled in `app/widgetbook/pubspec.yaml`; release web compilation verified.
10. **Type-Safe Icon APIs**:
    - Changed `dynamic icon` to `final Widget icon` (or `Widget?`) with type-safe `.fromIconData(...)` convenience constructors across `ActionIconButton`, `EmptyState`, and `ErrorState`.
11. **Semantic Typography**:
    - Centralized all typographic rendering through `context.textTokens` and `context.textTheme`.
12. **Semantic Status Colors**:
    - Introduced `StatusColors` `ThemeExtension` with lerp/copyWith for `live`, `success`, `warning`, `cream`, `neutral`, and `championGround`.
13. **Information Fidelity**:
    - Restored `'SEE ALL $total MATCHES'` counter in `MyMatchesScreen`.

