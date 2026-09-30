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
- [ ] **Phase 4**: Widgetbook nested package + golden/accessibility tests + drift tests.
- [ ] **Phase 5**: Migrate My Matches & My Tournaments.
- [ ] **Phase 6**: Migrate Messages (remove `ChatTheme`) & Profile.
- [ ] **Phase 7**: Migrate Teams, Explore, Notifications, Posts (decompose `v2_kit.dart`).
- [ ] **Phase 8**: Tournament & Match operational flows, scoring chrome.
- [ ] **Phase 9**: Delete legacy compatibility layers.
