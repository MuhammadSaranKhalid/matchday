# Why Phase 3A does not rewrite old migration history

Now that production has begun receiving forward migrations, do **not** solve
the physical split by deleting columns from the old `20260101000400_matches`,
`0401_match_players`, or `0402_match_teams` files in isolation.

Those historical migrations are referenced by later historical functions such
as the old match helpers, tournament live-ops functions, and old
`list_my_matches`. Removing the columns at the beginning of the chain while
leaving those later historical migrations unchanged makes a fresh reset fail
*before* it reaches the Phase 2/3 migrations that replace them.

The safe sequence is:

```text
historical migrations
        ↓
Phase 1 extensions
        ↓
Phase 2A callers
        ↓
Phase 2B remaining callers + mirror removal
        ↓
Phase 3A physical legacy-column drop
```

A fresh reset still ends in the correct final schema.

If you later want a shorter migration history, do that as a dedicated
**baseline/squash operation** after Phase 3 is fully verified. At that point
the old match migrations can be replaced as one coherent set rather than
partially edited.

This is especially important now because production has migration history:
rewriting already-applied migration files changes Git history but does not
change the already-deployed database.
