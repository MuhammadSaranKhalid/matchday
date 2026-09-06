-- match_challenges_pps_single_source — proposed_format.players_per_team is the
-- single source of truth for players-per-side on a match request.
--
-- Previously `match_challenges.players_per_side` was a standalone column written
-- alongside `proposed_format`. That allowed the two to drift. Now:
--   1. send_match_request folds the validated pps into proposed_format and no
--      longer writes the column.
--   2. a CHECK guarantees proposed_format always carries a valid players_per_team.
--   3. the standalone column becomes a generated projection of the blob.
--
-- NOTE: the live send path is the `send-match-request` edge function (not this
-- RPC). It was updated in lockstep (v2) to fold players_per_team into
-- proposed_format and drop the generated column from its INSERT. This RPC stays
-- as a fallback / direct-DB caller and is kept in sync here.

-- 1) send_match_request: same signature, but now folds the validated
--    players-per-side into proposed_format and no longer writes the column.
CREATE OR REPLACE FUNCTION public.send_match_request(
  p_from_team_id uuid,
  p_to_team_id uuid DEFAULT NULL::uuid,
  p_proposed_start_time timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_proposed_venue text DEFAULT NULL::text,
  p_proposed_format jsonb DEFAULT '{}'::jsonb,
  p_message text DEFAULT NULL::text,
  p_players_per_side integer DEFAULT 11,
  p_from_team_xi uuid[] DEFAULT '{}'::uuid[],
  p_from_team_keeper_id uuid DEFAULT NULL::uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_request_id uuid;
  v_code       text;
  v_attempts   integer := 0;
  v_pps        integer := coalesce(p_players_per_side, 11);
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_to_team_id is not null and p_from_team_id = p_to_team_id then
    raise exception 'A team cannot challenge itself' using errcode = '23514';
  end if;
  if not public.is_team_manager(p_from_team_id) then
    raise exception 'Only managers of the requesting team can send a match request'
      using errcode = '42501';
  end if;
  if v_pps < 5 or v_pps > 15 then
    raise exception 'players_per_side must be between 5 and 15' using errcode = '22023';
  end if;
  if p_from_team_xi is not null and array_length(p_from_team_xi, 1) is not null
     and array_length(p_from_team_xi, 1) > v_pps then
    raise exception 'from_team_xi has more players than players_per_side'
      using errcode = '22023';
  end if;
  perform public._validate_team_xi(p_from_team_id, p_from_team_xi);

  if p_to_team_id is not null and exists (
    select 1 from public.match_challenges
     where from_team_id = p_from_team_id
       and to_team_id   = p_to_team_id
       and status in ('pending', 'countered')
  ) then
    raise exception 'A pending request already exists for these teams'
      using errcode = '23505';
  end if;

  loop
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    begin
      insert into public.match_challenges (
        from_team_id, to_team_id, requested_by,
        proposed_start_time, proposed_venue, proposed_format, message,
        from_team_xi, from_team_keeper_id,
        share_code, code_expires_at, proposal_expires_at
      ) values (
        p_from_team_id, p_to_team_id, auth.uid(),
        p_proposed_start_time, p_proposed_venue,
        coalesce(p_proposed_format, '{}'::jsonb) || jsonb_build_object('players_per_team', v_pps),
        p_message,
        coalesce(p_from_team_xi, '{}'::uuid[]),
        p_from_team_keeper_id,
        v_code,
        now() + interval '24 hours',
        now() + interval '48 hours'
      )
      returning request_id into v_request_id;
      exit;
    exception when unique_violation then
      v_attempts := v_attempts + 1;
      if v_attempts >= 6 then
        raise;
      end if;
    end;
  end loop;

  return v_request_id;
end;
$function$;

-- 2 & 3. MOVED 2026-09-06.
--   match_challenges.players_per_side is declared as a GENERATED projection of
--   proposed_format->>'players_per_team' directly in
--   20260101000600_match_challenges.sql, together with the check constraint that
--   makes the projection sound. There is no longer a standalone column to drop
--   and re-add, so nothing remains here but the RPC above.
