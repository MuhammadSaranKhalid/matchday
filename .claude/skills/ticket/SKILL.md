---
name: ticket
description: >-
  Manage GitHub tickets and branches for this personal repo (matchday) — the full
  issue → branch → PR loop, with a guard that refuses to act under the wrong gh
  account. Use when the user wants to open/file a ticket or issue, start work on an
  issue, cut a feature branch, or open a pull request that closes an issue.
---

# /ticket — issue → branch → PR for the matchday repo

This repo is **personal** (`MuhammadSaranKhalid/matchday`), but the machine also
has a **work** GitHub account (`sarankhalid`). `git` picks the right identity from
the SSH host, but **`gh` uses whichever account is active**, so every action here
goes through `scripts/ticket.sh`, which **guards** against acting as the wrong
account before it touches anything.

All work runs the helper from the repo root:

```bash
.claude/skills/ticket/scripts/ticket.sh <subcommand> [args]
```

## Prerequisites (one-time — see SETUP.md, or docs/github-accounts.md + docs/workflow.md)
- `direnv` installed + hooked into the shell, and `direnv allow` run in this repo,
  so `gh` auto-uses the personal account here (via `.envrc`).
- The personal token has the `project` scope (`gh auth refresh -s project --user MuhammadSaranKhalid --hostname github.com`).
- Labels + board created once: `ticket.sh init --project <N>` (or `--create`).

If a command fails with *"active gh account … cannot access …"*, the guard caught a
wrong-account situation: tell the user to `cd` out and back in (reloads direnv) or
run `gh auth switch --user MuhammadSaranKhalid`. **Never bypass the guard.**

## How to handle each request

**Always run `guard` (or any real subcommand, which guards internally) first.** If it
fails, surface the fix above and stop — do not fall back to raw `gh`.

### "Create a ticket / file an issue for X"
1. Pick a `--label` from `feat fix chore refactor docs test` (default `feat`). Infer
   from the user's words (a bug → `fix`, tooling → `chore`, etc.); ask only if unclear.
2. Write a crisp title and a short body (what + acceptance criteria).
3. Run:
   ```bash
   .claude/skills/ticket/scripts/ticket.sh new "<title>" --label <type> --body "<body>"
   ```
4. Report the issue URL. If they want to begin immediately, continue to **start**.

**Defaults baked in (overridable per call):**
- `--assignee @me` — every ticket is assigned to you.
- `--priority P2` — default Priority on the project board (P0|P1|P2 allowed).
- `--size M` — default Size (XS|S|M|L|XL allowed).

**Optional flags (left blank unless passed):**
- `--estimate <number>` — Estimate field (planning-time decision; usually leave blank).
- `--start YYYY-MM-DD` — Start date.
- `--target YYYY-MM-DD` — Target date.
- `--milestone "<name>"` — GitHub milestone (set on the issue).

When you have **strong signal** about priority or size from the user's words (e.g.
"urgent" → `--priority P0`, "small tweak" → `--size XS`, "big refactor" → `--size L`),
pass the flag. Otherwise let the defaults stand — the user can adjust in the UI.

### "Start working on issue #N" / "make a branch for #N"
```bash
.claude/skills/ticket/scripts/ticket.sh start <N>
```
This derives the type from the issue's label, cuts `type/<N>-<slug>` off the latest
`main`, pushes it, and **flips the board card to `In progress`**. Pass `--type fix`
to override the branch prefix. Then do the work.

### "Open a PR" / "I'm done with this branch"
From the feature branch:
```bash
.claude/skills/ticket/scripts/ticket.sh pr
```
The PR title comes from the linked issue and the body is `Closes #N` (parsed from the
branch name), so merging auto-closes the ticket. The board card is **flipped to
`In review`** at the same time. On merge, board automation flips it to `Done`.
Add `--draft` for a draft PR. Prefer **squash-merge** into `main` to keep history
linear.

### "What account/board am I on?"
```bash
.claude/skills/ticket/scripts/ticket.sh whoami
```

## Conventions this skill keeps in lockstep
- **Types**: `feat fix chore refactor docs test` — same vocabulary for the issue
  label, the branch prefix, and the Conventional-Commit type.
- **Branch**: `type/<issue#>-<kebab-title>` (e.g. `feat/42-live-scoring`).
- **PR body**: `Closes #<issue#>` so the board's built-in *"item closed → Done"*
  workflow moves the card on merge.
- **Status lifecycle (script-driven)**: `Backlog` (board auto-add) → `In progress`
  (on `start`) → `In review` (on `pr`) → `Done` (board automation on merge).
- **Defaults on `new`**: `Assignee=@me`, `Priority=P2`, `Size=M`. Override with
  flags. Estimate, dates, milestone, relationships stay blank unless flagged
  (or set later in the UI).
- **Board automation**: prefer GitHub Projects' built-in workflows (auto-add items,
  closed → Done) over scripting status columns. Enable them once in the board's UI.
