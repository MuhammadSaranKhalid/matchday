# Design Brief — MatchDay Side Panel (App Drawer)

You are designing the **side navigation panel** for **MatchDay**, a mobile cricket app
(Flutter, iOS + Android, light theme only). The panel already exists and works — your job
is to **redesign it to a higher standard of craft within the app's existing visual
language**, and to fill the gaps in it that were specified but never built.

Deliver a pixel-annotated design I can port directly into Flutter. Do not invent a new
design system; this app has one, and it is given to you in full below.

---

## 1. The product, in one paragraph

MatchDay is where amateur/club cricketers organise and play. You create a team, add
players, challenge another team or post into an open "pool" of fixtures, then score the
match ball-by-ball on the phone. The app's bottom navigation holds **the world** (Home
feed, Explore, Matches, Pool). The side panel holds **you** — your matches, your teams,
your pool requests, and your account. That split is a decided architectural rule:

> **Bottom nav is the world. Side panel is you.**
> **The panel is nouns only. No verbs.** (You go to a place; the place knows how to create.)

Corollary you must respect: the panel does **not** get a "Create team / Post a request /
New match" section. Every destination already owns its own create button one tap deeper.
A create section in the panel would be a second door to the same buttons.

---

## 2. Brand & design tokens (authoritative — use these exact values)

The brand line is: **"One ink · one earned red · warm paper."** The surface is warm
off-white paper, text is a warm near-black, and there is exactly **one** accent — Cricket
Red — which is spent sparingly on live/destructive/active moments. Green and amber exist
**only** as functional status colours, never as decoration.

### Colours

| Token | Hex | Use |
|---|---|---|
| `ink` | `#29251E` | Primary text, primary icons |
| `ink2` | `#4A4339` | Secondary text, dialog body |
| `muted` | `#8A8170` | Tertiary text, meta, chevrons, disabled labels |
| `soft` | `#B9B1A2` | Inactive nav glyphs, placeholder text |
| `paper` | `#FBFAF6` | Panel background, page background |
| `paper2` | `#F3F0E9` | Recessed fills: avatar fallback, chips, buttons |
| `surface` | `#FFFFFF` | Elevated surfaces (bottom nav bar) |
| `line` | `#E6E2D9` | Borders on inputs / stronger separators |
| `hairline` | `#EEEBE3` | 1px dividers and card borders (the default) |
| `red` | `#DC4D32` | **Cricket Red** — LIVE, destructive, active tab |
| `redSoft` | `#F7E6E1` | Tint behind red text |
| `green` | `#338946` | Status only (won / confirmed) |
| `greenSoft` | `#CFEED2` | Status tint |
| `amber` | `#E6AC3D` | Status only (pending / awaiting) |
| `cream` | `#F4ECDD` | Seam Cream — amber-tinted chip background |
| `creamBorder` | `#DED0AC` | Border for cream chips |

Ink colours that sit **on** the soft tints: on `redSoft` use `#8C2218`; on `greenSoft` use
`#1E5A2C`; on `cream` use `#6B5414`.

Shadows (only two exist — do not invent more):
`shadow-1: 0 1px 2px rgba(40,30,15,.04), 0 1px 1px rgba(40,30,15,.03)`
`shadow-2: 0 8px 28px rgba(40,30,15,.07), 0 2px 6px rgba(40,30,15,.04)`

Radii: `sm 8` · `md 14` · `lg 20` · `xl 28` (px/dp).

### Typography — three bundled families, three roles

| Role | Family | Rules |
|---|---|---|
| **Display** | `Inter Tight` | Names, row labels, titles. Default weight 700. Letter-spacing is **-0.02em × font-size** (tighter as it grows). |
| **Body** | `Inter` | Sentences, buttons, subtitles. Default weight 400. |
| **Mono** | `JetBrains Mono` | Eyebrows/section labels (UPPERCASE), stat lines, tabular numbers, status pills. Default weight 600, letter-spacing **+0.14em × font-size** (about +0.10em for uppercase labels). |

