# Claude Code Subagents

This directory contains project-scoped subagents for Claude Code. Each `.md` file defines one specialist that Claude Code can delegate to.

These subagents are version-controlled. The team inherits them via `git clone` — no per-machine setup.

## Agents in this project

| Agent | Routes to it when... | Read-only? |
|---|---|---|
| `architecture-reviewer` | Code changed in `lib/` (any layer) | Yes |
| `match-engine-specialist` | ANY change touching ball-by-ball scoring — record-ball, scoring RPCs/SQL, balls/innings-state tables, undo, free-hits, formats | No |
| `feature-builder` | New feature requested ("add bookmarks", "build tournaments") | No |
| `db-reviewer` | New migration in `supabase/migrations/` or RLS/RPC/schema change proposed | Yes |
| `code-simplifier` | After a feature works and passes review — reuse, dead code, over-abstraction | Yes |
| `security-auditor` | Periodic / pre-release sweep — secrets, RLS coverage across all migrations, edge-fn auth, deps | Yes |
| `docs-keeper` | A decision was made or code merged — design-doc decision logs, CLAUDE.md, README upkeep | Docs only |
| `test-writer` | After a feature is built, or when coverage is requested | No |
| `riverpod-specialist` | Provider DI questions, controller design, ref misuse bugs | No |
| `supabase-specialist` | RLS policies, auth flows, real-time, schema design | No |
| `drift-specialist` | ⚠️ LEGACY — app is online-only since 2026-05-26; drift survives only for WizardDrafts + the messages read-through cache. Use only for those. | No |
| `version-auditor` | Periodic dependency maintenance (NOTE: drift pinned 2.31, riverpod_lint/custom_lint disabled — do not "fix") | Mostly |

> **2026-06-12:** `feature-builder`, `architecture-reviewer`, `riverpod-specialist`, `test-writer`, and `supabase-specialist` have all been updated for the current architecture (NO use-case layer per 2026-05-29 amendment; ONLINE-ONLY per 2026-05-26). Project skills live in `.claude/skills/` (`ticket`, `supabase-migration`, `design-port`, `geo-discovery`, `pre-flight-qa`, `edge-functions`, `release-readiness`, `push-notifications`).
>
> **Deterministic enforcement** (beyond agents): `.claude/settings.json` has a PostToolUse hook that greps for framework imports in domain layers after every edit, and `test/architecture_test.dart` (dart_arch_test) encodes the layer rules as CI-runnable tests with a frozen cross-feature baseline.

## How Claude Code uses these

- **Automatic delegation**: when you ask Claude Code something that matches an agent's `description`, it routes to that agent. The `description` field is the matching signal — that's why each agent's description starts with "Use proactively when..." or "Use when...".
- **Explicit invocation**: type `@architecture-reviewer review my changes` or use natural language ("ask the test-writer subagent to add tests for the auth feature").
- **Session-wide override**: `claude --agent feature-builder` runs the whole session as that agent.

## Why this structure

Each agent has a **fresh context window** when spawned. They read CLAUDE.md and BEST_PRACTICES.md at startup but don't see the parent conversation. This means:

1. Each agent's system prompt must be self-contained — it can't rely on conversation history.
2. Agents can run in parallel without polluting each other's context.
3. The main session stays focused; verbose work (like running tests across the codebase) happens in the agent's isolated context.

Subagents **cannot spawn other subagents**. They're single-level. The main session orchestrates between them.

## Adding a new agent

1. Create `.claude/agents/<name>.md`
2. YAML frontmatter with at minimum `name` and `description`. Optional: `tools`, `model`, `color`.
3. System prompt in the markdown body — self-contained, references CLAUDE.md and BEST_PRACTICES.md as needed.
4. Restart Claude Code (or use `/agents` to reload).
5. Commit to version control.

## Editing existing agents

Edit the markdown file directly. Changes take effect on next session start.

Conventions for keeping these agents healthy:
- Keep each agent **focused on one job**. If you're tempted to add a second responsibility, create a second agent.
- The `description` is the routing signal — keep it specific. "Use proactively when X" routes better than "Helps with various things."
- For read-only agents (reviewers, auditors), restrict `tools` to `Read, Grep, Glob, Bash`.
- For builders, give full tool access but document non-goals clearly in the body.

## Testing changes

After editing an agent:
1. Reload via `/agents` in Claude Code.
2. Invoke explicitly with `@<agent-name>` to verify the new behavior.
3. Watch the agent's output for hallucinated tools or wrong paths — these indicate the system prompt needs tightening.

## Costs

Each subagent has its own context window, which means subagent-heavy workflows can use ~2-7x the tokens of a single-thread session. The trade-off is worth it for:
- Heavy-context tasks (running tests across the codebase, exploring many files)
- Parallel exploration (multiple agents searching different modules simultaneously)
- Specialization where focus matters more than breadth (the architecture-reviewer's narrow focus catches things a general session would miss)

Don't delegate trivial work to a subagent — the overhead exceeds the benefit.
