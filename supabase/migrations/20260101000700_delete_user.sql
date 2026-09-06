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
    select coalesce(display_name, 'Former player')
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
       set user_id      = null,
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
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_user() from public;
grant execute on function public.delete_user() to authenticated;


-- =============================================================================
-- Dangling uuid[] cleanup on profile delete
-- =============================================================================
-- Seven columns hold uuid[] of profile ids with no referential integrity —
-- an array cannot carry a foreign key. Deleting a profile therefore left its
-- id behind in every one of them, and two of those arrays (teams.managers,
-- tournaments.organizers) are read by RLS policies to decide who may write.
-- A stale id in an authorization array is the part that actually matters.
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
  update public.teams
     set managers = array_remove(managers, old.user_id)
   where old.user_id = any(managers);

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