Established sizes in this app: screen title `display 26` · row label `display 14.5/600` ·
dialog title `display 18/700` · body copy `body 13.5` · subtitle `body 11.5 muted` ·
mono eyebrow `mono 10/700, +0.10em, muted, UPPERCASE` · pill text `mono 9/700` ·
footer legal `mono 9`.

### Iconography

Two icon vocabularies coexist and you should design with the SVG one:
- **Inline SVG, 24 viewBox, stroked, `stroke-width: 1.8`, round caps/joins** — used across
  the app chrome (header, bottom nav). This is the house style.
- Material "rounded" icons — used inside the current drawer rows. Treat this as a legacy
  inconsistency you may resolve by moving to the stroked SVG set.

Existing glyphs available: home (house), search, matches (bat + ball), pool (radar /
crosshair), bell, messages (speech bubble), plus, chevron-left/right, heart, comment,
share, bookmark, check, pin, dots-vertical, close (×), camera, profile (bust), management
(2×2 grid of rounded squares), shield-with-star. If your design needs a glyph outside this
set, draw it in the same language (24 viewBox, 1.8 stroke, geometric, no fills) and hand
me the path data.

---

## 3. The chrome the panel lives inside (design to fit this)

- **Top header** (persistent, all four tabs): a 36×36 circular **management button** on the
  far left — `paper` fill, `hairline` 1px border, 2×2 grid glyph, 17px — then the screen
  title in `display 26`, then on the right two more 36×36 circular buttons (bell,
  messages), each with a red count badge (`red` fill, 1.5px `paper` border, min 15×15,
  `display 9/700` white, `9+` cap). Header padding is `18px` left/right, `6px` top,
  `12px` bottom.
- **The panel opens from the LEFT**, triggered by that management button, plus a ~20dp
  left-edge drag. Medium haptic on open.
- **Bottom nav** (4 tabs: Home · Explore · Matches · Pool): `surface` white bar,
  `hairline` top border, each item a 40×32 rounded tile (radius 11) that fills **red**
  when active with the glyph turning white at 21px; inactive glyph is `soft` at 23px;
  label `body 9.5`, active `w700 ink` / inactive `w600 muted`.
- The panel currently covers the header but sits **above** nothing else — it is a standard
  Material drawer with a scrim over the whole screen.

---

## 4. What exists today (the baseline you are redesigning)

Panel container: width = `86% of screen width, clamped 320–420`, `paper` background,
**square corners**, elevation 16, content inside a SafeArea, laid out top-to-bottom:

**A · Identity block** (tapping anywhere closes the panel and opens `/profile`)
- Padding `18 / 14 / 14 / 14` (L/T/R/B). Row layout, top-aligned.
- 48dp circular avatar — network image, or `paper2` fill + `hairline` border + two-letter
  monogram in `display 17.3/700`, colour `ink2`.
- 14px gap, then a column:
  - Display name — `display 17/700`, single line, ellipsis.
  - 2px gap. Subline `@username · All-rounder · Lahore` — `body 11.5 muted`, single line,
    ellipsis. Parts are joined by ` · ` and any missing part is dropped.
  - 4px gap. `12 Posts · 340 Followers` — `mono 10 muted`.
- 8px gap, then a 30×30 circular **close (×)** button — `paper2` fill, `hairline` border,
  17px `ink` glyph.
- 1px `hairline` divider under the whole block.

**B · Rows — section "YOURS"**
- List padded 12px vertically. Section label `YOURS` at padding `20 / 6 / 20 / 8`,
  `mono 10/700, +0.10em, muted`.
- Five rows, each **56dp tall**, 20px horizontal padding:
  `[icon 22] — 14px gap — [label, display 14.5/600] — [badge] — 6px — [chevron 18 muted]`
