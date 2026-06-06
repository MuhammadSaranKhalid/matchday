# Workflow — Tickets, Branches & PRs

Companion to `../CLAUDE.md`. The simple, day-to-day flow for working on matchday. For how
the two GitHub accounts on this machine are wired (SSH + gh + direnv), see
[`github-accounts.md`](github-accounts.md).

---

## The one rule

Every change is one chain:

> **issue → branch → pull request**

You file a ticket, cut a branch from it, and open a PR that closes it. Nothing goes
straight to `main`.

---

## Daily use (just ask Claude)

The `/ticket` skill does the steps for you. Say it in plain English:

| You say | What happens |
|---|---|
| "open a ticket for live scoring" | a labelled issue is created and added to the board |
| "start issue 5" | branch `feat/5-live-scoring` is cut from `main`, pushed, checked out |
| "open a PR" | a PR is opened with `Closes #5`; squash-merging it closes the ticket |

Prefer to run it yourself? From the repo root:

```
.claude/skills/ticket/scripts/ticket.sh new "Add live scoring" --label feat
.claude/skills/ticket/scripts/ticket.sh start 5
.claude/skills/ticket/scripts/ticket.sh pr
```

Handy checks:

```
.claude/skills/ticket/scripts/ticket.sh whoami    # account, repo, board
.claude/skills/ticket/scripts/ticket.sh guard     # am I on the right account?
```

---

## Naming (one word, everywhere)

The same type word is used for the **issue label**, the **branch prefix**, and the
**commit message** — so everything lines up:

`feat` · `fix` · `chore` · `refactor` · `docs` · `test`

- **Branch:** `type/<issue#>-<short-title>` → `feat/5-live-scoring`
- **Commit:** `feat(scope): summary` ([Conventional Commits](https://www.conventionalcommits.org/))
- **PR body:** `Closes #5`

---

## Accounts, in one line

matchday is the **personal** account; direnv auto-selects the personal `gh` account
inside this repo, and the `/ticket` **guard refuses to act as the wrong account**. The
full picture is in [`github-accounts.md`](github-accounts.md).

If a command ever says *"wrong account for this repo"*:

```
cd .. && cd -                              # reload direnv
gh auth switch --user MuhammadSaranKhalid  # or force it
```

> ⚠️ This zsh doesn't treat `#` as an inline comment — never paste a command with a
> trailing `# ...`, or it becomes arguments (and `# ->` is read as a `>` redirect that
> creates junk files).

---

## First-time setup

Already done on this Mac. You only need it on a **new machine or a new personal repo** —
full steps are in [`github-accounts.md`](github-accounts.md). The matchday-specific last
step (run once) creates the labels and links the board (Project #2):

```
.claude/skills/ticket/scripts/ticket.sh init --project 2
```

The `.envrc` (loads the personal token) and `.ticket.conf` (the board number) are
gitignored — machine-local, never committed.