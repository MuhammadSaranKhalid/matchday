---
name: design-port
description: Port screens from the design prototypes (design/app/screens/*.jsx, especially v2-IA.jsx) into Flutter, or build any new screen/widget in this app's visual language. Use whenever creating or restyling UI - screens, headers, cards, chips, empty states, nav elements.
---

# Building UI in the MatchDay visual language

## The kit (use it, don't bypass it)
- Atoms live in `lib/core/widgets/v2/v2_kit.dart`: `V2Header` (title + bell + own-profile avatar), `V2BottomNav`, `V2Svg` + `V2Icons`, `Avatar`, `Crest`, plus `ck_shimmer.dart` and `v2_modals.dart`.
- Tokens ONLY from `lib/core/theme/circk_theme.dart`: `CkColors` (paper, paper2, ink, ink2, muted, soft, hairline, red, redSoft, cream, amber...), `CkType.display/body/mono`, `CkCrest`. Never ad-hoc `Color(0x...)` except documented oklch->sRGB conversions (comment the original oklch value, see profile_screen.dart precedent).
- Fonts are bundled Inter / Inter Tight / JetBrains Mono via CkType - never google_fonts.

## Screen scaffold pattern (every tab-level screen)
ColoredBox(color: CkColors.paper) > SafeArea(bottom: false) > Column [ V2Header(title, onBell), ...content ]. Full-screen pushed screens add their own compact nav/back affordance (see profile's `_CompactNav`).

## Porting from JSX prototypes
1. Read the relevant component in `design/app/screens/v2-IA.jsx` fully before writing Flutter.
2. Port FAITHFULLY: spacing, font sizes, letter-spacing, radii, and casing (mono labels are UPPERCASE with letterSpacing ~0.10) are part of the design - copy the numbers, don't approximate.
3. oklch colors: convert to approx sRGB, keep the oklch original in a comment.
4. Build presentation-only first with realistic mock data (project convention for unwired screens); wire providers in a later pass.

## Conventions
- Stateless content -> ConsumerWidget; forms/controllers -> ConsumerStatefulWidget.
- Private widgets (`_FooCard`) in the same file until reused across screens.
- Cards: `BoxDecoration(color: CkColors.paper, borderRadius: 14, border: hairline)`.
- Mono meta rows (KIND - when), filter chips, and skeleton shimmer placeholders all have precedents in profile_screen.dart / home feed - copy those, don't reinvent.
- Nav/IA facts: 5 tabs Home - Search - Matches - Messages - Pavilion (D9, docs/search-feature-design.md); own profile opens from the V2Header avatar; bell pushes Notifications via root navigator.
- Loading: CkShimmer skeletons shaped like the real content, never spinners.

## Checks before done
`flutter analyze` clean; screen works on a ~380px-wide viewport; no hardcoded colors/fonts outside the token system.
