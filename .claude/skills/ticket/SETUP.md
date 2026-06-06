# /ticket — setup checklist

> Full explanation + from-scratch steps live in the repo docs:
> `../../../docs/github-accounts.md` (the two-account setup) and
> `../../../docs/workflow.md` (the issue→branch→PR flow). This file is just the
> quick checklist.

This repo (`matchday`) is **personal** (`MuhammadSaranKhalid`); the machine also has a
**work** account (`sarankhalid`). `git` already picks personal here via the SSH host;
`gh` follows the active token, so direnv loads the personal token inside this repo.

## One-time, in order
1. **direnv installed + hooked** — `brew install direnv`, then `eval "$(direnv hook zsh)"`
   in `~/.zshrc`.
2. **Personal token has the `project` scope** (browser; `gh auth refresh` has no `--user`
   flag and ignores `GH_TOKEN`):
   ```
   unset GH_TOKEN
   gh auth switch --user MuhammadSaranKhalid
   gh auth refresh -s project --hostname github.com
   gh auth switch --user sarankhalid
   ```
3. **Trust direnv** in the repo: `direnv allow` (then `direnv reload` to pick up the token).
4. **Labels + board** (matchday's board is Project #2):
   ```
   .claude/skills/ticket/scripts/ticket.sh init --project 2
   ```

## If a command says "wrong account for this repo"
The guard caught it. Reload direnv (`cd .. && cd -`) or `gh auth switch --user MuhammadSaranKhalid`.
Verify with `gh api user --jq .login` → should be `MuhammadSaranKhalid` inside this repo.
