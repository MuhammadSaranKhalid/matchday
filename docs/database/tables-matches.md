# Matches and scoring: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## matches

Fixture, sides, start/toss phase, format snapshot and authoritative match result.

Canonical declaration: [20260101000400_matches.sql](../../supabase/migrations/20260101000400_matches.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| match_id | uuid | False | gen_random_uuid() |
| tournament_id | uuid | True | — |
| match_type | match_type | False | 'friendly'::match_type |
| match_format | match_format | False | 't20'::match_format |
| stage | match_stage | True | — |
| round | text | True | — |
| bracket_round_number | integer | True | — |
| bracket_match_number | integer | True | — |
| prev_match_a_id | uuid | True | — |
| prev_match_b_id | uuid | True | — |
| group_id | text | True | — |
| venue | text | True | — |
| ground_id | uuid | True | — |
| scheduled_start_time | timestamp with time zone | False | now() |
| actual_start_time | timestamp with time zone | True | — |
| completed_at | timestamp with time zone | True | — |
| format | jsonb | False | _normalize_match_format('{}'::jsonb) |
| toss_won_by | uuid | True | — |
| toss_decision | toss_decision | True | — |
| toss_face | character(1) | True | — |
| toss_recorded_at | timestamp with time zone | True | — |
| start_phase | match_start_phase | False | 'toss'::match_start_phase |
| openers_submitted_by | uuid | True | — |
| openers_submitted_at | timestamp with time zone | True | — |
| scoring_mode | scoring_mode | False | 'live_ball_by_ball'::scoring_mode |
| status | match_status | False | 'scheduled'::match_status |
| result | jsonb | True | — |
| result_summary | jsonb | True | — |
| winner_id | uuid | True | — |
| revised_conditions | jsonb | True | — |
| player_of_the_match_id | uuid | True | — |
| team_a_id | uuid | True | — |
| team_b_id | uuid | True | — |
| team_a_captain | uuid | True | — |
| team_b_captain | uuid | True | — |
| created_by | uuid | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

- **venue:** Free-text ground name, NULL when unknown. Retained for casual matches with no registered ground. Tournament fixtures should set ground_id and mirror the name here for display.

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| matches_bracket_match_number_check | CHECK (bracket_match_number IS NULL OR bracket_match_number >= 1) | False / False |
| matches_bracket_round_number_check | CHECK (bracket_round_number IS NULL OR bracket_round_number >= 1) | False / False |
| matches_created_by_fkey | FOREIGN KEY (created_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| matches_ground_id_fkey | FOREIGN KEY (ground_id) REFERENCES grounds(ground_id) ON DELETE SET NULL | False / False |
| matches_openers_submitted_by_fkey | FOREIGN KEY (openers_submitted_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| matches_pkey | PRIMARY KEY (match_id) | False / False |
| matches_player_of_the_match_fkey | FOREIGN KEY (player_of_the_match_id) REFERENCES match_players(match_player_id) ON DELETE SET NULL | False / False |
| matches_prev_match_a_id_fkey | FOREIGN KEY (prev_match_a_id) REFERENCES matches(match_id) ON DELETE SET NULL | False / False |
| matches_prev_match_b_id_fkey | FOREIGN KEY (prev_match_b_id) REFERENCES matches(match_id) ON DELETE SET NULL | False / False |
| matches_team_a_captain_fkey | FOREIGN KEY (team_a_captain) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| matches_team_a_id_fkey | FOREIGN KEY (team_a_id) REFERENCES teams(team_id) ON DELETE SET NULL | False / False |
| matches_team_b_captain_fkey | FOREIGN KEY (team_b_captain) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| matches_team_b_id_fkey | FOREIGN KEY (team_b_id) REFERENCES teams(team_id) ON DELETE SET NULL | False / False |
| matches_toss_face_check | CHECK (toss_face IS NULL OR (toss_face = ANY (ARRAY['H'::bpchar, 'T'::bpchar]))) | False / False |
| matches_toss_won_by_fkey | FOREIGN KEY (toss_won_by) REFERENCES teams(team_id) ON DELETE SET NULL | False / False |
| matches_tournament_id_fkey | FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE SET NULL | False / False |
| matches_winner_id_fkey | FOREIGN KEY (winner_id) REFERENCES teams(team_id) ON DELETE SET NULL | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_matches_created_by | CREATE INDEX idx_matches_created_by ON public.matches USING btree (created_by) |
| idx_matches_openers_submitted_by | CREATE INDEX idx_matches_openers_submitted_by ON public.matches USING btree (openers_submitted_by) |
| idx_matches_player_of_the_match_id | CREATE INDEX idx_matches_player_of_the_match_id ON public.matches USING btree (player_of_the_match_id) |
| idx_matches_prev_match_a_id | CREATE INDEX idx_matches_prev_match_a_id ON public.matches USING btree (prev_match_a_id) |
| idx_matches_prev_match_b_id | CREATE INDEX idx_matches_prev_match_b_id ON public.matches USING btree (prev_match_b_id) |
| idx_matches_status_time | CREATE INDEX idx_matches_status_time ON public.matches USING btree (status, scheduled_start_time DESC) |
| idx_matches_team_a | CREATE INDEX idx_matches_team_a ON public.matches USING btree (team_a_id) WHERE (team_a_id IS NOT NULL) |
| idx_matches_team_a_captain | CREATE INDEX idx_matches_team_a_captain ON public.matches USING btree (team_a_captain) |
| idx_matches_team_b | CREATE INDEX idx_matches_team_b ON public.matches USING btree (team_b_id) WHERE (team_b_id IS NOT NULL) |
| idx_matches_team_b_captain | CREATE INDEX idx_matches_team_b_captain ON public.matches USING btree (team_b_captain) |
| idx_matches_toss_won_by | CREATE INDEX idx_matches_toss_won_by ON public.matches USING btree (toss_won_by) |
| idx_matches_tournament | CREATE INDEX idx_matches_tournament ON public.matches USING btree (tournament_id) WHERE (tournament_id IS NOT NULL) |
| idx_matches_tournament_winner | CREATE INDEX idx_matches_tournament_winner ON public.matches USING btree (tournament_id, winner_id) WHERE (tournament_id IS NOT NULL) |
| idx_matches_winner_id | CREATE INDEX idx_matches_winner_id ON public.matches USING btree (winner_id) |
| matches_ground_time | CREATE INDEX matches_ground_time ON public.matches USING btree (ground_id, scheduled_start_time) WHERE (ground_id IS NOT NULL) |
| matches_pkey | CREATE UNIQUE INDEX matches_pkey ON public.matches USING btree (match_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| matches_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

| Name | Definition |
| --- | --- |
| match_advance_tournament_bracket | CREATE TRIGGER match_advance_tournament_bracket AFTER UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION trg_advance_tournament_bracket() |
| match_sync_winner_id | CREATE TRIGGER match_sync_winner_id BEFORE INSERT OR UPDATE OF result ON matches FOR EACH ROW EXECUTE FUNCTION trg_sync_match_winner_id() |
| matches_fill_captains | CREATE TRIGGER matches_fill_captains BEFORE INSERT OR UPDATE OF team_a_id, team_b_id ON matches FOR EACH ROW EXECUTE FUNCTION _fill_match_captains() |
| trg_broadcast_match_state | CREATE TRIGGER trg_broadcast_match_state AFTER UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION broadcast_match_state_updated() |

## match_teams

Per-match side records; separate from reusable team identity.

Canonical declaration: [20260101000402_match_teams.sql](../../supabase/migrations/20260101000402_match_teams.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| match_id | uuid | False | — |
| team_id | uuid | True | — |
| team_name | text | False | — |
| team_side | text | False | — |
| is_batting_first | boolean | True | — |
| captain_player_id | uuid | True | — |
| keeper_player_id | uuid | True | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_teams_captain_player_fkey | FOREIGN KEY (captain_player_id) REFERENCES match_players(match_player_id) ON DELETE SET NULL | False / False |
| match_teams_keeper_player_fkey | FOREIGN KEY (keeper_player_id) REFERENCES match_players(match_player_id) ON DELETE SET NULL | False / False |
| match_teams_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_teams_pkey | PRIMARY KEY (match_id, team_side) | False / False |
| match_teams_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE SET NULL | False / False |
| match_teams_team_side_check | CHECK (team_side = ANY (ARRAY['team_a'::text, 'team_b'::text])) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_teams_captain_player_id | CREATE INDEX idx_match_teams_captain_player_id ON public.match_teams USING btree (captain_player_id) |
| idx_match_teams_keeper_player_id | CREATE INDEX idx_match_teams_keeper_player_id ON public.match_teams USING btree (keeper_player_id) |
| idx_match_teams_team_id | CREATE INDEX idx_match_teams_team_id ON public.match_teams USING btree (team_id) |
| match_teams_pkey | CREATE UNIQUE INDEX match_teams_pkey ON public.match_teams USING btree (match_id, team_side) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_teams_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## match_players

Per-match lineup identities used by delivery and wicket references.

Canonical declaration: [20260101000401_match_players.sql](../../supabase/migrations/20260101000401_match_players.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| match_player_id | uuid | False | gen_random_uuid() |
| match_id | uuid | False | — |
| team_side | text | False | — |
| user_id | uuid | True | — |
| unclaimed_id | uuid | True | — |
| display_name | text | False | — |
| jersey_number | smallint | True | — |
| role | match_role | False | 'player'::match_role |
| is_in_playing_xi | boolean | False | true |
| batting_order | smallint | True | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| chk_match_player_identity | CHECK (num_nonnulls(user_id, unclaimed_id) = 1) | False / False |
| match_players_batting_order_check | CHECK (batting_order IS NULL OR batting_order >= 1 AND batting_order <= 15) | False / False |
| match_players_jersey_number_check | CHECK (jersey_number IS NULL OR jersey_number >= 0 AND jersey_number <= 99) | False / False |
| match_players_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_players_match_id_unclaimed_id_key | UNIQUE (match_id, unclaimed_id) | False / False |
| match_players_match_id_user_id_key | UNIQUE (match_id, user_id) | False / False |
| match_players_pkey | PRIMARY KEY (match_player_id) | False / False |
| match_players_team_side_check | CHECK (team_side = ANY (ARRAY['team_a'::text, 'team_b'::text])) | False / False |
| match_players_unclaimed_id_fkey | FOREIGN KEY (unclaimed_id) REFERENCES unclaimed_players(unclaimed_id) ON DELETE SET NULL | False / False |
| match_players_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_players_match | CREATE INDEX idx_match_players_match ON public.match_players USING btree (match_id) |
| idx_match_players_unclaimed | CREATE INDEX idx_match_players_unclaimed ON public.match_players USING btree (unclaimed_id) WHERE (unclaimed_id IS NOT NULL) |
| idx_match_players_user | CREATE INDEX idx_match_players_user ON public.match_players USING btree (user_id) WHERE (user_id IS NOT NULL) |
| match_players_match_id_unclaimed_id_key | CREATE UNIQUE INDEX match_players_match_id_unclaimed_id_key ON public.match_players USING btree (match_id, unclaimed_id) |
| match_players_match_id_user_id_key | CREATE UNIQUE INDEX match_players_match_id_user_id_key ON public.match_players USING btree (match_id, user_id) |
| match_players_pkey | CREATE UNIQUE INDEX match_players_pkey ON public.match_players USING btree (match_player_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_players_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## match_innings

Innings identity and lifecycle for a match.

Canonical declaration: [20260101000403_match_innings.sql](../../supabase/migrations/20260101000403_match_innings.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| innings_id | uuid | False | gen_random_uuid() |
| match_id | uuid | False | — |
| innings_number | smallint | False | — |
| batting_team_side | text | False | — |
| bowling_team_side | text | False | — |
| overs_allocated | numeric(4,1) | False | 20.0 |
| is_completed | boolean | False | false |
| start_time | timestamp with time zone | True | now() |
| end_time | timestamp with time zone | True | — |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_innings_batting_team_side_check | CHECK (batting_team_side = ANY (ARRAY['team_a'::text, 'team_b'::text])) | False / False |
| match_innings_bowling_team_side_check | CHECK (bowling_team_side = ANY (ARRAY['team_a'::text, 'team_b'::text])) | False / False |
| match_innings_innings_id_match_id_innings_number_key | UNIQUE (innings_id, match_id, innings_number) | False / False |
| match_innings_innings_number_check | CHECK (innings_number >= 1 AND innings_number <= 4) | False / False |
| match_innings_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_innings_match_id_innings_number_key | UNIQUE (match_id, innings_number) | False / False |
| match_innings_pkey | PRIMARY KEY (innings_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_innings_match | CREATE INDEX idx_innings_match ON public.match_innings USING btree (match_id) |
| match_innings_innings_id_match_id_innings_number_key | CREATE UNIQUE INDEX match_innings_innings_id_match_id_innings_number_key ON public.match_innings USING btree (innings_id, match_id, innings_number) |
| match_innings_match_id_innings_number_key | CREATE UNIQUE INDEX match_innings_match_id_innings_number_key ON public.match_innings USING btree (match_id, innings_number) |
| match_innings_pkey | CREATE UNIQUE INDEX match_innings_pkey ON public.match_innings USING btree (innings_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_innings_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## match_innings_state

Hot innings snapshot, totals, batters/bowler and versioning, separate from fixture metadata.

Canonical declaration: [20260101000404_match_innings_state.sql](../../supabase/migrations/20260101000404_match_innings_state.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| innings_id | uuid | False | — |
| match_id | uuid | False | — |
| innings_number | smallint | False | 1 |
| striker_id | uuid | True | — |
| non_striker_id | uuid | True | — |
| bowler_id | uuid | True | — |
| total_runs | integer | False | 0 |
| total_wickets | smallint | False | 0 |
| legal_ball_count | integer | False | 0 |
| total_wides | integer | False | 0 |
| total_no_balls | integer | False | 0 |
| total_byes | integer | False | 0 |
| total_leg_byes | integer | False | 0 |
| total_penalties | integer | False | 0 |
| total_extras | integer | False | GENERATED: ((((total_wides + total_no_balls) + total_byes) + total_leg_byes) + total_penalties) |
| is_declared | boolean | False | false |
| is_all_out | boolean | False | false |
| target | integer | True | — |
| is_free_hit_next | boolean | False | false |
| version | bigint | False | 0 |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| chk_state_distinct_batters | CHECK (striker_id IS NULL OR non_striker_id IS NULL OR striker_id <> non_striker_id) | False / False |
| match_innings_state_bowler_id_fkey | FOREIGN KEY (bowler_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_innings_state_innings_id_fkey | FOREIGN KEY (innings_id) REFERENCES match_innings(innings_id) ON DELETE CASCADE | False / False |
| match_innings_state_innings_number_check | CHECK (innings_number >= 1 AND innings_number <= 4) | False / False |
| match_innings_state_legal_ball_count_check | CHECK (legal_ball_count >= 0) | False / False |
| match_innings_state_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_innings_state_non_striker_id_fkey | FOREIGN KEY (non_striker_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_innings_state_parent_fkey | FOREIGN KEY (innings_id, match_id, innings_number) REFERENCES match_innings(innings_id, match_id, innings_number) ON DELETE CASCADE | False / False |
| match_innings_state_pkey | PRIMARY KEY (innings_id) | False / False |
| match_innings_state_striker_id_fkey | FOREIGN KEY (striker_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_innings_state_target_check | CHECK (target IS NULL OR target > 0) | False / False |
| match_innings_state_total_byes_check | CHECK (total_byes >= 0) | False / False |
| match_innings_state_total_leg_byes_check | CHECK (total_leg_byes >= 0) | False / False |
| match_innings_state_total_no_balls_check | CHECK (total_no_balls >= 0) | False / False |
| match_innings_state_total_penalties_check | CHECK (total_penalties >= 0) | False / False |
| match_innings_state_total_runs_check | CHECK (total_runs >= 0) | False / False |
| match_innings_state_total_wickets_check | CHECK (total_wickets >= 0 AND total_wickets <= 11) | False / False |
| match_innings_state_total_wides_check | CHECK (total_wides >= 0) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_innings_state_match | CREATE INDEX idx_innings_state_match ON public.match_innings_state USING btree (match_id) |
| idx_match_innings_state_bowler_id | CREATE INDEX idx_match_innings_state_bowler_id ON public.match_innings_state USING btree (bowler_id) |
| idx_match_innings_state_non_striker_id | CREATE INDEX idx_match_innings_state_non_striker_id ON public.match_innings_state USING btree (non_striker_id) |
| idx_match_innings_state_striker_id | CREATE INDEX idx_match_innings_state_striker_id ON public.match_innings_state USING btree (striker_id) |
| match_innings_state_pkey | CREATE UNIQUE INDEX match_innings_state_pkey ON public.match_innings_state USING btree (innings_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_innings_state_read_all | SELECT | ["anon", "authenticated"] | true | — |
| match_innings_state_write_scorer | UPDATE | ["authenticated"] | false | — |

### Triggers

| Name | Definition |
| --- | --- |
| trg_broadcast_innings_state | CREATE TRIGGER trg_broadcast_innings_state AFTER INSERT OR UPDATE ON match_innings_state FOR EACH ROW EXECUTE FUNCTION broadcast_innings_state_updated() |

## match_deliveries

Ordered persisted scoring deliveries. Last-delivery undo is an intentional exception to append-oriented storage.

Canonical declaration: [20260101000405_match_deliveries.sql](../../supabase/migrations/20260101000405_match_deliveries.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| delivery_id | uuid | False | gen_random_uuid() |
| innings_id | uuid | False | — |
| match_id | uuid | False | — |
| innings_number | integer | False | 1 |
| seq | integer | False | — |
| over_number | integer | False | — |
| ball_in_over | smallint | False | — |
| is_legal_delivery | boolean | False | — |
| delivery_type | delivery_kind | False | 'legal'::delivery_kind |
| runs_off_bat | smallint | False | 0 |
| extra_runs | smallint | False | 0 |
| total_runs | smallint | False | GENERATED: (runs_off_bat + extra_runs) |
| is_boundary | boolean | False | false |
| is_four | boolean | False | false |
| is_six | boolean | False | false |
| is_free_hit | boolean | False | false |
| is_wicket | boolean | False | false |
| wicket_type | wicket_kind | True | — |
| striker_id | uuid | True | — |
| non_striker_id | uuid | True | — |
| bowler_id | uuid | True | — |
| fielder_id | uuid | True | — |
| pitch_x | numeric(5,2) | True | — |
| pitch_y | numeric(5,2) | True | — |
| shot_angle | numeric(5,2) | True | — |
| shot_distance | numeric(5,2) | True | — |
| shot_type | text | True | — |
| idempotency_key | text | False | — |
| is_undone | boolean | False | false |
| commentary | text | True | — |
| recorded_by | uuid | True | — |
| recorded_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| chk_delivery_ball_in_over | CHECK (is_legal_delivery AND ball_in_over >= 1 OR NOT is_legal_delivery AND ball_in_over = 0) | False / False |
| chk_delivery_type_legality | CHECK (<br>CASE delivery_type<br>    WHEN 'wide'::delivery_kind THEN is_legal_delivery = false<br>    WHEN 'no_ball'::delivery_kind THEN is_legal_delivery = false<br>    WHEN 'legal'::delivery_kind THEN is_legal_delivery = true<br>    WHEN 'bye'::delivery_kind THEN is_legal_delivery = true<br>    WHEN 'leg_bye'::delivery_kind THEN is_legal_delivery = true<br>    ELSE true<br>END) | False / False |
| match_deliveries_ball_in_over_check | CHECK (ball_in_over >= 0) | False / False |
| match_deliveries_bowler_id_fkey | FOREIGN KEY (bowler_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_deliveries_extra_runs_check | CHECK (extra_runs >= 0 AND extra_runs <= 10) | False / False |
| match_deliveries_fielder_id_fkey | FOREIGN KEY (fielder_id) REFERENCES match_players(match_player_id) ON DELETE SET NULL | False / False |
| match_deliveries_innings_id_fkey | FOREIGN KEY (innings_id) REFERENCES match_innings(innings_id) ON DELETE CASCADE | False / False |
| match_deliveries_innings_id_idempotency_key_key | UNIQUE (innings_id, idempotency_key) | False / False |
| match_deliveries_innings_id_seq_key | UNIQUE (innings_id, seq) | False / False |
| match_deliveries_innings_number_check | CHECK (innings_number >= 1 AND innings_number <= 4) | False / False |
| match_deliveries_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_deliveries_non_striker_id_fkey | FOREIGN KEY (non_striker_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_deliveries_over_number_check | CHECK (over_number >= 0) | False / False |
| match_deliveries_pkey | PRIMARY KEY (delivery_id) | False / False |
| match_deliveries_recorded_by_fkey | FOREIGN KEY (recorded_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| match_deliveries_runs_off_bat_check | CHECK (runs_off_bat >= 0 AND runs_off_bat <= 7) | False / False |
| match_deliveries_seq_check | CHECK (seq >= 1) | False / False |
| match_deliveries_striker_id_fkey | FOREIGN KEY (striker_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_deliveries_bowler | CREATE INDEX idx_deliveries_bowler ON public.match_deliveries USING btree (bowler_id) WHERE (bowler_id IS NOT NULL) |
| idx_deliveries_match | CREATE INDEX idx_deliveries_match ON public.match_deliveries USING btree (match_id) |
| idx_deliveries_striker | CREATE INDEX idx_deliveries_striker ON public.match_deliveries USING btree (striker_id) WHERE (striker_id IS NOT NULL) |
| idx_match_deliveries_fielder_id | CREATE INDEX idx_match_deliveries_fielder_id ON public.match_deliveries USING btree (fielder_id) |
| idx_match_deliveries_non_striker_id | CREATE INDEX idx_match_deliveries_non_striker_id ON public.match_deliveries USING btree (non_striker_id) |
| idx_match_deliveries_recorded_by | CREATE INDEX idx_match_deliveries_recorded_by ON public.match_deliveries USING btree (recorded_by) |
| match_deliveries_innings_id_idempotency_key_key | CREATE UNIQUE INDEX match_deliveries_innings_id_idempotency_key_key ON public.match_deliveries USING btree (innings_id, idempotency_key) |
| match_deliveries_innings_id_seq_key | CREATE UNIQUE INDEX match_deliveries_innings_id_seq_key ON public.match_deliveries USING btree (innings_id, seq) |
| match_deliveries_pkey | CREATE UNIQUE INDEX match_deliveries_pkey ON public.match_deliveries USING btree (delivery_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_deliveries_read_all | SELECT | ["anon", "authenticated"] | true | — |
| match_deliveries_write_scorer | INSERT | ["authenticated"] | — | false |

### Triggers

| Name | Definition |
| --- | --- |
| trg_broadcast_delivery | CREATE TRIGGER trg_broadcast_delivery AFTER INSERT ON match_deliveries FOR EACH ROW EXECUTE FUNCTION broadcast_new_delivery() |
| trg_broadcast_delivery_deleted | CREATE TRIGGER trg_broadcast_delivery_deleted AFTER DELETE ON match_deliveries FOR EACH ROW EXECUTE FUNCTION broadcast_delivery_deleted() |

## match_wickets

Dismissal detail associated with deliveries and match players.

Canonical declaration: [20260101000406_match_wickets.sql](../../supabase/migrations/20260101000406_match_wickets.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| wicket_id | uuid | False | gen_random_uuid() |
| delivery_id | uuid | False | — |
| innings_id | uuid | False | — |
| player_out_id | uuid | False | — |
| dismissal_kind | wicket_kind | False | — |
| is_bowler_credited | boolean | False | true |
| credited_bowler_id | uuid | True | — |
| primary_fielder_id | uuid | True | — |
| assisted_fielder_id | uuid | True | — |
| fall_of_wicket_score | integer | False | — |
| fall_of_wicket_number | smallint | False | — |
| fall_of_wicket_overs | numeric(4,1) | False | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_wickets_assisted_fielder_id_fkey | FOREIGN KEY (assisted_fielder_id) REFERENCES match_players(match_player_id) ON DELETE SET NULL | False / False |
| match_wickets_credited_bowler_id_fkey | FOREIGN KEY (credited_bowler_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_wickets_delivery_id_fkey | FOREIGN KEY (delivery_id) REFERENCES match_deliveries(delivery_id) ON DELETE CASCADE | False / False |
| match_wickets_delivery_id_key | UNIQUE (delivery_id) | False / False |
| match_wickets_fall_of_wicket_number_check | CHECK (fall_of_wicket_number >= 1 AND fall_of_wicket_number <= 11) | False / False |
| match_wickets_innings_id_fkey | FOREIGN KEY (innings_id) REFERENCES match_innings(innings_id) ON DELETE CASCADE | False / False |
| match_wickets_pkey | PRIMARY KEY (wicket_id) | False / False |
| match_wickets_player_out_id_fkey | FOREIGN KEY (player_out_id) REFERENCES match_players(match_player_id) ON DELETE RESTRICT | False / False |
| match_wickets_primary_fielder_id_fkey | FOREIGN KEY (primary_fielder_id) REFERENCES match_players(match_player_id) ON DELETE SET NULL | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_wickets_assisted_fielder_id | CREATE INDEX idx_match_wickets_assisted_fielder_id ON public.match_wickets USING btree (assisted_fielder_id) |
| idx_match_wickets_credited_bowler_id | CREATE INDEX idx_match_wickets_credited_bowler_id ON public.match_wickets USING btree (credited_bowler_id) |
| idx_match_wickets_player_out_id | CREATE INDEX idx_match_wickets_player_out_id ON public.match_wickets USING btree (player_out_id) |
| idx_match_wickets_primary_fielder_id | CREATE INDEX idx_match_wickets_primary_fielder_id ON public.match_wickets USING btree (primary_fielder_id) |
| idx_wickets_innings | CREATE INDEX idx_wickets_innings ON public.match_wickets USING btree (innings_id) |
| match_wickets_delivery_id_key | CREATE UNIQUE INDEX match_wickets_delivery_id_key ON public.match_wickets USING btree (delivery_id) |
| match_wickets_pkey | CREATE UNIQUE INDEX match_wickets_pkey ON public.match_wickets USING btree (wicket_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_wickets_read_all | SELECT | ["anon", "authenticated"] | true | — |
| match_wickets_write_scorer | INSERT | ["authenticated"] | — | false |

### Triggers

No non-system triggers attached.

## match_officials

Match-level official assignments; scorer authorization is mirrored into scoped grants.

Canonical declaration: [20260101000410_match_officials.sql](../../supabase/migrations/20260101000410_match_officials.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| match_id | uuid | False | — |
| user_id | uuid | False | — |
| role | text | False | — |
| assigned_at | timestamp with time zone | False | now() |
| assigned_by | uuid | True | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_officials_assigned_by_fkey | FOREIGN KEY (assigned_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| match_officials_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_officials_pkey | PRIMARY KEY (match_id, user_id, role) | False / False |
| match_officials_role_check | CHECK (role = ANY (ARRAY['scorer'::text, 'umpire_main'::text, 'umpire_leg'::text, 'umpire_third'::text, 'referee'::text])) | False / False |
| match_officials_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_officials_assigned_by | CREATE INDEX idx_match_officials_assigned_by ON public.match_officials USING btree (assigned_by) |
| match_officials_pkey | CREATE UNIQUE INDEX match_officials_pkey ON public.match_officials USING btree (match_id, user_id, role) |
| match_officials_user | CREATE INDEX match_officials_user ON public.match_officials USING btree (user_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_officials_read | SELECT | ["authenticated"] | true | — |
| match_officials_write_organizers | ALL | ["authenticated"] | (EXISTS ( SELECT 1<br>   FROM matches m<br>  WHERE ((m.match_id = match_officials.match_id) AND<br>        CASE<br>            WHEN (m.tournament_id IS NOT NULL) THEN is_tournament_organizer(m.tournament_id)<br>            ELSE (is_team_captain(m.team_a_id) OR is_team_captain(m.team_b_id))<br>        END))) | ((EXISTS ( SELECT 1<br>   FROM matches m<br>  WHERE ((m.match_id = match_officials.match_id) AND<br>        CASE<br>            WHEN (m.tournament_id IS NOT NULL) THEN is_tournament_organizer(m.tournament_id)<br>            ELSE (is_team_captain(m.team_a_id) OR is_team_captain(m.team_b_id))<br>        END))) AND ((role = 'scorer'::text) OR (EXISTS ( SELECT 1<br>   FROM matches m<br>  WHERE ((m.match_id = match_officials.match_id) AND (m.tournament_id IS NOT NULL)))))) |

### Triggers

| Name | Definition |
| --- | --- |
| match_officials_mirror_scorer | CREATE TRIGGER match_officials_mirror_scorer AFTER INSERT OR DELETE OR UPDATE ON match_officials FOR EACH ROW EXECUTE FUNCTION mirror_scorer_grant() |

## match_scorer_leases

Scorer lease state declared by the schema. Do not infer universal enforcement from the table alone.

Canonical declaration: [20260101000407_match_scorer_leases.sql](../../supabase/migrations/20260101000407_match_scorer_leases.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| match_id | uuid | False | — |
| active_scorer_id | uuid | False | — |
| device_id | text | False | — |
| lease_acquired_at | timestamp with time zone | False | now() |
| lease_expires_at | timestamp with time zone | False | (now() + '00:05:00'::interval) |
| heartbeat_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_scorer_leases_active_scorer_id_fkey | FOREIGN KEY (active_scorer_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| match_scorer_leases_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_scorer_leases_pkey | PRIMARY KEY (match_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_scorer_leases_active_scorer_id | CREATE INDEX idx_match_scorer_leases_active_scorer_id ON public.match_scorer_leases USING btree (active_scorer_id) |
| match_scorer_leases_pkey | CREATE UNIQUE INDEX match_scorer_leases_pkey ON public.match_scorer_leases USING btree (match_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_scorer_leases_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## match_result_history

Recorded result history, distinct from the current result on matches.

Canonical declaration: [20260101000408_match_result_history.sql](../../supabase/migrations/20260101000408_match_result_history.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| history_id | uuid | False | gen_random_uuid() |
| match_id | uuid | False | — |
| previous_status | match_status | False | — |
| new_status | match_status | False | — |
| result_payload | jsonb | False | — |
| reason | text | True | — |
| recorded_by | uuid | True | — |
| recorded_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_result_history_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| match_result_history_pkey | PRIMARY KEY (history_id) | False / False |
| match_result_history_recorded_by_fkey | FOREIGN KEY (recorded_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_result_history_recorded_by | CREATE INDEX idx_match_result_history_recorded_by ON public.match_result_history USING btree (recorded_by) |
| idx_result_history_match | CREATE INDEX idx_result_history_match ON public.match_result_history USING btree (match_id, recorded_at DESC) |
| match_result_history_pkey | CREATE UNIQUE INDEX match_result_history_pkey ON public.match_result_history USING btree (history_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_result_history_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## match_challenges

Direct/open friendly-match proposals, counteroffers, lineup choices and decision timers.

Canonical declaration: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| request_id | uuid | False | gen_random_uuid() |
| from_team_id | uuid | False | — |
| to_team_id | uuid | True | — |
| requested_by | uuid | True | — |
| proposed_start_time | timestamp with time zone | True | — |
| proposed_venue | text | True | — |
| proposed_format | jsonb | False | '{}'::jsonb |
| message | text | True | — |
| players_per_side | smallint | True | GENERATED: ((proposed_format ->> 'players_per_team'::text))::smallint |
| from_team_xi | uuid[] | False | '{}'::uuid[] |
| from_team_keeper_id | uuid | True | — |
| countered_start_time | timestamp with time zone | True | — |
| countered_venue | text | True | — |
| countered_format | jsonb | True | — |
| countered_players_per_side | integer | True | — |
| status | match_request_status | False | 'pending'::match_request_status |
| decided_by | uuid | True | — |
| decided_at | timestamp with time zone | True | — |
| decision_note | text | True | — |
| decision_reason | decline_reason | True | — |
| match_id | uuid | True | — |
| share_code | text | True | — |
| code_expires_at | timestamp with time zone | True | — |
| proposal_expires_at | timestamp with time zone | True | — |
| counter_expires_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_challenges_countered_players_per_side_check | CHECK (countered_players_per_side IS NULL OR countered_players_per_side >= 5 AND countered_players_per_side <= 15) | False / False |
| match_challenges_decided_by_fkey | FOREIGN KEY (decided_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| match_challenges_decision_consistency | CHECK (status = 'pending'::match_request_status AND decided_by IS NULL AND decided_at IS NULL AND match_id IS NULL OR status = 'countered'::match_request_status AND decided_by IS NOT NULL AND decided_at IS NOT NULL AND match_id IS NULL OR (status = ANY (ARRAY['declined'::match_request_status, 'cancelled'::match_request_status, 'expired'::match_request_status])) AND (status = 'expired'::match_request_status OR decided_by IS NOT NULL) AND decided_at IS NOT NULL AND match_id IS NULL OR status = 'accepted'::match_request_status AND decided_by IS NOT NULL AND decided_at IS NOT NULL AND match_id IS NOT NULL) | False / False |
| match_challenges_decision_note_check | CHECK (decision_note IS NULL OR length(decision_note) <= 500) | False / False |
| match_challenges_distinct_teams | CHECK (from_team_id IS NULL OR to_team_id IS NULL OR from_team_id <> to_team_id) | False / False |
| match_challenges_from_team_id_fkey | FOREIGN KEY (from_team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| match_challenges_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE SET NULL | False / False |
| match_challenges_message_check | CHECK (message IS NULL OR length(message) <= 500) | False / False |
| match_challenges_pkey | PRIMARY KEY (request_id) | False / False |
| match_challenges_proposed_ppt_valid | CHECK (proposed_format ? 'players_per_team'::text AND ((proposed_format ->> 'players_per_team'::text)::integer) >= 5 AND ((proposed_format ->> 'players_per_team'::text)::integer) <= 15) | False / False |
| match_challenges_requested_by_fkey | FOREIGN KEY (requested_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| match_challenges_to_team_id_fkey | FOREIGN KEY (to_team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_challenges_decided_by | CREATE INDEX idx_match_challenges_decided_by ON public.match_challenges USING btree (decided_by) |
| idx_match_challenges_match_id | CREATE INDEX idx_match_challenges_match_id ON public.match_challenges USING btree (match_id) |
| match_challenges_active_code | CREATE UNIQUE INDEX match_challenges_active_code ON public.match_challenges USING btree (share_code) WHERE ((status = ANY (ARRAY['pending'::match_request_status, 'countered'::match_request_status])) AND (share_code IS NOT NULL)) |
| match_challenges_from_team_status | CREATE INDEX match_challenges_from_team_status ON public.match_challenges USING btree (from_team_id, status, created_at DESC) |
| match_challenges_pkey | CREATE UNIQUE INDEX match_challenges_pkey ON public.match_challenges USING btree (request_id) |
| match_challenges_requested_by | CREATE INDEX match_challenges_requested_by ON public.match_challenges USING btree (requested_by) |
| match_challenges_to_team_status | CREATE INDEX match_challenges_to_team_status ON public.match_challenges USING btree (to_team_id, status, created_at DESC) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_challenges_no_direct_delete | DELETE | ["authenticated"] | false | — |
| match_challenges_no_direct_insert | INSERT | ["authenticated"] | — | false |
| match_challenges_no_direct_update | UPDATE | ["authenticated"] | false | false |
| match_challenges_read_team_managers | SELECT | ["anon", "authenticated"] | (is_team_manager(from_team_id) OR ((to_team_id IS NOT NULL) AND is_team_manager(to_team_id)) OR ((to_team_id IS NULL) AND (status = 'pending'::match_request_status))) | — |

### Triggers

| Name | Definition |
| --- | --- |
| match_challenges_notify_decision | CREATE TRIGGER match_challenges_notify_decision AFTER UPDATE OF status ON match_challenges FOR EACH ROW EXECUTE FUNCTION notify_on_match_request_decision() |
| match_challenges_notify_insert | CREATE TRIGGER match_challenges_notify_insert AFTER INSERT ON match_challenges FOR EACH ROW EXECUTE FUNCTION notify_on_match_request_insert() |
| match_challenges_set_updated_at | CREATE TRIGGER match_challenges_set_updated_at BEFORE UPDATE ON match_challenges FOR EACH ROW EXECUTE FUNCTION set_updated_at() |
| match_challenges_validate_keeper | CREATE TRIGGER match_challenges_validate_keeper BEFORE INSERT OR UPDATE OF from_team_keeper_id, from_team_xi, from_team_id ON match_challenges FOR EACH ROW EXECUTE FUNCTION _validate_match_request_keeper() |

## match_pool_applications

Teams applying to an open match; selected through application-decision RPCs.

Canonical declaration: [20260817090000_match_pool_applications.sql](../../supabase/migrations/20260817090000_match_pool_applications.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| application_id | uuid | False | gen_random_uuid() |
| request_id | uuid | False | — |
| applicant_team_id | uuid | False | — |
| applicant_user_id | uuid | False | — |
| applicant_xi | uuid[] | True | '{}'::uuid[] |
| applicant_keeper_id | uuid | True | — |
| message | text | True | — |
| status | text | False | 'pending'::text |
| decision_note | text | True | — |
| decided_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_pool_applications_applicant_team_id_fkey | FOREIGN KEY (applicant_team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| match_pool_applications_applicant_user_id_fkey | FOREIGN KEY (applicant_user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| match_pool_applications_pkey | PRIMARY KEY (application_id) | False / False |
| match_pool_applications_request_id_fkey | FOREIGN KEY (request_id) REFERENCES match_challenges(request_id) ON DELETE CASCADE | False / False |
| match_pool_applications_status_check | CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text, 'withdrawn'::text])) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_pool_applications_applicant_user_id | CREATE INDEX idx_match_pool_applications_applicant_user_id ON public.match_pool_applications USING btree (applicant_user_id) |
| idx_match_pool_apps_applicant_team | CREATE INDEX idx_match_pool_apps_applicant_team ON public.match_pool_applications USING btree (applicant_team_id) |
| idx_match_pool_apps_request | CREATE INDEX idx_match_pool_apps_request ON public.match_pool_applications USING btree (request_id) |
| idx_match_pool_apps_status | CREATE INDEX idx_match_pool_apps_status ON public.match_pool_applications USING btree (status) |
| match_pool_applications_pkey | CREATE UNIQUE INDEX match_pool_applications_pkey ON public.match_pool_applications USING btree (application_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_pool_apps_select | SELECT | ["authenticated"] | (is_team_manager(applicant_team_id) OR (EXISTS ( SELECT 1<br>   FROM match_challenges mr<br>  WHERE ((mr.request_id = match_pool_applications.request_id) AND is_team_manager(mr.from_team_id))))) | — |

### Triggers

No non-system triggers attached.
