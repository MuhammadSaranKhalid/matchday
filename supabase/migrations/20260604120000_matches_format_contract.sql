-- matches_format_contract — make `matches.format` mandatory + contract-validated.
--
-- Supersedes the permissive posture of 20260531120000_format_relax_constraints:
-- the format blob is now the authoritative source of a match's rules, so it is
--   * NOT NULL with no default (callers MUST supply a complete format), and
--   * gated by a declarative JSON-schema CHECK (pg_jsonschema) requiring the
--     four core keys, with sanity bounds on each.
-- Six typed, indexable generated columns project the core rules out of the blob
-- so queries/indexes don't have to reach into jsonb.
--
-- ⚠️ Blast radius (applied 2026-06-04 via MCP, captured here for parity):
--   * send-match-request edge fn + send_match_request RPC: folded players_per_team
--     into proposed_format (see 20260604120100_match_requests_pps_single_source).
--   * accept_match_request: threads a complete MatchFormat → satisfies this CHECK.
--   * generate_knockout_fixtures / generate_round_robin_fixtures insert `matches`
--     with NO format → they now fail this NOT NULL/CHECK. They are dormant (no
--     app call sites, no tournaments feature yet) and remain UNFIXED — must be
--     updated to thread a complete format before tournaments ship.

-- Declarative JSON validation for jsonb.
create extension if not exists pg_jsonschema with schema extensions;

-- format is now mandatory and must obey the format contract.
alter table public.matches
  alter column format drop default,
  alter column format set not null;

alter table public.matches
  add constraint matches_format_valid check (
    extensions.jsonb_matches_schema(
      '{
        "type": "object",
        "required": ["players_per_team","overs_per_innings","balls_per_over","innings_per_side"],
        "properties": {
          "players_per_team":     {"type":"integer","minimum":2,"maximum":15},
          "overs_per_innings":    {"type":"integer","minimum":1,"maximum":100},
          "balls_per_over":       {"type":"integer","minimum":1,"maximum":10},
          "innings_per_side":     {"type":"integer","minimum":1,"maximum":2},
          "max_overs_per_bowler": {"type":"integer","minimum":1},
          "ball_type":            {"type":"string","enum":["leather","tape","tennis"]}
        },
        "additionalProperties": true
      }',
      format
    )
  );

-- Typed, indexable projections of the core rules, derived from the blob.
alter table public.matches
  add column players_per_team     smallint generated always as ((format->>'players_per_team')::smallint)     stored,
  add column overs_per_innings    smallint generated always as ((format->>'overs_per_innings')::smallint)    stored,
  add column balls_per_over       smallint generated always as ((format->>'balls_per_over')::smallint)       stored,
  add column max_overs_per_bowler smallint generated always as ((format->>'max_overs_per_bowler')::smallint) stored,
  add column innings_per_side     smallint generated always as ((format->>'innings_per_side')::smallint)     stored,
  add column ball_type            text     generated always as (format->>'ball_type')                        stored;