- Badge = pill, padding `7×3`, radius 5, background is the badge colour at **10% alpha**,
  text `9/700` in the badge colour. (Note: this text currently uses the *body* font, not
  mono — inconsistent with every other pill in the app. Fix it in your design.)
- Disabled rows: label + icon go `muted`, badge background `paper2`, chevron `muted @50%`.

| Row | Glyph today | Trailing state |
|---|---|---|
| My Matches | calendar-check | `LIVE NOW` (red) → `2 upcoming` (ink) → `3 pending` (amber). Precedence: live > upcoming > pending. Nothing at all when zero. |
| My Teams | shield outline | `3` (ink). Nothing when zero. |
| My Pool Requests | radar | `2 open` (ink). Nothing when zero. |
| My Tournaments | trophy outline | `Soon`, disabled — feature not built |
| My Clubs | building | `Soon`, disabled — feature not built |

**C · Footer**
- 1px `hairline` divider, then padding `16 / 14 / 16 / 16`.
- **Sign out** — full-width 44dp button, `paper2` fill, radius 10, `hairline` border,
  centred: logout glyph 17 in `red` + 8px + `body 13.5/600` in `red`.
- 12px gap, then `MATCHDAY · v2.0` in `mono 9 muted`, centred.
- Sign-out opens a confirm dialog: `paper` background, radius 16, title `display 18/700`
  "Sign out", body `body 13.5 ink2` "Are you sure you want to sign out of Matchday?",
  actions `Cancel` (`body 13 muted`) and `Sign out` (`body 13/700 red`).

---

## 5. Problems to solve (this is the actual brief)

1. **The footer is a stub.** The IA spec called for `Saved · Settings · Help` above Sign
   out. None of it shipped, and **the app has no Settings screen at all** — no notification
   preferences, no privacy, no blocked users, no account deletion, no legal links. That is
   both a UX hole and an app-store compliance risk. Design the panel's account/footer zone
   properly, and tell me which entries are real destinations vs. roadmap. (Saved/bookmarks
   exists only as mock UI today; Help does not exist.)
2. **First run is a dead panel.** A brand-new user has no matches, no teams, no pool
   requests, so all five rows render with a bare right edge and two greyed "Soon" rows. It
   reads as broken. Design a first-run/empty treatment that stays inside the *nouns-only*
   rule — do not solve it by adding create buttons.
3. **There are no loading states.** While data resolves, the name falls back to the literal
   string "Your profile", counts read 0, and badges are absent. The app's convention is
   **shimmer skeletons shaped like the real content — never spinners**. Design the skeleton.
4. **No sense of place.** The panel never indicates where you currently are, and every row
   looks equally weighted whether it holds a live match or nothing at all. A live match is
   the single most important state in this app and deserves more than a small red chip.
5. **Craft inconsistencies to resolve:** the badge font (body vs mono); Material rounded
   icons inside a panel whose app uses stroked SVG; square drawer corners with a heavy
   Material elevation 16 shadow that doesn't match the app's two shadow tokens; a 30dp
   close button that is under the 44dp minimum touch target.
6. **The identity block is doing less than it could.** Available and unused: cover image,
   bio, batting style, bowling style, years playing, following count, team crests, city
   coordinates. Consider whether any of it earns its place — but the block must remain
   compact; it is a doorway to the profile, not the profile.
7. **Long content breaks it.** Design for a 28-character display name, a
   `@a_very_long_username · Wicket-keeper · Muzaffargarh` subline, a `12 upcoming` badge,
   and 120% OS text scaling.

---

## 6. Data actually available (design only against this)

- **Identity:** display name, @username, avatar URL, cover URL, bio, city, player role
  (Batter / Bowler / All-rounder / Wicket-keeper), batting style, bowling style, years
  playing, post count, follower count, following count.
