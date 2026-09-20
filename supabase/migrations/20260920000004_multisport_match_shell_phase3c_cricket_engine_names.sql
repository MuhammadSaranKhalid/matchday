-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 3C
-- Cricket engine physical table ownership / naming
-- =============================================================================
--
-- REQUIRES:
--   Phase 2A
--   Phase 2B
--   Phase 3A
--   Phase 3B
--
-- PHYSICAL TABLES AFTER THIS MIGRATION:
--
--   cricket_match_innings
--   cricket_match_innings_state
--   cricket_match_deliveries
--   cricket_match_wickets
--
-- The former generic names are removed completely:
--
--   match_innings
--   match_innings_state
--   match_deliveries
--   match_wickets
--
-- There are no compatibility views because Matchday is still in development
-- and there are no users / older installed app versions to support.
--
-- `balls` is also removed completely. It was only a compatibility view over
-- match_deliveries and must not survive the hard cut.
--
-- No data is copied. ALTER TABLE ... RENAME preserves table OIDs, rows,
-- foreign keys, RLS, grants, indexes and dependent view relationships.
-- =============================================================================


-- =============================================================================
-- 0. Preflight — refuse a partial/out-of-order destructive rename
-- =============================================================================

do $$
declare
  v_lifecycle text[];
begin
  if to_regtype('public.cricket_match_phase') is null
     or to_regtype('public.cricket_toss_decision') is null
     or to_regtype('public.cricket_delivery_kind') is null
     or to_regtype('public.cricket_wicket_kind') is null
  then
    raise exception
      'Phase 3C requires Phase 3B Cricket-owned types.';
  end if;

  select array_agg(e.enumlabel order by e.enumsortorder)
    into v_lifecycle
  from pg_enum e
  where e.enumtypid = 'public.match_status'::regtype;

  if v_lifecycle is distinct from
       array[
         'scheduled',
         'live',
         'completed',
         'abandoned',
         'cancelled'
       ]::text[]
  then
    raise exception
      'Phase 3C requires the Phase 3B generic match_status lifecycle. Found: %',
      v_lifecycle;
  end if;

  -- Old names must still be real physical tables at the start of 3C.
  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'match_innings'
      and c.relkind = 'r'
  ) or not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'match_innings_state'
      and c.relkind = 'r'
  ) or not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'match_deliveries'
      and c.relkind = 'r'
  ) or not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'match_wickets'
      and c.relkind = 'r'
  ) then
    raise exception
      'Phase 3C expected the four legacy-named Cricket engine tables to still be physical tables.';
  end if;

  -- New physical names must not exist yet.
  if to_regclass('public.cricket_match_innings') is not null
     or to_regclass('public.cricket_match_innings_state') is not null
     or to_regclass('public.cricket_match_deliveries') is not null
     or to_regclass('public.cricket_match_wickets') is not null
  then
    raise exception
      'Phase 3C appears partially/already applied. Reconcile instead of rerunning.';
  end if;

  -- Phase 3B should already have removed the only old `balls` function usage.
  -- Do not drop the compatibility view while active server code still names it.
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and position(
        'public.balls'
        in pg_get_functiondef(p.oid)
      ) > 0
  ) then
    raise exception
      'An installed public function still references public.balls. Migrate that caller before Phase 3C.';
  end if;

  -- Guard against the rewrite accidentally renaming a FUNCTION identity rather
  -- than only relation references in a body.
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and (
        p.proname like '%match_innings%'
        or p.proname like '%match_deliveries%'
        or p.proname like '%match_wickets%'
      )
  ) then
    raise exception
      'A public function name itself contains a legacy engine table name. Handle it explicitly before the automatic body rewrite.';
  end if;
end
$$;


-- =============================================================================
-- 1. Retire the duplicate Supabase-Realtime match transport
-- =============================================================================
--
-- Matchday's current match transport is:
--
--   Edge Function -> PostgreSQL -> canonical snapshot -> Ably
--
-- The database realtime.send triggers and CDC publication entries are a second,
-- drifting transport and are no longer consumed by the current Flutter code.
-- =============================================================================

drop trigger if exists trg_broadcast_match_state
  on public.matches;

drop trigger if exists trg_broadcast_innings_state
  on public.match_innings_state;

drop trigger if exists trg_broadcast_delivery
  on public.match_deliveries;

drop trigger if exists trg_broadcast_delivery_deleted
  on public.match_deliveries;


drop function if exists public.broadcast_match_state_updated();
drop function if exists public.broadcast_innings_state_updated();
drop function if exists public.broadcast_new_delivery();
drop function if exists public.broadcast_delivery_deleted();


