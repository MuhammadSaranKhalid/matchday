-- Patch record_ball: the first ball of an innings has no prior ball to
-- look at, so `v_prev_kind` is NULL and `NULL = 'no_ball'` is NULL,
-- which then violates the NOT NULL constraint on balls.is_free_hit.
-- Coalesce to false so the very first delivery is not a free-hit.

create or replace function public.record_ball(
  p_match_id          uuid,
  p_innings_number    integer,
  p_is_legal_delivery boolean,
  p_ball_type         public.ball_kind,
  p_runs_scored       integer default 0,
  p_extras            integer default 0,
  p_is_wicket         boolean default false,
  p_wicket_type       public.wicket_kind default null,
  p_batsman_id        uuid default null,
  p_non_striker_id    uuid default null,
  p_bowler_id         uuid default null,
  p_fielder_id        uuid default null,
  p_commentary        text default null,
  p_expected_version  bigint default null
)
returns public.balls
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid          uuid := auth.uid();
  v_state        public.match_innings_state;
  v_over_number  integer;
  v_ball_in_over integer;
  v_prev_kind    public.ball_kind;
  v_is_free_hit  boolean;
  v_swap         boolean;
  v_over_ended   boolean;
  v_runs         integer := coalesce(p_runs_scored, 0);
  v_extras       integer := coalesce(p_extras, 0);
  v_row          public.balls;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organisers or assigned scorers can score this match'
      using errcode = '42501';
  end if;
  if p_innings_number not between 1 and 4 then
    raise exception 'innings_number must be between 1 and 4' using errcode = '23514';
  end if;
  if p_is_wicket and p_wicket_type is null then
    raise exception 'wicket_type is required when is_wicket=true' using errcode = '23514';
  end if;
  if not p_is_wicket and p_wicket_type is not null then
    raise exception 'wicket_type must be null when is_wicket=false' using errcode = '23514';
  end if;

  select * into v_state
    from public.match_innings_state
   where match_id = p_match_id and innings_number = p_innings_number
   for update;
  if not found then
    raise exception 'Innings % has not been started for this match', p_innings_number
      using errcode = '23000';
  end if;

  if p_expected_version is not null
     and v_state.version <> p_expected_version then
    raise exception 'Innings state changed under us (expected v%, got v%)',
      p_expected_version, v_state.version
      using errcode = '40001';
  end if;

  v_over_number := v_state.legal_ball_count / 6;
  if p_is_legal_delivery then
    v_ball_in_over := (v_state.legal_ball_count % 6) + 1;
  else
    v_ball_in_over := 0;
  end if;

  select ball_type into v_prev_kind
    from public.balls
   where match_id = p_match_id
     and innings_number = p_innings_number
     and ball_type <> 'wide'
   order by seq desc
   limit 1;
  v_is_free_hit := coalesce(v_prev_kind = 'no_ball', false);

  insert into public.balls (
    match_id, innings_number, over_number, ball_in_over,
    is_legal_delivery, ball_type, runs_scored, extras,
    is_wicket, wicket_type, is_free_hit,
    batsman_id, non_striker_id, bowler_id, fielder_id,
    commentary, created_by
  )
  values (
    p_match_id, p_innings_number, v_over_number, v_ball_in_over,
    p_is_legal_delivery, p_ball_type, v_runs, v_extras,
    p_is_wicket, p_wicket_type, v_is_free_hit,
    p_batsman_id, p_non_striker_id, p_bowler_id, p_fielder_id,
    p_commentary, v_uid
  )
  returning * into v_row;

  v_swap := (v_runs % 2 = 1)
            <> (p_is_legal_delivery and v_extras % 2 = 1);
  v_over_ended := p_is_legal_delivery and (v_state.legal_ball_count + 1) % 6 = 0;
  if v_over_ended then
    v_swap := not v_swap;
  end if;

  update public.match_innings_state mis
     set legal_ball_count = mis.legal_ball_count + (p_is_legal_delivery)::int,
         total_runs       = mis.total_runs + v_runs + v_extras,
         total_wickets    = mis.total_wickets + (p_is_wicket)::smallint,
         total_extras     = mis.total_extras + v_extras,
         striker_id       = case
           when p_is_wicket then null
           when v_swap then mis.non_striker_id
           else mis.striker_id
         end,
         non_striker_id   = case
           when v_swap and not p_is_wicket then mis.striker_id
           else mis.non_striker_id
         end,
         bowler_id        = case
           when v_over_ended then null
           else mis.bowler_id
         end,
         version          = mis.version + 1
   where mis.match_id       = p_match_id
     and mis.innings_number = p_innings_number;

  return v_row;
end;
$$;
