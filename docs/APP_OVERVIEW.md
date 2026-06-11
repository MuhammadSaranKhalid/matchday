# matchday — Product Overview

> **What this doc is:** a plain-English picture of the matchday app today — what it is, who it's for, what works, what doesn't, and where it's headed. No code, no architecture. Share with a PM, a designer, an investor, or a new Claude session.
> **Snapshot date:** 2026-06-11.

---

## 1. What matchday is

**matchday** is a mobile app for amateur and grassroots **cricket** — the people who actually run village teams, friendly fixtures, weekend tournaments, and the social life around them. It is one Flutter binary that ships to **Android and iOS** (no web, no desktop).

The product idea, in one line: **the cricket layer that sits between WhatsApp groups and pro-level scoring apps.** Friendly enough for a village captain to set up a Sunday match in two minutes; serious enough that the scoring is ball-by-ball, the result is enforced server-side, and the stats stick to the player's profile forever.

### The shape of the app

When you open matchday you land in a five-tab bottom navigation:

| Tab | What's there |
|---|---|
| **Home** | The feed — posts from people you follow and from teams you're in. Photos, text, soon: likes / comments / bookmarks. |
| **Matches** | Discover live and upcoming matches — your own and the wider network's. Spectator-friendly. |
| **Pavilion** | Your private workspace. Lanes for **Matches · Teams · Tournaments**, a calendar, and the entry points to set things up. |
| **Messages** | 1-to-1 chats and team chats. Realtime delivery, unread counts, drafts that survive killing the app. |
| **You** | Your profile — bio, city, player profile, post grid, follow counts. Edit + share buttons. |

A bell in the header on every tab opens your notifications inbox. Push notifications wake you for match events, follows, comments, likes, new messages, and challenge updates.

### Design language

matchday has its own visual identity: **warm paper background, deep ink type, one earned red accent, the Seam ball mark.** Typography is Inter / Inter Tight / JetBrains Mono — bundled, never loaded from the web. The whole feel is "cricket annual" — like the pages of a Wisden, not like a fintech dashboard.

---

## 2. Who it's for

- **Captains and managers** running clubs, school sides, university teams, or weekend friendlies. They set the team up, invite players, send challenges to other teams.
- **Players** who want a single feed and a single profile that travels with them between teams.
- **Spectators** — family, friends, and the wider cricket community — who want to watch a live scorecard or scroll the feed.

It's not aimed at the pro league or the professional scorer market. The scoring engine is rigorous (server-enforced, all formats), but the UX above it is built for amateur captains, not statisticians.

---

## 3. What you can do in the app today

Everything in this section is **wired to real backend data** unless it says otherwise. "Mocked" means the screen renders the design but the data isn't persisted yet.

### 3.1 Sign in and set up your profile

- Sign in with **email OTP** (we email you a 6-digit code) or **native Google** (the OS sign-in sheet, not a browser).
- First-run **onboarding wizard**: pick a display name, claim a `@username`, set your city (with Google Places autocomplete + GPS fallback for villages with no map entry), and add an optional **player profile** (batting style, bowling style, playing role).
- The wizard remembers half-filled forms — kill the app, come back, pick up where you left off.

### 3.2 Build and manage a team

- Create a team with name, type, colours, founded year, home ground, tagline, and a logo (upload an image, we store it server-side).
- Add players two ways:
  - **By invitation** — they sign up and join via a team invite (schema exists; invite UI flow ships next).
  - **As unclaimed players** — type a player's name and skill profile so you can field them in matches before they're on matchday. They can claim their record later via a request flow.
- Assign **jersey numbers** (unique per team, validated server-side).
- Set a **captain** (one per team — promoting demotes the current).
- A live **team page** shows squad, role tags, and team metadata.

### 3.3 Challenge another team to a friendly

- **Send a match challenge** from your team to another. Pick a proposed format, time, venue, and your XI for the match. Generates a 6-digit **share code** so the other captain can find your challenge in person.
- The receiver can **accept**, **counter** (propose a different time / venue / format), **decline**, or — if it's the sender — **withdraw**. Acceptance turns the challenge into a real match row with both lineups.
- Challenges expire automatically (24h on the share code, 48h on the proposal).

### 3.4 Run a match — lifecycle

A match moves through **toss → lineup → live → completed**:

1. **Toss** — the host captain records who won and what they chose (bat / field).
2. **Lineup** — the batting captain picks the opening pair from their XI.
3. **Live** — the batting team's captain taps "Start" and the match goes live.
4. **Live scoring** — ball-by-ball entry from the **scoring console** (most polished single screen in the app today).
5. **Innings break** — between the two innings, the chase target is set.
6. **Result** — server computes who won, by how much, and writes the result.

### 3.5 Score a match

The scoring console (`ScoringScreen`) lets the batting team's captain enter every delivery: runs, wides, no-balls, byes, leg-byes, wickets (with the dismissal kind and the fielder). On every ball the **server-side engine**:

- Locks the innings row (so two scorers on the same match can't desync).
- Computes the new state with a pure scoring engine that knows every format.
- Inserts the ball, updates the live totals, advances the on-field trio (strike rotation, end-of-over swap), and broadcasts the new state to every connected device in real time.
- If the innings ended, transitions the match; if the chase ended, computes the result.

**Status today:** innings 1 and the transition to innings 2 are fully wired. Innings 2 → completion is **server-side complete**, but the client handoff (after the innings break) is the next milestone to polish.

### 3.6 Post and read posts

- **Feed:** posts from accounts you follow, newest first, with photos and BlurHash placeholders so the layout never jumps. Pull to refresh; infinite scroll.
- **Composer:** type a post, attach up to 4 photos. The photos go through a **device-side pipeline** — pick → crop (with ratio presets) → resize to ≤1080px long edge → JPEG q75 → compute a BlurHash. The end result is one file per image, so the feed is fast even on poor networks.
- **Engagement (likes, comments, bookmarks):** the schema is in place server-side, but the UI is currently mocked (the heart and comment icons render counts but don't persist yet). This is on the near-term roadmap.

### 3.7 Follow people

- Follow / unfollow other users from their profile or a team page.
- **Followers / following lists** — paginated, with each row tagged "FOLLOWS YOU" if relevant and a tri-state button (Follow / Follow back / Following).
- Follow counts appear on the profile and update live.

### 3.8 Message someone or a team

- **Inbox** — all your conversations sorted by latest message, with unread badges (capped at "99+").
- **1-to-1 chats** between users; **team chats** that are created automatically when a team is created. Adding a player to a team auto-adds them to the team chat.
- **Threads** load the latest 50 messages instantly (from a local cache for cold-start speed), then realtime delivery for every new message.
- **Scroll up** to load older history (50 at a time).
- **Drafts** — anything you've typed in a thread is saved locally per chat, so killing and reopening the app doesn't lose your half-typed message.
- **Read receipts** — the unread count clears when you open a thread; the other side sees the read time.

### 3.9 Notifications

- A **bell** in the header on every primary tab opens the notifications inbox.
- You receive notifications for: new follower, comment on your post, like on your post, new chat message, new match challenge, challenge accepted / declined / countered, match starting, match ended.
- All notifications are delivered as **push notifications** via Firebase Cloud Messaging when the app is in the background or terminated. When the app is open, they appear as a heads-up.
- Notifications are realtime (broadcast channel) so the bell badge updates without a refresh.

### 3.10 Share your profile

- A **share** button on the profile opens the OS share sheet with a link like `https://joinmatchday.com/u/<username>`.
- That link, in the app, opens the public profile screen.
- (Long-term: the link also opens the app from outside via App Links / Universal Links — Android and iOS configuration is in the binary; the verification files need to be hosted on the matchday.com domain before the link auto-opens the app instead of a browser.)

### 3.11 Browse without context

- The Matches tab is **spectator-friendly** — anyone signed in can browse live and recent matches, not just their own. (The "my matches" view in Pavilion is filtered to your participation.)

---

## 4. What's not yet built

The schema or backend logic for many of these is in place — they're "shovel-ready" — but the user-facing surface isn't done.

- **Likes, comments, bookmarks** on posts (UI mocked, schema ready).
- **Post drafts**, **scheduling**, and **visibility sheet** (private / followers / public).
- **Tournament authoring UI** — server side has tournaments, brackets, round-robin / knockout fixturing, standings recalculation, all done. There's no Flutter screen to set a tournament up yet.
- **Team posts and tournament posts** authoring — schema supports author context (personal / team manager / tournament organizer); composer only ships personal posts today.
- **Challenge counter** flow on the receiver side — temporarily disabled in v1 (sender must accept or decline a counter; the screen exists, the route is commented out).
- **Profile follow / message buttons** on a public `/u/<username>` profile — placeholders.
- **Live cards** rail and **feed filter chips** on Home — hidden behind feature flags until the underlying data is wired.
- **Innings-2 → result** client polish — server is complete; UI handoff after the innings break is the next big milestone.
- **iOS push** — Firebase project and Android side are ready; iOS still needs the Push Notifications capability + APNs key added in Xcode before tokens issue.
- **App-link verification files** hosted at `joinmatchday.com/.well-known/assetlinks.json` and `.../apple-app-site-association`. Until they're hosted, sharing a profile link works but opens the browser instead of the app.

---

## 5. How the architecture works (the 3-minute version)

For a stakeholder context — the engineering decisions behind the app.

- **Flutter** for the app — one codebase, Android + iOS, native UI.
- **Supabase** for the backend — Postgres database, authentication, file storage, realtime broadcast channels, and server-side **edge functions** for the heavy logic.
- **Server is the source of truth.** Scoring, challenge handshakes, push notifications, follow lists — all server-enforced. The client renders state; it never tries to compute it.
- **Online-only.** With one exception (the messages inbox + threads use a local cache for cold-start speed), every read and write talks to Supabase directly. No background sync, no "did it save?" ambiguity.
- **Realtime** — match score, chat messages, notifications, team rosters all update live across devices via Supabase broadcast channels.
- **Push notifications** via Firebase. The Supabase database triggers the FCM dispatcher whenever a notification row is created.

### The team behind matchday's tech

The codebase is structured under **Clean Architecture** — Domain, Data, Presentation layers — so any one piece can be reasoned about without reading the others. There's a written agent contract (`CLAUDE.md`) so Claude Code (and human reviewers) catch architectural drift early.

---

## 6. State of the codebase (high-level metrics)

- **Features fully wired:** auth, onboarding, teams, matches (through innings 1), messages, notifications, follows, posts, location, profile.
- **Features rendered as composition only:** home, pavilion, profile, shell — these don't have their own backend; they aggregate other features.
- **Supabase tables:** 29.
- **Supabase migrations:** 50+.
- **Edge functions:** 6 (`record-ball`, `list-my-matches`, `list-my-chats`, `list-follow-list`, `send-match-request`, `send-push`).
- **Test footprint:** ~880 LOC, ~9 files. Skew is controller + entity tests; matches/posts/messages coverage thinner. Server-side scoring engine has its own Deno tests.
- **Recent activity:** the messages feature has been heavily refined in the past month (#5–#48); follows came in last (#49/#51/#53); deep-link profile route #53; team_members `added_by` strict nullability fix in flight.

---

## 7. What's distinctive about matchday

Three things mark the product apart from "we're building yet another sports app":

1. **The scoring engine is server-authoritative and shared between formats.** A pure TypeScript engine runs every delivery through a row-locked Postgres transaction; the client only renders. This makes the data trustworthy and the format catalog (T20, ODI, custom overs/players/innings) a configuration file, not a fork of the codebase.
2. **The visual identity is deliberate and unapologetic.** Warm paper, single earned red, Seam ball mark, three carefully chosen variable fonts. The whole app feels like a cricket annual, not a generic UI kit. Brand sheet and design tokens are part of the codebase, not a Figma afterthought.
3. **Online-first, ruthlessly.** Many apps in this space try to be offline-first and fail at sync edges. matchday made a deliberate choice in early 2026 to remove the offline-first stack and accept the constraint. The one exemption (messages cache) is scoped, named, and reviewed. The result is faster engineering iteration and zero "why did it sync wrong" bugs.

---

## 8. Quick numbers

- Platforms: **Android + iOS** (mobile only).
- Domain: `joinmatchday.com`.
- Firebase project: `matchday-44ed4`. Android app id: `com.matchday.app`.
- Brand: warm paper `#FBFAF6`, ink `#29251E`, cricket red `#DC4D32`, seam cream `#F4ECDD`.
- Fonts: Inter, Inter Tight, JetBrains Mono (variable, bundled).
- License / Repo visibility: private (personal repo on a personal GitHub account).
- Stack short form: **Flutter + Riverpod 3.x + Supabase + Firebase + Drift (scoped) + Google Places + go_router.**

---

## 9. A note on the audience for this document

If you're a designer or product person, jump to §3 for what works and §4 for what doesn't.
If you're an investor or stakeholder, §1, §7, and §6 are the briefing.
If you're an engineer joining the team, read this document for context and then go straight to `docs/APP_TECHNICAL.md` — the engineer-level handoff — and `CLAUDE.md`, the architectural contract.