-- `supabase_realtime` is normally a selective publication. Remove Matchday
-- match-engine CDC entries if they are present. If an installation uses an
-- ALL-TABLES publication, there is nothing table-specific to remove here.
do $$
declare
  v_all_tables boolean;
  v_name text;
begin
  select puballtables
    into v_all_tables
    from pg_publication
   where pubname = 'supabase_realtime';

  if not found or v_all_tables then
    return;
  end if;

  foreach v_name in array array[
    'matches',
    'match_innings_state',
    'match_deliveries',
    'match_wickets'
  ]
  loop
    if exists (
      select 1
      from pg_publication_tables pt
      where pt.pubname = 'supabase_realtime'
        and pt.schemaname = 'public'
        and pt.tablename = v_name
    ) then
      execute format(
        'alter publication supabase_realtime drop table public.%I',
        v_name
      );
    end if;
  end loop;
end
$$;


-- =============================================================================
-- 2. Remove the redundant `balls` compatibility alias
-- =============================================================================

drop view if exists public.balls;


-- =============================================================================
-- 3. Physical rename — NO COPY, same rows/OIDs/FKs/RLS
-- =============================================================================

alter table public.match_innings
  rename to cricket_match_innings;

alter table public.match_innings_state
  rename to cricket_match_innings_state;

alter table public.match_deliveries
  rename to cricket_match_deliveries;

alter table public.match_wickets
  rename to cricket_match_wickets;


-- =============================================================================
-- 4. Rewrite every installed public function body onto the new physical names
-- =============================================================================
--
-- PL/pgSQL bodies are stored as source text. Table OID renames preserve FKs and
-- views, but a late-bound function body that says "from match_deliveries" can
-- still fail on its next call.
--
-- Instead of maintaining a fragile hand-list, rewrite every installed public
-- function whose definition still contains one of the four legacy relation
-- names. Function identity/owner/privileges are preserved by CREATE OR REPLACE.
--
-- Tournament batting/bowling leaderboards are excluded here and rebuilt
-- explicitly below because Phase 3B also changed their lifecycle semantics.
-- =============================================================================

do $rewrite$
declare
  r record;
  v_sql text;
begin
  for r in
    select
      p.oid,
      p.proname,
      pg_get_functiondef(p.oid) as definition
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and p.proname not in (
        'tournament_batting_leaderboard',
        'tournament_bowling_leaderboard'
      )
      and (
        position(
          'match_innings_state'
          in pg_get_functiondef(p.oid)
        ) > 0
        or position(
          'match_deliveries'
          in pg_get_functiondef(p.oid)
        ) > 0
        or position(
          'match_wickets'
          in pg_get_functiondef(p.oid)
        ) > 0
        or position(
          'match_innings'
          in pg_get_functiondef(p.oid)
        ) > 0
      )
  loop
    v_sql := r.definition;

    -- First protect any canonical names PostgreSQL may already render after
    -- ALTER TABLE ... RENAME. Then replace only genuinely legacy tokens.
    -- This makes the rewrite safe whether pg_get_functiondef() shows the old
    -- source spelling or the new relation/type spelling.
    v_sql := replace(
      v_sql,
      'cricket_match_innings_state',
      '__MATCHDAY_ALREADY_CRICKET_INNINGS_STATE__'
    );
    v_sql := replace(
      v_sql,
      'cricket_match_deliveries',
      '__MATCHDAY_ALREADY_CRICKET_DELIVERIES__'
    );
    v_sql := replace(
      v_sql,
      'cricket_match_wickets',
      '__MATCHDAY_ALREADY_CRICKET_WICKETS__'
    );
    v_sql := replace(
      v_sql,
      'cricket_match_innings',
      '__MATCHDAY_ALREADY_CRICKET_INNINGS__'
    );

    v_sql := replace(
      v_sql,
      'match_innings_state',
      '__MATCHDAY_LEGACY_INNINGS_STATE__'
    );
    v_sql := replace(
      v_sql,
      'match_deliveries',
      '__MATCHDAY_LEGACY_DELIVERIES__'
    );
    v_sql := replace(
      v_sql,
      'match_wickets',
      '__MATCHDAY_LEGACY_WICKETS__'
    );
    v_sql := replace(
      v_sql,
      'match_innings',
      '__MATCHDAY_LEGACY_INNINGS__'
    );

    v_sql := replace(
      v_sql,
      '__MATCHDAY_LEGACY_INNINGS_STATE__',
      'cricket_match_innings_state'
    );
    v_sql := replace(
      v_sql,
      '__MATCHDAY_LEGACY_DELIVERIES__',
      'cricket_match_deliveries'
    );
    v_sql := replace(
      v_sql,
      '__MATCHDAY_LEGACY_WICKETS__',
      'cricket_match_wickets'
    );
    v_sql := replace(
      v_sql,
      '__MATCHDAY_LEGACY_INNINGS__',
      'cricket_match_innings'
    );

    v_sql := replace(
      v_sql,
      '__MATCHDAY_ALREADY_CRICKET_INNINGS_STATE__',
      'cricket_match_innings_state'
    );
    v_sql := replace(
      v_sql,
      '__MATCHDAY_ALREADY_CRICKET_DELIVERIES__',
      'cricket_match_deliveries'
    );
    v_sql := replace(
      v_sql,
      '__MATCHDAY_ALREADY_CRICKET_WICKETS__',
      'cricket_match_wickets'
    );
    v_sql := replace(
      v_sql,
      '__MATCHDAY_ALREADY_CRICKET_INNINGS__',
      'cricket_match_innings'
    );

    execute v_sql;
  end loop;
