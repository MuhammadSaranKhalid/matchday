-- =============================================================================
-- 0700 · delete_user — self-service account deletion
-- =============================================================================
-- WHY THIS RPC EXISTS
-- -------------------
-- Play Store data-safety policy (post-2024) requires every app collecting
-- PII to offer self-service account deletion. This RPC is the single
-- entry point.
--
-- THE FLOW
-- --------
--   1. User taps Settings → Delete account.
--   2. Client calls public.delete_user() (this RPC).
--   3. The RPC walks every table that references the user and either
--      anonymises the row (history-preserving) or lets ON DELETE
--      cascade clean it up. Then it deletes the auth.users row, which
--      cascades into public.profiles + every per-user table that has
--      ON DELETE CASCADE on profiles.user_id.
--
-- WHAT GETS ANONYMISED, AND WHY
-- -----------------------------
-- Three references to profiles cannot be cascaded because their target
-- rows are historical artefacts that must outlive the user:
--
--   * matches.created_by      — the /m/<id> spectator URL must keep
--                                working after the creator deletes
--                                their account. (FK is ON DELETE SET
--                                NULL in 0400; we also null it
--                                explicitly here as a belt-and-braces.)
--
--   * match_deliveries.recorded_by — same reasoning. The scorer's name
--                                disappears from the over-by-over feed,
--                                but the deliveries themselves remain.
--                                (FK is ON DELETE SET NULL in 0400.)
--
--   * match_players.user_id    — historical lineups (and therefore the
--                                full scorecard / stats lineage) must
--                                survive a profile delete. We promote
--                                the user's match_players rows to point
--                                at a synthetic unclaimed_players row
--                                that preserves their display name.
--                                This is the same identity-merge flow
--                                the cascade_unclaimed_claim trigger
--                                runs in the OPPOSITE direction (when
--                                an unclaimed player claims a profile).
--                                (FK is ON DELETE RESTRICT — the
--                                promotion below is mandatory.)
--
-- WHAT GETS CASCADED (no explicit action here)
-- --------------------------------------------
-- The auth.users → profiles → ... cascade chain handles:
--   * team_members.user_id (ON DELETE CASCADE) — the user vanishes
--     from team rosters automatically.
--   * notifications, posts, comments, likes, bookmarks, follows,
--     device_tokens — all cascade off profiles.
--   * match_officials.user_id (ON DELETE CASCADE) — the user's scorer
--     / umpire assignments vanish.
--   * Captain/keeper/MOTM FKs on matches (ON DELETE SET NULL) — set
--     to null automatically.
--
-- SECURITY DEFINER + auth.uid() GATE
-- ----------------------------------
-- The function runs as the table owner so it can reach auth.users.
-- The first guard rejects unauthenticated callers; the body only ever
-- operates on the calling user's own data — there is no path to delete
-- another user's account. The function is granted ONLY to the
-- `authenticated` role.
-- =============================================================================

