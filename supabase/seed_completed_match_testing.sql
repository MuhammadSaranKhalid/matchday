-- =============================================================================
-- seed_completed_match_testing.sql — a fully scored match for the
-- Completed Match screen
-- =============================================================================
-- seed_my_matches_testing.sql produces past matches whose deliveries have NULL
-- striker/non-striker/bowler. That is fine for a score line — the My Matches
-- past card only needs the two totals — but the Completed Match screen derives
-- the ENTIRE scorecard from the ledger, so those matches open with an empty
-- batting card, an empty bowling card and no fall of wickets.
--
-- This file upgrades ONE of them (the won match, ff…011) into a real ledger:
--   · 22 match_players (11 a side), named, with a batting order
--   · every delivery attributed to a striker, non-striker and bowler
--   · cricket_match_wickets rows so dismissals, fall of wickets and partnerships exist
--
-- The arithmetic is deliberately plain — a fixed per-over run pattern — because
-- the point is to exercise the DERIVATION, not to simulate a believable match.
-- What matters is that every column the screen reads is populated.
--
-- RUN IN THE SUPABASE DASHBOARD SQL EDITOR, after seed_challenges_testing.sql
-- and seed_my_matches_testing.sql. Idempotent for the fixed uuids below.
-- =============================================================================

do $seed_cm$
declare
  v_me       uuid;
  v_match    constant uuid := 'ff000000-0000-4000-8000-000000000011';
  v_inn1     constant uuid := 'fa000000-0000-4000-8000-000000000011';
  v_inn2     constant uuid := 'fb000000-0000-4000-8000-000000000011';
  v_names_a  constant text[] := array[
    'Bilal Hussain','Abdul Rehman Qureshi','Faizan Malik','Zeeshan Iqbal',
    'Adeel Butt','Kamran Ali','Saad Nawaz','Hamza Sheikh','Talha Aziz',
    'Noman Baig','Rizwan Haider'];
  v_names_b  constant text[] := array[
    'Danish Raza','Shahzaib Khan','Owais Farooq','Junaid Akhtar',
    'Tayyab Sohail','Waleed Anjum','Fahad Mehmood','Sohail Abbas',
    'Imran Yousaf','Asad Jamil','Bilal Tariq'];
  v_a        uuid[] := '{}';
  v_b        uuid[] := '{}';
  v_uid      uuid;
  v_mp       uuid;
  i          int;
  v_inn      int;
  v_seq      int;
  v_over     int;
  v_ball     int;
  v_runs     int;
  v_delivery uuid;
  v_bat      uuid[];
  v_bowl     uuid[];
  v_innid    uuid;
  v_striker  int;   -- index into v_bat
  v_wkt      int;
  v_total    int;
