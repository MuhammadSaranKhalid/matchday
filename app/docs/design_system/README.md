# Matchday Design System

Welcome to the Matchday Design System. This directory documents the UI architecture, foundations, component contracts, and migration guide for Matchday.

---

## Quick Reference & Decision Guide

### 1. Where should I put a new widget?
- **Generic UI Primitives & Patterns**: Put them in `lib/core/design_system/` under `primitives/`, `patterns/`, `navigation/`, or `layout/`.
- **Cricket / Social Domain Components**: Put them in their respective feature directory (e.g., `lib/features/matches/presentation/widgets/fixture_card.dart` or `lib/features/tournaments/presentation/widgets/ck_tournament_card.dart`). Domain widgets compose design system surfaces and primitives.

### 2. Should this component be design-system or feature-specific?
- **Design System**: Buttons, badges, chips, text fields, empty states, error states, headers, sheets, dialogs, surfaces. Contains NO cricket-specific rules or domain models.
- **Feature Component**: Scoreboard, ball keypad, tournament bracket, fixture card, team crest, chat bubble, post card. Owns business information architecture.

### 3. Naming Rule
> **Component names describe responsibility and semantics. They do not contain project abbreviations (`Ck`, `MD`, `Matchday`, `V2`).**
> Examples: `ActionButton`, `ActionIconButton`, `Surface`, `StatusBadge`, `SelectionChip`, `EmptyState`, `TextInput`, `SearchField`, `AppBottomSheet`, `ScreenLayout`.

### 4. When may I introduce a new token?
- Foundation tokens (`Palette`, `Spacing`, `Radii`, `Sizing`, `Motion`) are immutable contracts.
- Only introduce a new token if an app-wide brand or layout change is architecturally reviewed and approved.
- Never add ad-hoc, one-off colors or random font sizes in feature widgets.

### 5. How do I access theme values in UI?
```dart
// Standard layout tokens
context.layout.screenGutter
context.layout.sectionGap
context.layout.cardPadding

// Text styling
context.theme.textTheme.titleMedium
context.theme.textTheme.bodyMedium

// Cricket metadata & mono typography
context.textTokens.metadata
context.textTokens.score
context.textTokens.metric
```

### 6. How do I deprecate a component?
Annotate the legacy widget or function with `@Deprecated('Use NewComponent instead')`. Provide a backward-compatible wrapper or forwarding facade during the migration phase until all call sites are migrated.