create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_unclaimed_id  uuid;
  v_display_name  text;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- ---------------------------------------------------------------------------
  -- Match-history promotion (match_players.user_id).
  -- ---------------------------------------------------------------------------
  -- If the user has EVER appeared in a match lineup, create one
  -- unclaimed_players placeholder carrying their display name, then
  -- rewrite all their match_players rows to point at it.
  --
  -- Collision guard: if rewriting would put the placeholder on the same
  -- (match, team_side) as an existing row for the same person (cannot
  -- happen via app flows but possible via manual data tooling), the
  -- partial unique on match_players_unique_unclaimed would reject the
  -- update. The NOT EXISTS subquery skips those rows so the bulk
  -- update completes; orphans are left as-is for operator review.
  if exists (select 1 from public.match_players where user_id = v_uid) then
    select 'Deleted player'
      into v_display_name
      from public.profiles
     where user_id = v_uid;

    -- added_by is left NULL: no manager created this placeholder, and pointing
    -- it at v_uid would either cascade it away or trip a not-null violation
    -- when auth.users is deleted below.
    insert into public.unclaimed_players (display_name, added_by)
    values (v_display_name, null)
    returning unclaimed_id into v_unclaimed_id;

    update public.match_players mp1
       set display_name = 'Deleted player',
           jersey_number = null,
           user_id      = null,
           unclaimed_id = v_unclaimed_id
     where user_id = v_uid
       and not exists (
         select 1 from public.match_players mp2
          where mp2.match_id     = mp1.match_id
            and mp2.team_side    = mp1.team_side
            and mp2.unclaimed_id = v_unclaimed_id
       );
  end if;

  -- ---------------------------------------------------------------------------
  -- Authored-row anonymisation. Belt-and-braces — the FKs already do this
  -- on cascade, but explicit makes the RPC predictable if the FK actions
  -- ever change.
  -- ---------------------------------------------------------------------------
  update public.matches           set created_by  = null where created_by  = v_uid;
  update public.match_deliveries  set recorded_by = null where recorded_by = v_uid;

  -- Audit breadcrumbs that must not block the delete. Both FKs are ON DELETE
  -- SET NULL so this is belt-and-braces, but explicit keeps the RPC readable.
  update public.team_members      set added_by    = null where added_by    = v_uid;
  update public.unclaimed_players set added_by    = null where added_by    = v_uid;

  -- ---------------------------------------------------------------------------
  -- Final cascade. Everything else hung off auth.users / profiles cleans
  -- up via its own ON DELETE CASCADE.
  -- ---------------------------------------------------------------------------
  -- A profile's claimed placeholders must not retain identity/contact data.
  update public.unclaimed_players set display_name = 'Deleted player',
    phone_number = null, email = null, player_profile = '{}'::jsonb,
    claimed_by_user_id = null, claimed_at = null where claimed_by_user_id = v_uid;
  update public.messages set body = 'This message was deleted', payload = '{}'::jsonb,
    deleted_at = now() where sender_id = v_uid;

  -- The authenticated Edge Function removes bytes through the Storage API first.
  -- Deleting storage.objects rows directly would leak the underlying objects.
  if exists (select 1 from storage.objects o where o.owner_id = v_uid::text
    or (o.bucket_id = 'avatars' and split_part(o.name, '/', 1) = v_uid::text)
    or (o.bucket_id = 'post-media' and exists (select 1 from public.posts p
      where p.author_id = v_uid and p.post_id::text = split_part(o.name, '/', 1)))) then
    raise exception 'Remove uploaded files before completing account deletion';
  end if;
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_user() from public;
grant execute on function public.delete_user() to authenticated;


