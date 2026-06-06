# GitHub Accounts (Personal + Work) on One Machine

Companion to `../CLAUDE.md`. This explains how this Mac runs **two GitHub accounts side
by side**, how the right one is picked automatically, and how to set the same thing up
on a fresh machine. The day-to-day ticket/branch/PR flow lives in
[`workflow.md`](workflow.md).

---

## The accounts

| | Account | SSH host | SSH key | gh CLI |
|---|---|---|---|---|
| **Personal** | `MuhammadSaranKhalid` | `github.com` | `~/.ssh/id_ed25519_personal` | logged in |
| **Work** | `sarankhalid` | `github-work` | `~/.ssh/id_ed25519_work` | logged in |

**matchday is personal** — its remote is `git@github.com:MuhammadSaranKhalid/matchday.git`.

---

## The mental model (read this once)

"Which account am I?" is answered by **two independent systems** that don't talk to
each other:

| Action | Decided by | |
|---|---|---|
| `git` clone / push / pull | the **SSH host** in the remote URL | host → key → account |
| `gh` issues / PRs / boards | the **active `gh` token** | nothing to do with SSH |

That split is the whole reason multi-account feels confusing. We add **direnv** so the
`gh` side follows the folder you're in automatically.

> Both accounts live on `github.com`, so `gh` **cannot** tell them apart by host — it
> just uses whichever account is *active*. direnv makes "active" follow the repo.

---

## Part 1 — SSH (the `git` identity)

One key per account, told apart by a **host alias** in `~/.ssh/config`.

### How it's wired here (`~/.ssh/config`)
```
# Personal — the normal github.com
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

# Work — reached through the alias "github-work"
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

- A **personal** repo uses a normal remote: `git@github.com:you/repo.git`
- A **work** repo swaps the host for the alias: `git@github-work:org/repo.git`
  (Same real server — the alias only chooses which key to use.)

### Setting it up from scratch
```
ssh-keygen -t ed25519 -C "personal@email" -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C "work@email"     -f ~/.ssh/id_ed25519_work
```
Write the `~/.ssh/config` above, then add each **public** key (`.pub`) to the matching
GitHub account (Settings → SSH and GPG keys). Verify:
```
ssh -T git@github.com      ->  Hi MuhammadSaranKhalid
ssh -T git@github-work     ->  Hi sarankhalid
```

### Commits attributed to the right person
Global git identity is personal. Inside a **work** repo, override it once so commits
show the work identity:
```
git config user.name  "Your Work Name"
git config user.email "you@work.com"
```

---

## Part 2 — gh CLI (the issue / PR / board identity)

**Yes, `gh` holds several accounts at once.** Both are logged in on this machine.

### Adding a second account
Run login once per account (choose GitHub.com each time):
```
gh auth login          # run twice — once per account
gh auth status         # shows BOTH; one is marked "Active account: true"
```

### Switching the active account
```
gh auth switch                            # toggle between the two
gh auth switch --user MuhammadSaranKhalid # pick one explicitly
```

### The catch (this is the important bit)
`gh` only auto-detects the account when the accounts are on **different hosts** (e.g.
github.com vs a GitHub Enterprise server). Both of ours are on `github.com`, so `gh`
**can't guess** — it uses the active one. On a private repo the wrong account can't even
*see* it (`Could not resolve to a Repository`). Part 3 makes this automatic so you never
hit it.

### Scopes (needed for Projects boards)
A token carries scopes. Issues/PRs need `repo`; **Projects boards** also need `project`.
Add it to the personal token once. Note `gh auth refresh` has **no `--user` flag** (it
refreshes whichever account is *active*) and it **ignores `GH_TOKEN`**, so clear that
first:
```
unset GH_TOKEN
gh auth switch --user MuhammadSaranKhalid
gh auth refresh -s project --hostname github.com   # opens a browser
gh auth switch --user sarankhalid
```

---

## Part 3 — direnv (auto-pick `gh` per repo)

direnv runs a `.envrc` when you enter a folder and undoes it when you leave. We use it to
turn on the **personal** token only inside personal repos.

### Install
```
brew install direnv
```
Add this near the end of `~/.zshrc`, then restart the shell:
```
eval "$(direnv hook zsh)"
```

### The `.envrc` (one per personal repo — gitignored)
```
export GH_TOKEN="$(gh auth token --user MuhammadSaranKhalid --hostname github.com 2>/dev/null)"
```
It reads the personal token from gh's keyring **at entry time** (nothing secret is
written to disk) and exports it as `GH_TOKEN`, which `gh` always prefers. Leave the
folder → direnv unsets it → work repos fall back to the work account.

Approve it once per repo (and again after editing the file):
```
direnv allow
```

### Why this approach
- No global `gh auth switch` that leaks across terminals.
- Reverts automatically when you `cd` away.
- The token is never committed or stored in the repo.

---

## Checking / switching by hand

```
gh api user --jq .login        # who am I right now?
gh auth status                 # every account + its scopes
gh auth switch --user <name>   # force a specific account
cd .. && cd -                  # reload direnv for the current repo
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Could not resolve to a Repository` | work account active on a private personal repo | `cd .. && cd -`, or `gh auth switch --user MuhammadSaranKhalid` |
| `missing required scopes [read:project]` | personal token lacks `project` scope | the refresh in Part 2 |
| `gh auth refresh` seems to do nothing | `GH_TOKEN` is set (by direnv) | `unset GH_TOKEN` first, or run it outside the repo |
| junk files appear after pasting commands | this zsh treats `#` as text, and `# ->` as a `>` redirect | don't paste commands with a trailing `# comment` |