- **Rows:** count of my teams (plus each team's crest colour, monogram and logo); my
  matches split into confirmed / live / pending-request counts; count of my open pool
  requests.
- **Elsewhere in the chrome, and available to the panel if you want it:** unread
  notifications count, unread messages count.
- **Does not exist:** tournaments, clubs, saved items, settings, help, in-app support,
  theme switching, language switching, profile completion percentage. Anything you design
  from this list is a roadmap signpost, and must be visibly, honestly inert.

---

## 7. Constraints

- **Light theme only.** Do not design a dark mode or a theme toggle.
- **Flutter implementation.** Avoid backdrop blur, glassmorphism, gradient meshes, gradient
  text, multi-layer drop shadows, and anything that needs a CSS-only trick. Flat fills,
  1px hairlines, the two shadow tokens, and the radii scale are the whole toolbox.
- **One accent.** Red is earned — LIVE, destructive, active. If everything is red, nothing
  is. Green/amber only carry status meaning.
- **No new colours** unless you justify each one in a note and give me the hex.
- **Panel width stays 86% clamped 320–420**, and it stays a left-side drawer with a scrim.
- **Touch targets ≥ 44dp**; row height should stay in the 52–60dp band.
- **Nouns only, no verbs** — see §1. If you believe a specific verb must appear, argue it
  explicitly in a note rather than slipping it in.
- Bottom nav destinations (Home, Explore, Matches, Pool) must **not** be duplicated in the
  panel.

---

## 8. What to deliver

A **single self-contained HTML file** I can open in a browser, containing:

1. **Artboards at 390 × 844** (iPhone 14 viewport), each labelled, laid out side by side on
   a neutral canvas, showing the panel **in situ** over a dimmed app screen where relevant:
   - **A · Default** — populated account: 2 upcoming matches, 3 teams, 2 open pool requests.
   - **B · Live** — a match in progress (this is the hero state; make the panel feel it).
   - **C · First run** — brand-new user, everything empty.
   - **D · Loading** — the shimmer skeleton.
   - **E · Overflow** — longest plausible strings + 120% text scale.
   - **F · Footer / account zone** — expanded detail of Settings/Saved/Help/Sign out and
     the confirm dialog.
   - **G · Row anatomy** — one row blown up ~3× with every measurement redlined.
2. **A redline table** listing every element: size, weight, letter-spacing, colour token,
   padding, gap, radius, and opacity. I will type these numbers into Flutter verbatim, so
   give me numbers, not adjectives.
3. **Any new SVG glyphs** as raw path data on a 24 viewBox at 1.8 stroke.
4. **Motion notes**: panel open/close curve and duration, scrim opacity, row press state,
   skeleton shimmer timing, and what (if anything) animates when a match goes live.
5. **A short rationale** — at most one page: what you changed, why, and which of the seven
   problems in §5 each change addresses.
6. **Open questions** for me, if the brief left anything genuinely ambiguous.

Use CSS custom properties named exactly like the tokens in §2 (`--ink`, `--paper-2`,
`--red`, `--hairline`, `--r-md`, `--font-display`, …) so the mapping to Flutter is
mechanical. Load Inter, Inter Tight and JetBrains Mono from Google Fonts in the file.

Optional and welcome: if you see a genuinely stronger structure for the panel that still
obeys §1 and §7, show it as an **alternative artboard** beside your primary
recommendation, and say which one you'd ship.

---

## 9. Acceptance checklist

- [ ] Every colour is a token from §2, or a documented, justified addition.
- [ ] Every type style is Inter Tight / Inter / JetBrains Mono in its correct role, with
      the letter-spacing rules applied.
- [ ] Red appears only where it is earned.
- [ ] No verbs / create actions in the panel.
- [ ] No bottom-nav destination duplicated.
- [ ] Populated, live, empty, loading, and overflow states are all drawn.
- [ ] Unbuilt destinations are visibly inert and honest.
- [ ] All touch targets ≥ 44dp; row heights 52–60dp.
- [ ] Nothing in the design requires blur, gradients, or a shadow outside the two tokens.
- [ ] Every measurement I need is in the redline table.