begin
  select id into v_me from auth.users
   where lower(email) = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_me is null then
    raise exception 'Sign in on the emulator first.';
  end if;
  if not exists (select 1 from public.matches where match_id = v_match) then
    raise exception 'Run seed_my_matches_testing.sql first — it creates %.', v_match;
  end if;

  -- ── Clean up (deliveries cascade to wickets) ──────────────────────────────
  delete from public.cricket_match_deliveries where match_id = v_match;
  delete from public.match_players     where match_id = v_match;
  delete from public.unclaimed_players
   where unclaimed_id::text like 'cd000000-0000-4000-8000-%';

  -- ── 22 players ────────────────────────────────────────────────────────────
  -- Unclaimed placeholders rather than profiles: seeding real auth users for
  -- 22 people would collide with the identities used to sign in.
  for i in 1..22 loop
    v_uid := ('cd000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
    insert into public.unclaimed_players (unclaimed_id, sport_id, display_name, added_by)
    values (
      v_uid,
      'cricket',
      case when i <= 11 then v_names_a[i] else v_names_b[i - 11] end,
      v_me
    );

    v_mp := ('ce000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
    insert into public.match_players (
      match_player_id, match_id, team_side, unclaimed_id, display_name,
      is_in_playing_xi, batting_order
    ) values (
      v_mp, v_match,
      case when i <= 11 then 'team_a' else 'team_b' end,
      v_uid,
      case when i <= 11 then v_names_a[i] else v_names_b[i - 11] end,
      true,
      case when i <= 11 then i else i - 11 end
    );

    if i <= 11 then v_a := v_a || v_mp; else v_b := v_b || v_mp; end if;
  end loop;

  -- ── Two innings of deliveries ─────────────────────────────────────────────
  for v_inn in 1..2 loop
    if v_inn = 1 then
      v_innid := v_inn1; v_bat := v_a; v_bowl := v_b;
    else
      v_innid := v_inn2; v_bat := v_b; v_bowl := v_a;
    end if;

    v_seq := 0; v_striker := 1; v_wkt := 0; v_total := 0;

    for i in 1..96 loop
      v_over := (i - 1) / 6;
      v_ball := ((i - 1) % 6) + 1;
      v_seq  := v_seq + 1;
      -- Innings 1 outscores innings 2, so "Strikers won by 16 runs" is true.
      v_runs := case when v_inn = 1
                     then (array[1,0,2,1,0,4])[v_ball]
                     else (array[1,0,1,2,0,3])[v_ball] end;

      -- A wicket every 13th ball, up to 9 — never the last batter standing.
      if i % 13 = 0 and v_wkt < 9 then
        v_runs := 0;
      end if;

      v_delivery := gen_random_uuid();
      insert into public.cricket_match_deliveries (
        delivery_id, innings_id, match_id, innings_number, seq,
        over_number, ball_in_over, is_legal_delivery, delivery_type,
        runs_off_bat, extra_runs, is_wicket, wicket_type,
        striker_id, non_striker_id, bowler_id, idempotency_key
      ) values (
        v_delivery, v_innid, v_match, v_inn, v_seq,
        v_over, v_ball, true, 'legal',
        v_runs, 0,
        (i % 13 = 0 and v_wkt < 9),
        case when i % 13 = 0 and v_wkt < 9 then 'bowled'::public.wicket_kind end,
        v_bat[v_striker],
        v_bat[case when v_striker = 11 then 10 else v_striker + 1 end],
        -- Four bowlers, four overs each, rotating every over.
        v_bowl[(v_over % 4) + 1],
        v_match::text || '-' || v_inn || '-' || v_seq
      );

      v_total := v_total + v_runs;

      if i % 13 = 0 and v_wkt < 9 then
        v_wkt := v_wkt + 1;
        insert into public.cricket_match_wickets (
          delivery_id, innings_id, player_out_id, dismissal_kind,
          is_bowler_credited, credited_bowler_id,
          fall_of_wicket_score, fall_of_wicket_number, fall_of_wicket_overs
        ) values (
          v_delivery, v_innid, v_bat[v_striker], 'bowled',
          true, v_bowl[(v_over % 4) + 1],
          v_total, v_wkt, (v_over + v_ball / 10.0)
        );
        -- Next batter in.
        v_striker := least(v_wkt + 1, 11);
      elsif v_runs % 2 = 1 then
        -- Odd runs rotate the strike.
        v_striker := case when v_striker = 11 then 10 else v_striker + 1 end;
      end if;
    end loop;
  end loop;

  -- Make the result sentence agree with the ledger. A seed that says
  -- "won by 16 runs" over a scorecard reading 119 v 104 teaches the reviewer
  -- to distrust the screen — which is the opposite of what a seed is for.
  update public.matches m
     set result = jsonb_build_object(
           'description',
           format('Strikers won by %s runs', t.margin))
    from (
      select
        sum(case when d.innings_number = 1
                 then d.runs_off_bat + d.extra_runs else 0 end)
        - sum(case when d.innings_number = 2
                   then d.runs_off_bat + d.extra_runs else 0 end) as margin
      from public.cricket_match_deliveries d
      where d.match_id = v_match
    ) t
   where m.match_id = v_match;

  raise notice 'Seeded a full ledger for %', v_match;
end
$seed_cm$;

-- Sanity read — expect two innings with 96 legal balls and 9 wickets each.
select
  d.innings_number,
  count(*)                                          as deliveries,
  sum(d.runs_off_bat + d.extra_runs)                as runs,
  count(*) filter (where d.is_wicket)               as wickets,
  count(distinct d.striker_id)                      as batters_used,
  count(distinct d.bowler_id)                       as bowlers_used
from public.cricket_match_deliveries d
where d.match_id = 'ff000000-0000-4000-8000-000000000011'
group by d.innings_number
order by d.innings_number;
