# Deployment — Cricket Setup / Atomic Toss / RBAC Hard Cut

This is a coordinated database + Edge + Flutter cutover.

## 1. Superseded package

Do not deploy the earlier package that adds `matches.host_side`. This package supersedes it.

If that experiment was ever applied in a disposable development database, this migration contains cleanup logic to transfer a usable value into the Cricket child and then remove the generic field.

## 2. Create the migration with the CLI

```bash
supabase migration new cricket_setup_atomic_toss_rbac
```

Paste:

```text
migration/cricket_setup_atomic_toss_rbac.sql
```

into the generated migration file.

## 3. Test first in local/staging

Preferred:

```text
fresh reset
→ migration chain
→ new migration
→ verification SQL
```

Then run:

```text
migration/verify_cricket_setup_atomic_toss_rbac.sql
```

This package-generation session did not execute the migration against your connected project.

## 4. Replace the Edge Function folder

```bash
rm -rf supabase/functions/cricket-match-action
cp -R <package>/supabase/functions/cricket-match-action \
  supabase/functions/cricket-match-action
```

Confirm:

```bash
test ! -f supabase/functions/cricket-match-action/commands/record_toss_winner.ts
test ! -f supabase/functions/cricket-match-action/commands/record_toss_decision.ts
```

Then deploy:

```bash
supabase functions deploy cricket-match-action
```

## 5. Apply Flutter/data-layer changes

```bash
python3 <package>/repo_tools/apply_flutter_and_repository_changes.py
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Dart/Flutter are not installed in the artifact-generation environment, so these must be run in your development environment.

## 6. Recommended cutover order

```text
1. Validate all pieces together in local/staging
2. Apply database migration
3. Deploy replacement cricket-match-action immediately
4. Run updated Flutter client
5. Run verification SQL
6. Run Supabase security/performance advisors
```

There is no compatibility window by design.

## 7. Smoke-test essentials

- direct challenge originating team gets Cricket setup side;
- owner/manager/captain default setup permissions work;
- per-team override denial works;
- ordinary player is denied;
- one atomic toss accepts winner + decision;
- third-party team and duplicate toss are rejected;
- batting-side authority derives correctly for all four toss combinations;
- batting-side permitted user can select openers and start;
- neutral tournament Cricket fixture uses `setup_side=NULL`;
- assigned scorer receives `cricket.match.setup` + `match.score`;
- replacing/removing scorer updates grants;
- `match.lineup.set` is gone;
- `matches` contains no `host_side` or `setup_side`;
- `cricket_match_details` stays `security_invoker`.
