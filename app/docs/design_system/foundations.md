# Foundations

## Palette
Located at `lib/core/design_system/foundation/palette.dart`.

- **Ink ramp**: `Palette.ink` (#29251E), `Palette.ink2` (#4A4339), `Palette.muted` (#8A8170), `Palette.soft` (#B9B1A2).
- **Paper ramp**: `Palette.paper` (#FBFAF6), `Palette.paper2` (#F3F0E9), `Palette.surface` (#FFFFFF), `Palette.canvas` (#E5E0D6).
- **Hairlines**: `Palette.line` (#E6E2D9), `Palette.hairline` (#EEEBE3).
- **Accents**: `Palette.red` (#DC4D32), `Palette.cream` (#F4ECDD).
- **Status**:
  - Green: `Palette.green`, `Palette.greenInk`, `Palette.greenSurface`, `Palette.greenBorder`.
  - Amber: `Palette.amber`, `Palette.amberInk`, `Palette.creamBorder`.
- **Dark Ground**: `Palette.championGround` (#29251E), `Palette.championRaised`, `Palette.championHairline`, `Palette.championGold`.

## Spacing Scale
Located at `lib/core/design_system/foundation/spacing.dart`.

| Token | Value | Semantic Use |
|---|---|---|
| `Spacing.xxs` | 4.0 | Micro padding, indicator dots |
| `Spacing.xs` | 8.0 | Inline item gap, icon padding |
| `Spacing.sm` | 12.0 | Item gap, compact card padding |
| `Spacing.md` | 16.0 | Screen gutter, standard card padding |
| `Spacing.lg` | 20.0 | Comfortable card padding |
| `Spacing.xl` | 24.0 | Section gap, bottom gutter |
| `Spacing.xxl` | 32.0 | Major section gap |
| `Spacing.xxxl`| 40.0 | Modal spacing |
| `Spacing.huge`| 48.0 | Screen hero spacing |

## Radii Scale
Located at `lib/core/design_system/foundation/radii.dart`.

- `Radii.xs` (4.0): Sub-badges, micro tags.
- `Radii.sm` (8.0): Small elements.
- `Radii.md` / `Radii.control` / `Radii.card` (14.0): Standard controls, cards, input fields.
- `Radii.lg` / `Radii.modal` / `Radii.hero` (20.0): Bottom sheets, dialogs, hero cards.
- `Radii.xl` (28.0): Floating action pods.
- `Radii.pill` (999.0): Chips, pill badges.

## Sizing & Interaction Targets
Located at `lib/core/design_system/foundation/sizing.dart`.

- `Sizing.minimumTapTarget`: 48.0 (enforces accessible touch bounds regardless of visual compactness).
- `Sizing.controlCompactHeight`: 40.0 (visual height for dense UI like profile actions).
- `Sizing.controlHeight`: 48.0 (standard height).
- `Sizing.controlLargeHeight`: 52.0 (prominent CTA height).
