-- Backend format catalog: format_presets.
--
-- The single source of truth for selectable match formats. The setup picker
-- reads it; a chosen format is SNAPSHOTTED into matches.format at creation (the
-- scoring engine only ever reads that snapshot). `config` is open-shape jsonb
-- with optional + defaulted keys, so new format fields are purely additive —
-- old rows and old match snapshots keep working unchanged (append-only
-- evolution; no config version needed).

create table public.format_presets (
  id                   text primary key,             -- 't20', 'odi', ...
  label                text not null,
  sort_order           integer not null default 0,
  config               jsonb not null,               -- the engine knobs (open shape)
  is_active            boolean not null default true, -- rollout gate
  is_system            boolean not null default false,-- canonical vs user-saved
  created_by           uuid references auth.users on delete cascade, -- null = system
  default_scoring_mode public.scoring_mode not null default 'live_ball_by_ball',
  created_at           timestamptz not null default now()
);

create index format_presets_active on public.format_presets (sort_order)
  where is_active;

-- ── validate_format: the canonical format-config validator ──────────────────
-- Runs on the WRITE path only (catalog upserts via the trigger; match creation
-- via the match-request RPCs). NEVER run against old snapshots — reads stay
-- tolerant (the engine defaults absent keys).
create or replace function public.validate_format(p_config jsonb)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_overs   int  := coalesce((p_config->>'overs_per_innings')::int, 0);
  v_players int  := coalesce((p_config->>'players_per_team')::int, 11);
  v_bpo     int  := coalesce((p_config->>'balls_per_over')::int, 6);
  v_cap     int  := coalesce((p_config->>'max_overs_per_bowler')::int, 0);
  v_inns    int  := coalesce((p_config->>'innings_per_side')::int, 1);
  v_dismiss text := p_config->>'dismissal_model';
  v_tie     text := p_config->>'tie_breaker';
begin
  if v_overs < 0 then
    raise exception 'overs_per_innings must be >= 0' using errcode = '23514';
  end if;
  if v_players < 2 then
    raise exception 'players_per_team must be >= 2' using errcode = '23514';
  end if;
  if v_bpo not in (5, 6, 8) then
    raise exception 'balls_per_over must be 5, 6 or 8' using errcode = '23514';
  end if;
  if v_overs > 0 and v_cap > 0 and v_cap > v_overs then
    raise exception 'max_overs_per_bowler cannot exceed overs_per_innings'
      using errcode = '23514';
  end if;
  if v_inns not in (1, 2) then
    raise exception 'innings_per_side must be 1 or 2' using errcode = '23514';
  end if;
  -- co-dependencies (forward-compat for the bespoke formats)
  if v_dismiss = 'pairs' and (p_config->>'dismissal_penalty') is null then
    raise exception 'dismissal_model=pairs requires dismissal_penalty'
      using errcode = '23514';
  end if;
  if v_tie = 'super_over' and (p_config->>'super_over_wickets') is null then
    raise exception 'tie_breaker=super_over requires super_over_wickets'
      using errcode = '23514';
  end if;
end;
$$;

grant execute on function public.validate_format(jsonb) to anon, authenticated;

create or replace function public._format_presets_validate()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  perform public.validate_format(new.config);
  return new;
end;
$$;

create trigger format_presets_validate
  before insert or update on public.format_presets
  for each row execute function public._format_presets_validate();

-- ── RLS ─────────────────────────────────────────────────────────────────────
-- Public read of active rows + a user's own rows; users manage only their own.
-- System rows (created_by null) are migration-only (no client policy matches).
alter table public.format_presets enable row level security;

create policy "format presets readable when active or owned"
  on public.format_presets for select
  using (is_active or created_by = auth.uid());

create policy "users manage their own format presets"
  on public.format_presets for all
  using (created_by = auth.uid())
  with check (created_by = auth.uid());

grant select on public.format_presets to anon, authenticated;
grant insert, update, delete on public.format_presets to authenticated;

-- ── Seed the 8 config-only system formats ───────────────────────────────────
insert into public.format_presets
  (id, label, sort_order, is_system, default_scoring_mode, config)
values
 ('t20',     'T20',         1, true, 'live_ball_by_ball',
   '{"overs_per_innings":20,"players_per_team":11,"max_overs_per_bowler":4}'),
 ('t10',     'T10',         2, true, 'live_ball_by_ball',
   '{"overs_per_innings":10,"players_per_team":11,"max_overs_per_bowler":2}'),
 ('odi',     'ODI',         3, true, 'live_ball_by_ball',
   '{"overs_per_innings":50,"players_per_team":11,"max_overs_per_bowler":10}'),
 ('list_a',  'List A',      4, true, 'live_ball_by_ball',
   '{"overs_per_innings":50,"players_per_team":11,"max_overs_per_bowler":10}'),
 ('hundred', 'The Hundred', 5, true, 'live_ball_by_ball',
   '{"overs_per_innings":20,"players_per_team":11,"max_overs_per_bowler":4,"balls_per_over":5,"end_change_balls":10}'),
 ('super8',  '8-a-side',    6, true, 'live_ball_by_ball',
   '{"overs_per_innings":20,"players_per_team":8,"max_overs_per_bowler":4}'),
 ('tape',    'Tape-ball',   7, true, 'live_ball_by_ball',
   '{"overs_per_innings":20,"players_per_team":11,"max_overs_per_bowler":4,"ball_type":"tape"}'),
 ('box',     'Box cricket', 8, true, 'post_match_scorecard',
   '{"overs_per_innings":6,"players_per_team":8,"max_overs_per_bowler":2}')
on conflict (id) do update set
  label                = excluded.label,
  sort_order           = excluded.sort_order,
  is_system            = excluded.is_system,
  default_scoring_mode = excluded.default_scoring_mode,
  config               = excluded.config;

-- ── Validate format on the friendly-challenge write path ────────────────────
-- The picker → challenge flow writes proposed/countered_format into
-- match_requests; accept_match_request later snapshots the chosen one into
-- matches.format. Validating here (rather than rewriting the large RPC bodies)
-- means the snapshot the engine eventually reads is always well-formed. Empty
-- '{}' (inherit / not-yet-set) is allowed through.
create or replace function public._validate_request_format()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.proposed_format is not null and new.proposed_format <> '{}'::jsonb then
    perform public.validate_format(new.proposed_format);
  end if;
  if new.countered_format is not null and new.countered_format <> '{}'::jsonb then
    perform public.validate_format(new.countered_format);
  end if;
  return new;
end;
$$;

create trigger match_requests_validate_format
  before insert or update on public.match_requests
  for each row execute function public._validate_request_format();
