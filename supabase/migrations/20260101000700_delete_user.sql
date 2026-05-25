-- =============================================================================
-- 0700 · delete_user (self-service account deletion)
-- =============================================================================
-- Play Store data-safety policy (post-2024) requires self-service deletion
-- for any app collecting PII. This file owns the RPC and the FK relaxation
-- it depends on.
--
-- Flow:
--   1. User taps Settings → Delete account.
--   2. Client calls public.delete_user() (this RPC).
--   3. RPC anonymises matches the user created (`created_by` → null) and
--      deletes the auth.users row, which cascades into public.profiles +
--      every per-user table hung off it.
--
-- Why anonymise matches:
--   The /m/<id> spectator URL must keep working after the creator deletes
--   their account. Cascading the FK would orphan or delete the match;
--   nulling created_by lets the historical scorecard live on without an
--   author.
--
-- This migration also has to relax the matches.created_by FK — when the
-- table was created (0400) it was `not null references profiles(user_id)
-- on delete restrict`. Both pieces have to change here.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Step 1 — relax matches.created_by.
-- -----------------------------------------------------------------------------
alter table public.matches
  alter column created_by drop not null;

alter table public.matches
  drop constraint matches_created_by_fkey;

alter table public.matches
  add constraint matches_created_by_fkey
    foreign key (created_by) references public.profiles(user_id)
    on delete set null;

-- -----------------------------------------------------------------------------
-- Step 2 — the RPC. SECURITY DEFINER so it can reach auth.users; the
-- auth.uid() guard makes self-service deletion the only callable shape.
-- -----------------------------------------------------------------------------
create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  -- Defensive: explicit anonymise even though the FK action above would do
  -- this on cascade. Keeps the RPC predictable if the FK action ever changes.
  update public.matches
     set created_by = null
   where created_by = v_uid;

  -- Cascades through profiles + everything else hung off auth.users.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_user() from public;
grant execute on function public.delete_user() to authenticated;