end
$rewrite$;


-- =============================================================================
-- 5. Tournament leaderboards — table rename + Phase-3B lifecycle semantics
-- =============================================================================
--
-- The old leaderboard SQL treated innings_break/super_over/tied as parent
-- statuses. After 3B those are represented by:
--
--   parent live/completed + Cricket phase/result
--
-- For the previous behavior, scored deliveries count when the parent is
-- `live` or `completed`; abandoned/no-result fixtures remain excluded.
-- =============================================================================

create or replace function public.tournament_batting_leaderboard(
  p_tournament_id uuid,
  p_limit         integer default 5
)
returns table (
  player_key    text,
  display_name  text,
  team_name     text,
  team_monogram text,
  is_unclaimed  boolean,
  runs          integer,
  balls_faced   integer,
  fours         integer,
  sixes         integer,
  strike_rate   numeric,
  innings       integer,
  high_score    integer
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with deliveries as (
    select
      d.*,
      mp.display_name,
      mp.user_id,
      mp.unclaimed_id,
      mp.team_side,
      m.team_a_id,
      m.team_b_id
    from public.cricket_match_deliveries d
    join public.matches m
      on m.match_id = d.match_id
    join public.match_players mp
      on mp.match_player_id = d.striker_id
    where m.tournament_id = p_tournament_id
      and d.is_undone = false
      and m.status in ('live', 'completed')
  ),

  per_player_match as (
    select
      coalesce(
        'u:' || dv.user_id::text,
        'x:' || dv.unclaimed_id::text
      ) as player_key,

      dv.match_id,
      max(dv.display_name) as display_name,
      bool_or(dv.user_id is null) as is_unclaimed,

      (
        array_agg(
          case dv.team_side
            when 'team_a' then dv.team_a_id
            else dv.team_b_id
          end
        )
      )[1] as team_id,

      sum(dv.runs_off_bat)::integer as runs,

      count(*) filter (
        where dv.is_legal_delivery
      )::integer as balls,

      count(*) filter (
        where dv.is_four
      )::integer as fours,

      count(*) filter (
        where dv.is_six
      )::integer as sixes

    from deliveries dv
    where coalesce(
      dv.user_id::text,
      dv.unclaimed_id::text
    ) is not null

    group by 1, 2
  ),

  totals as (
    select
      p.player_key,
      max(p.display_name) as display_name,
      bool_or(p.is_unclaimed) as is_unclaimed,

      (
        array_agg(
          p.team_id
          order by p.match_id desc
        )
      )[1] as team_id,

      sum(p.runs)::integer as runs,
      sum(p.balls)::integer as balls_faced,
      sum(p.fours)::integer as fours,
      sum(p.sixes)::integer as sixes,
      count(*)::integer as innings,
      max(p.runs)::integer as high_score

    from per_player_match p
    group by p.player_key
  )

  select
    t.player_key,
    t.display_name,
    tm.team_name,
    tm.logo_monogram,
    t.is_unclaimed,
    t.runs,
    t.balls_faced,
    t.fours,
    t.sixes,

    case
      when t.balls_faced = 0
        then 0
      else round(
        (t.runs::numeric * 100)
        / t.balls_faced,
        1
      )
    end,

    t.innings,
    t.high_score

  from totals t
  left join public.teams tm
    on tm.team_id = t.team_id

  where t.runs > 0

  order by
    t.runs desc,
    t.balls_faced asc,
    t.display_name

  limit greatest(
    coalesce(p_limit, 5),
    1
  );
$$;

revoke all
  on function public.tournament_batting_leaderboard(
    uuid,
    integer
  )
  from public, anon;

grant execute
  on function public.tournament_batting_leaderboard(
    uuid,
    integer
  )
  to authenticated;


create or replace function public.tournament_bowling_leaderboard(
  p_tournament_id uuid,
  p_limit         integer default 5
)
returns table (
  player_key    text,
  display_name  text,
  team_name     text,
  team_monogram text,
  is_unclaimed  boolean,
  wickets       integer,
  runs_conceded integer,
  legal_balls   integer,
  economy       numeric,
  innings       integer,
  best_wickets  integer,
  best_runs     integer
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with deliveries as (
    select
      d.*,
      mp.display_name,
      mp.user_id,
      mp.unclaimed_id,
      mp.team_side,
      m.team_a_id,
      m.team_b_id
    from public.cricket_match_deliveries d
    join public.matches m
      on m.match_id = d.match_id
    join public.match_players mp
      on mp.match_player_id = d.bowler_id
    where m.tournament_id = p_tournament_id
      and d.is_undone = false
      and m.status in ('live', 'completed')
  ),

  per_player_match as (
    select
      coalesce(
        'u:' || dv.user_id::text,
        'x:' || dv.unclaimed_id::text
      ) as player_key,

      dv.match_id,
      max(dv.display_name) as display_name,
      bool_or(dv.user_id is null) as is_unclaimed,

      (
        array_agg(
          case dv.team_side
            when 'team_a' then dv.team_a_id
            else dv.team_b_id
          end
        )
      )[1] as team_id,

      count(*) filter (
        where dv.is_wicket
          and dv.wicket_type::text =
              any(public._bowler_credited_wickets())
      )::integer as wickets,

      sum(
        case
          when dv.delivery_type in (
            'bye',
            'leg_bye',
            'penalty'
          )
          then dv.runs_off_bat
          else dv.runs_off_bat + dv.extra_runs
        end
      )::integer as runs_conceded,

      count(*) filter (
        where dv.is_legal_delivery
      )::integer as legal_balls

    from deliveries dv

    where coalesce(
      dv.user_id::text,
      dv.unclaimed_id::text
    ) is not null

    group by 1, 2
  ),

  totals as (
    select
      p.player_key,
      max(p.display_name) as display_name,
      bool_or(p.is_unclaimed) as is_unclaimed,

      (
        array_agg(
          p.team_id
          order by p.match_id desc
        )
      )[1] as team_id,

      sum(p.wickets)::integer as wickets,
      sum(p.runs_conceded)::integer as runs_conceded,
      sum(p.legal_balls)::integer as legal_balls,
      count(*)::integer as innings,

      (
        array_agg(
          p.wickets
          order by
            p.wickets desc,
            p.runs_conceded asc
        )
      )[1] as best_wickets,

      (
        array_agg(
          p.runs_conceded
          order by
            p.wickets desc,
            p.runs_conceded asc
        )
      )[1] as best_runs

    from per_player_match p
    group by p.player_key
  )

  select
    t.player_key,
    t.display_name,
    tm.team_name,
    tm.logo_monogram,
    t.is_unclaimed,
    t.wickets,
    t.runs_conceded,
    t.legal_balls,

    case
      when t.legal_balls = 0
        then 0
      else round(
        (t.runs_conceded::numeric * 6)
        / t.legal_balls,
        2
      )
    end,

    t.innings,
    t.best_wickets,
    t.best_runs

  from totals t
  left join public.teams tm
    on tm.team_id = t.team_id

  where t.legal_balls > 0

  order by
    t.wickets desc,
    t.runs_conceded asc,
    t.display_name

  limit greatest(
    coalesce(p_limit, 5),
    1
  );
$$;

revoke all
  on function public.tournament_bowling_leaderboard(
    uuid,
    integer
  )
  from public, anon;

grant execute
  on function public.tournament_bowling_leaderboard(
    uuid,
    integer
  )
  to authenticated;


-- =============================================================================
-- 6. Data-API / RLS contract on the new physical names
-- =============================================================================
--
-- These are renamed existing tables, not new tables, so grants survive the
-- rename. We still state the intended access explicitly:
--
--   public score ledger/state = SELECT
--   all mutations             = server-owned RPC / Edge only
-- =============================================================================

alter table public.cricket_match_innings
  enable row level security;

alter table public.cricket_match_innings_state
  enable row level security;

alter table public.cricket_match_deliveries
  enable row level security;

alter table public.cricket_match_wickets
  enable row level security;


drop policy if exists "match_innings_read_all"
  on public.cricket_match_innings;

drop policy if exists "cricket_match_innings_read_all"
  on public.cricket_match_innings;

create policy "cricket_match_innings_read_all"
  on public.cricket_match_innings
  for select
  to anon, authenticated
  using (true);


drop policy if exists "match_innings_state_read_all"
  on public.cricket_match_innings_state;

drop policy if exists "match_innings_state_write_scorer"
  on public.cricket_match_innings_state;

drop policy if exists "cricket_match_innings_state_read_all"
  on public.cricket_match_innings_state;

create policy "cricket_match_innings_state_read_all"
  on public.cricket_match_innings_state
  for select
  to anon, authenticated
  using (true);


drop policy if exists "match_deliveries_read_all"
  on public.cricket_match_deliveries;

drop policy if exists "match_deliveries_write_scorer"
  on public.cricket_match_deliveries;

drop policy if exists "cricket_match_deliveries_read_all"
  on public.cricket_match_deliveries;

create policy "cricket_match_deliveries_read_all"
  on public.cricket_match_deliveries
  for select
  to anon, authenticated
  using (true);


drop policy if exists "match_wickets_read_all"
  on public.cricket_match_wickets;

drop policy if exists "match_wickets_write_scorer"
  on public.cricket_match_wickets;

drop policy if exists "cricket_match_wickets_read_all"
  on public.cricket_match_wickets;

create policy "cricket_match_wickets_read_all"
  on public.cricket_match_wickets
  for select
  to anon, authenticated
  using (true);


grant select
  on public.cricket_match_innings,
     public.cricket_match_innings_state,
     public.cricket_match_deliveries,
     public.cricket_match_wickets
  to anon, authenticated;

revoke insert, update, delete, truncate
  on public.cricket_match_innings,
     public.cricket_match_innings_state,
     public.cricket_match_deliveries,
     public.cricket_match_wickets
  from anon, authenticated;

grant all
  on public.cricket_match_innings,
     public.cricket_match_innings_state,
     public.cricket_match_deliveries,
     public.cricket_match_wickets
  to service_role;


-- =============================================================================
-- 7. Canonical comments
-- =============================================================================

comment on table public.cricket_match_innings is
  'Cricket innings definition. Structurally owned by cricket_matches.';

comment on table public.cricket_match_innings_state is
  'Cricket live innings hot-state: totals, target and on-field trio.';

comment on table public.cricket_match_deliveries is
  'Authoritative Cricket delivery ledger. All ball-by-ball persistence lives here.';

comment on table public.cricket_match_wickets is
  'Cricket dismissal details attached to cricket_match_deliveries.';


-- =============================================================================
-- 8. Hard internal-cleanliness assertion
-- =============================================================================
--
-- No compatibility relation names are allowed anywhere after the hard cut.
-- Installed PUBLIC FUNCTION BODIES must use only cricket_* physical tables.
-- =============================================================================

do $$
declare
  v_refs text;
begin
  select string_agg(
           p.proname || '(' ||
           pg_get_function_identity_arguments(p.oid) ||
           ')',
           E'\n'
         )
    into v_refs
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.prokind = 'f'
     and (
       position(
         'match_innings_state'
         in pg_get_functiondef(p.oid)
       ) > 0
       or position(
         'match_deliveries'
         in pg_get_functiondef(p.oid)
       ) > 0
       or position(
         'match_wickets'
         in pg_get_functiondef(p.oid)
       ) > 0
       or position(
         'match_innings'
         in pg_get_functiondef(p.oid)
       ) > 0
     )
     -- New canonical names contain the old substrings. Remove canonical names
     -- before testing whether a legacy token remains.
     and (
       position(
         'match_innings_state'
         in replace(
           replace(
             replace(
               replace(
                 pg_get_functiondef(p.oid),
                 'cricket_match_innings_state',
                 ''
               ),
               'cricket_match_deliveries',
               ''
             ),
             'cricket_match_wickets',
             ''
           ),
           'cricket_match_innings',
           ''
         )
       ) > 0
       or position(
         'match_deliveries'
         in replace(
           pg_get_functiondef(p.oid),
           'cricket_match_deliveries',
           ''
         )
       ) > 0
       or position(
         'match_wickets'
         in replace(
           pg_get_functiondef(p.oid),
           'cricket_match_wickets',
           ''
         )
       ) > 0
       or position(
         'match_innings'
         in replace(
           replace(
             pg_get_functiondef(p.oid),
             'cricket_match_innings_state',
             ''
           ),
           'cricket_match_innings',
           ''
         )
       ) > 0
     );

  if v_refs is not null then
    raise exception
      'Phase 3C found installed functions that still depend on legacy engine relation names:%',
      E'\n' || v_refs;
  end if;
end
$$;