-- =============================================================================
-- Dangling uuid[] cleanup on profile delete
-- =============================================================================
-- Six columns hold uuid[] of profile ids with no referential integrity —
-- an array cannot carry a foreign key. Deleting a profile therefore left its
-- id behind in every one of them, and one of those arrays
-- (tournaments.organizers) is read by RLS policies to decide who may write.
-- A stale id in an authorization array is the part that actually matters.
--
-- teams.managers was the seventh and is gone (2026-09-10) — team authority
-- moved to team_members, which has a real FK and cascades on its own. What
-- replaced it here is the ownership-succession block below: a real FK cleans
-- up the row, but it cannot decide who should run the team next.
--
-- A trigger rather than more statements inside delete_user(), so it also
-- catches deletions that do not go through the RPC — an admin DELETE, or the
-- auth.users cascade.
--
-- Forward references are deliberate and safe here: the body is plpgsql, which
-- Postgres does NOT check at CREATE time, and every table named below exists
-- by the end of the migration run — which is the earliest this can ever fire.
-- (The same late-binding that hid the match_officials ordering bug is the
-- thing that makes this legal.)
create or replace function public._strip_deleted_profile_from_arrays()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Ownership succession (rewritten 2026-09-11 for the role model).
  --
  -- A departing member's team_members row cascades on the profiles FK, taking
  -- its team_member_roles with it — so staff cleanup is automatic. What is NOT
  -- automatic is succession: `is_singleton` stops a SECOND owner but nothing
  -- stops ZERO, and a team whose only owner deleted their account would be
  -- left with nobody able to act (the owner short-circuit in can() has no one
  -- to fire for).
  --
  -- The longest-tenured remaining manager is promoted into the `owner` role.
  -- If there is no manager, the team is archived rather than left headless.
  -- teams.created_by is deliberately NOT touched — it is history, and history
  -- does not change when someone leaves.
  with orphaned as (
    select tm.team_id
      from public.team_members tm
      join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
     where tm.user_id  = old.user_id
       and tmr.role_key = 'owner'
       and tm.status   = 'active'
  ),
  successor as (
    select distinct on (o.team_id)
           o.team_id, tm.membership_id
      from orphaned o
      join public.team_members tm
        on tm.team_id = o.team_id
       and tm.status  = 'active'
       and tm.user_id is not null
       and tm.user_id <> old.user_id
      join public.team_member_roles tmr
        on tmr.membership_id = tm.membership_id
       and tmr.role_key = 'manager'
     order by o.team_id, tm.joined_at asc
  ),
  -- Drop the successor's manager row before adding owner: they are two rows in
  -- the same exclusion set {owner, manager, player}, max 1.
  demoted as (
    delete from public.team_member_roles tmr
     using successor s
     where tmr.membership_id = s.membership_id
       and tmr.role_key in ('manager', 'player')
    returning tmr.membership_id
  ),
  promoted as (
    insert into public.team_member_roles
      (membership_id, scope, role_key, team_id, is_singleton)
    select s.membership_id, 'team', 'owner', s.team_id, true
      from successor s
    returning team_id
  )
  update public.teams t
     set status = 'archived'
   where t.team_id in (select team_id from orphaned)
     and t.team_id not in (select team_id from promoted)
     and t.status = 'active';

  update public.tournaments
     set organizers = array_remove(organizers, old.user_id)
   where old.user_id = any(organizers);

  update public.tournament_teams
     set squad = array_remove(squad, old.user_id)
   where old.user_id = any(squad);

  update public.match_challenges
     set from_team_xi = array_remove(from_team_xi, old.user_id)
   where old.user_id = any(from_team_xi);

  update public.match_pool_applications
     set applicant_xi = array_remove(applicant_xi, old.user_id)
   where old.user_id = any(applicant_xi);

  update public.posts
     set linked_player_ids = array_remove(linked_player_ids, old.user_id)
   where old.user_id = any(linked_player_ids);

  update public.comments
     set mentioned_user_ids = array_remove(mentioned_user_ids, old.user_id)
   where old.user_id = any(mentioned_user_ids);

  return old;
end;
$$;

drop trigger if exists profiles_strip_from_arrays on public.profiles;
create trigger profiles_strip_from_arrays
  before delete on public.profiles
  for each row execute function public._strip_deleted_profile_from_arrays();

-- Only the caller's own object names; bounded batches for the deletion worker.
create or replace function public.my_deletion_objects()
returns table(bucket_id text, name text)
language sql stable security definer set search_path = '' as $$
  select o.bucket_id, o.name from storage.objects o
  where auth.uid() is not null and (
    o.owner_id = auth.uid()::text
    or (o.bucket_id = 'avatars' and split_part(o.name, '/', 1) = auth.uid()::text)
    or (o.bucket_id = 'post-media' and exists(select 1 from public.posts p
      where p.author_id = auth.uid() and p.post_id::text = split_part(o.name, '/', 1))))
  order by o.bucket_id, o.name limit 100;
$$;
revoke all on function public.my_deletion_objects() from public, anon;
grant execute on function public.my_deletion_objects() to authenticated;
