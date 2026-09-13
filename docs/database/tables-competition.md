# Tournaments and venues: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## grounds

Reusable venue identity and geographic/search information.

Canonical declaration: [20260101000330_grounds.sql](../../supabase/migrations/20260101000330_grounds.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| ground_id | uuid | False | gen_random_uuid() |
| name | text | False | — |
| location | jsonb | False | '{}'::jsonb |
| location_point | geography(Point,4326) | True | GENERATED: <br>CASE<br>    WHEN ((location ? 'lat'::text) AND (location ? 'lng'::text)) THEN (st_setsrid(st_makepoint(((location ->> 'lng'::text))::double precision, ((location ->> 'lat'::text))::double precision), 4326))::geography<br>    ELSE NULL::geography<br>END |
| surface | ground_surface | True | — |
| has_floodlights | boolean | False | false |
| notes | text | True | — |
| search_name | text | True | GENERATED: lower(f_unaccent(name)) |
| created_by | uuid | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| grounds_created_by_fkey | FOREIGN KEY (created_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| grounds_name_check | CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 80) | False / False |
| grounds_notes_check | CHECK (notes IS NULL OR length(notes) <= 300) | False / False |
| grounds_pkey | PRIMARY KEY (ground_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| grounds_city | CREATE INDEX grounds_city ON public.grounds USING btree (((location ->> 'city'::text))) |
| grounds_created_by | CREATE INDEX grounds_created_by ON public.grounds USING btree (created_by) |
| grounds_location_point | CREATE INDEX grounds_location_point ON public.grounds USING gist (location_point) |
| grounds_pkey | CREATE UNIQUE INDEX grounds_pkey ON public.grounds USING btree (ground_id) |
| grounds_search_trgm | CREATE INDEX grounds_search_trgm ON public.grounds USING gin (search_name gin_trgm_ops) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| grounds_delete_creator | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = created_by) | — |
| grounds_insert_authenticated | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = created_by) |
| grounds_read_public | SELECT | ["anon", "authenticated"] | true | — |
| grounds_update_creator | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = created_by) | (( SELECT auth.uid() AS uid) = created_by) |

### Triggers

| Name | Definition |
| --- | --- |
| grounds_set_updated_at | CREATE TRIGGER grounds_set_updated_at BEFORE UPDATE ON grounds FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## tournaments

Competition configuration and lifecycle. Organizer authority still uses the tournament-specific model.

Canonical declaration: [20260101000300_tournaments.sql](../../supabase/migrations/20260101000300_tournaments.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| tournament_id | uuid | False | gen_random_uuid() |
| tournament_name | text | False | — |
| tournament_type | tournament_type | False | — |
| banner_image_url | text | True | — |
| logo_url | text | True | — |
| description | text | True | — |
| format | jsonb | False | '{}'::jsonb |
| rules | jsonb | False | '{}'::jsonb |
| start_date | date | True | — |
| end_date | date | True | — |
| registration_deadline | date | True | — |
| location | jsonb | False | '{}'::jsonb |
| location_point | geography(Point,4326) | True | GENERATED: <br>CASE<br>    WHEN ((location ? 'lat'::text) AND (location ? 'lng'::text)) THEN (st_setsrid(st_makepoint(((location ->> 'lng'::text))::double precision, ((location ->> 'lat'::text))::double precision), 4326))::geography<br>    ELSE NULL::geography<br>END |
| venues | jsonb | False | '[]'::jsonb |
| prize_details | text | True | — |
| entry_fee | numeric(10,2) | True | — |
| max_teams | integer | True | — |
| min_teams | integer | True | — |
| created_by | uuid | True | — |
| organizers | uuid[] | False | '{}'::uuid[] |
| status | tournament_status | False | 'draft'::tournament_status |
| privacy | tournament_privacy | False | 'public'::tournament_privacy |
| awards | jsonb | False | '{}'::jsonb |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| deadline_before_start | CHECK (registration_deadline IS NULL OR start_date IS NULL OR registration_deadline <= start_date) | False / False |
| end_after_start | CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date) | False / False |
| min_le_max_teams | CHECK (min_teams IS NULL OR max_teams IS NULL OR min_teams <= max_teams) | False / False |
| tournaments_created_by_fkey | FOREIGN KEY (created_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| tournaments_description_check | CHECK (description IS NULL OR length(description) <= 1000) | False / False |
| tournaments_entry_fee_check | CHECK (entry_fee IS NULL OR entry_fee >= 0::numeric) | False / False |
| tournaments_max_teams_check | CHECK (max_teams IS NULL OR max_teams >= 2 AND max_teams <= 256) | False / False |
| tournaments_min_teams_check | CHECK (min_teams IS NULL OR min_teams >= 2) | False / False |
| tournaments_pkey | PRIMARY KEY (tournament_id) | False / False |
| tournaments_prize_details_check | CHECK (prize_details IS NULL OR length(prize_details) <= 500) | False / False |
| tournaments_tournament_name_check | CHECK (length(tournament_name) >= 3 AND length(tournament_name) <= 100) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| tournaments_city | CREATE INDEX tournaments_city ON public.tournaments USING btree (((location ->> 'city'::text))) |
| tournaments_creator | CREATE INDEX tournaments_creator ON public.tournaments USING btree (created_by) |
| tournaments_location_point | CREATE INDEX tournaments_location_point ON public.tournaments USING gist (location_point) |
| tournaments_name_trgm | CREATE INDEX tournaments_name_trgm ON public.tournaments USING gin (tournament_name gin_trgm_ops) |
| tournaments_organizers_gin | CREATE INDEX tournaments_organizers_gin ON public.tournaments USING gin (organizers) |
| tournaments_pkey | CREATE UNIQUE INDEX tournaments_pkey ON public.tournaments USING btree (tournament_id) |
| tournaments_start_date | CREATE INDEX tournaments_start_date ON public.tournaments USING btree (start_date) |
| tournaments_status | CREATE INDEX tournaments_status ON public.tournaments USING btree (status) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| tournaments_delete_creator | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = created_by) | — |
| tournaments_insert_self_creator | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = created_by) |
| tournaments_read_visible | SELECT | ["anon", "authenticated"] | ((privacy = 'public'::tournament_privacy) OR (( SELECT auth.uid() AS uid) = created_by) OR (( SELECT auth.uid() AS uid) = ANY (organizers))) | — |
| tournaments_update_organizers | UPDATE | ["authenticated"] | ((( SELECT auth.uid() AS uid) = created_by) OR (( SELECT auth.uid() AS uid) = ANY (organizers))) | ((( SELECT auth.uid() AS uid) = created_by) OR (( SELECT auth.uid() AS uid) = ANY (organizers))) |

### Triggers

| Name | Definition |
| --- | --- |
| tournaments_cleanup_follows | CREATE TRIGGER tournaments_cleanup_follows AFTER DELETE ON tournaments FOR EACH ROW EXECUTE FUNCTION cleanup_follows_on_entity_delete() |
| tournaments_set_updated_at | CREATE TRIGGER tournaments_set_updated_at BEFORE UPDATE ON tournaments FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## tournament_grounds

Links a tournament to its allowed venues.

Canonical declaration: [20260101000331_tournament_grounds.sql](../../supabase/migrations/20260101000331_tournament_grounds.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| tournament_id | uuid | False | — |
| ground_id | uuid | False | — |
| sort_order | integer | False | 0 |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| tournament_grounds_ground_id_fkey | FOREIGN KEY (ground_id) REFERENCES grounds(ground_id) ON DELETE RESTRICT | False / False |
| tournament_grounds_pkey | PRIMARY KEY (tournament_id, ground_id) | False / False |
| tournament_grounds_tournament_id_fkey | FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| tournament_grounds_ground | CREATE INDEX tournament_grounds_ground ON public.tournament_grounds USING btree (ground_id) |
| tournament_grounds_pkey | CREATE UNIQUE INDEX tournament_grounds_pkey ON public.tournament_grounds USING btree (tournament_id, ground_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| tournament_grounds_read | SELECT | ["anon", "authenticated"] | (is_tournament_organizer(tournament_id) OR (EXISTS ( SELECT 1<br>   FROM tournaments t<br>  WHERE ((t.tournament_id = tournament_grounds.tournament_id) AND (t.privacy = 'public'::tournament_privacy))))) | — |
| tournament_grounds_write_organizer | ALL | ["authenticated"] | is_tournament_organizer(tournament_id) | is_tournament_organizer(tournament_id) |

### Triggers

No non-system triggers attached.

## tournament_teams

Registration/participation of a team in a tournament, including group and decision information.

Canonical declaration: [20260101000310_tournament_teams.sql](../../supabase/migrations/20260101000310_tournament_teams.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| registration_id | uuid | False | gen_random_uuid() |
| tournament_id | uuid | False | — |
| team_id | uuid | False | — |
| registered_by | uuid | True | — |
| registered_at | timestamp with time zone | False | now() |
| status | tournament_registration_status | False | 'pending'::tournament_registration_status |
| squad | uuid[] | False | '{}'::uuid[] |
| seed_number | integer | True | — |
| group_id | text | True | — |
| payment_status | text | True | — |
| decided_by | uuid | True | — |
| decided_at | timestamp with time zone | True | — |
| message | text | True | — |
| decision_reason | text | True | — |
| amount_paid | numeric(12,2) | False | 0 |
| payment_channel | text | True | — |
| payment_reference | text | True | — |
| payment_recorded_at | timestamp with time zone | True | — |
| payment_recorded_by | uuid | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

- **amount_paid:** Cumulative fee received for this registration, in the tournament currency. Partial payments are allowed: the ledger (artboard 24c) shows amount_paid against tournaments.entry_fee.

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| registration_decision_consistency | CHECK ((status = ANY (ARRAY['pending'::tournament_registration_status, 'withdrawn'::tournament_registration_status])) OR (status = ANY (ARRAY['approved'::tournament_registration_status, 'rejected'::tournament_registration_status])) AND decided_at IS NOT NULL) | False / False |
| tournament_teams_amount_paid_check | CHECK (amount_paid >= 0::numeric) | False / False |
| tournament_teams_decided_by_fkey | FOREIGN KEY (decided_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| tournament_teams_decision_reason_check | CHECK (decision_reason IS NULL OR length(decision_reason) <= 500) | False / False |
| tournament_teams_message_check | CHECK (message IS NULL OR length(message) <= 500) | False / False |
| tournament_teams_payment_channel_check | CHECK (payment_channel IS NULL OR (payment_channel = ANY (ARRAY['cash'::text, 'jazzcash'::text, 'easypaisa'::text, 'bank_transfer'::text, 'other'::text]))) | False / False |
| tournament_teams_payment_recorded_by_fkey | FOREIGN KEY (payment_recorded_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| tournament_teams_payment_reference_check | CHECK (payment_reference IS NULL OR length(payment_reference) <= 200) | False / False |
| tournament_teams_pkey | PRIMARY KEY (registration_id) | False / False |
| tournament_teams_registered_by_fkey | FOREIGN KEY (registered_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| tournament_teams_seed_number_check | CHECK (seed_number IS NULL OR seed_number >= 1) | False / False |
| tournament_teams_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| tournament_teams_tournament_id_fkey | FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE | False / False |
| tournament_teams_unique | UNIQUE (tournament_id, team_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_tournament_teams_decided_by | CREATE INDEX idx_tournament_teams_decided_by ON public.tournament_teams USING btree (decided_by) |
| idx_tournament_teams_payment_recorded_by | CREATE INDEX idx_tournament_teams_payment_recorded_by ON public.tournament_teams USING btree (payment_recorded_by) |
| idx_tournament_teams_registered_by | CREATE INDEX idx_tournament_teams_registered_by ON public.tournament_teams USING btree (registered_by) |
| tournament_teams_pkey | CREATE UNIQUE INDEX tournament_teams_pkey ON public.tournament_teams USING btree (registration_id) |
| tournament_teams_squad_gin | CREATE INDEX tournament_teams_squad_gin ON public.tournament_teams USING gin (squad) |
| tournament_teams_status | CREATE INDEX tournament_teams_status ON public.tournament_teams USING btree (tournament_id, status) |
| tournament_teams_team | CREATE INDEX tournament_teams_team ON public.tournament_teams USING btree (team_id) |
| tournament_teams_tournament | CREATE INDEX tournament_teams_tournament ON public.tournament_teams USING btree (tournament_id) |
| tournament_teams_unique | CREATE UNIQUE INDEX tournament_teams_unique ON public.tournament_teams USING btree (tournament_id, team_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| tournament_teams_insert_manager | INSERT | ["authenticated"] | — | (is_team_manager(team_id) AND (( SELECT auth.uid() AS uid) = registered_by) AND (EXISTS ( SELECT 1<br>   FROM tournaments t<br>  WHERE ((t.tournament_id = tournament_teams.tournament_id) AND (t.status = ANY (ARRAY['registration'::tournament_status, 'draft'::tournament_status])))))) |
| tournament_teams_read | SELECT | ["anon", "authenticated"] | (is_tournament_organizer(tournament_id) OR is_team_manager(team_id) OR (EXISTS ( SELECT 1<br>   FROM tournaments t<br>  WHERE ((t.tournament_id = tournament_teams.tournament_id) AND (t.privacy = 'public'::tournament_privacy))))) | — |
| tournament_teams_update_manager_or_organizer | UPDATE | ["authenticated"] | (is_team_manager(team_id) OR is_tournament_organizer(tournament_id)) | (is_team_manager(team_id) OR is_tournament_organizer(tournament_id)) |

### Triggers

| Name | Definition |
| --- | --- |
| tournament_teams_set_updated_at | CREATE TRIGGER tournament_teams_set_updated_at BEFORE UPDATE ON tournament_teams FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## tournament_standings

Persisted competition standings updated by result-processing workflows.

Canonical declaration: [20260101000320_tournament_standings.sql](../../supabase/migrations/20260101000320_tournament_standings.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| tournament_id | uuid | False | — |
| team_id | uuid | False | — |
| group_id | text | True | — |
| matches_played | integer | False | 0 |
| wins | integer | False | 0 |
| losses | integer | False | 0 |
| ties | integer | False | 0 |
| no_results | integer | False | 0 |
| points | integer | False | 0 |
| runs_scored | integer | False | 0 |
| overs_faced | numeric(6,2) | False | 0 |
| runs_conceded | integer | False | 0 |
| overs_bowled | numeric(6,2) | False | 0 |
| net_run_rate | numeric(6,3) | False | 0 |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| tournament_standings_pkey | PRIMARY KEY (tournament_id, team_id) | False / False |
| tournament_standings_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| tournament_standings_tournament_id_fkey | FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| tournament_standings_pkey | CREATE UNIQUE INDEX tournament_standings_pkey ON public.tournament_standings USING btree (tournament_id, team_id) |
| tournament_standings_team | CREATE INDEX tournament_standings_team ON public.tournament_standings USING btree (team_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| tournament_standings_no_direct_write | ALL | ["authenticated"] | false | false |
| tournament_standings_read_public | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

| Name | Definition |
| --- | --- |
| tournament_standings_broadcast | CREATE TRIGGER tournament_standings_broadcast AFTER INSERT OR DELETE OR UPDATE ON tournament_standings FOR EACH ROW EXECUTE FUNCTION broadcast_standings_change() |
| tournament_standings_set_updated_at | CREATE TRIGGER tournament_standings_set_updated_at BEFORE UPDATE ON tournament_standings FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## match_format_presets

Reusable format settings. A match stores its own format snapshot.

Canonical declaration: [20260101000340_match_format_presets.sql](../../supabase/migrations/20260101000340_match_format_presets.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| id | text | False | — |
| label | text | False | — |
| sort_order | integer | False | 0 |
| config | jsonb | False | — |
| is_active | boolean | False | true |
| is_system | boolean | False | false |
| created_by | uuid | True | — |
| default_scoring_mode | scoring_mode | False | 'live_ball_by_ball'::scoring_mode |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| match_format_presets_created_by_fkey | FOREIGN KEY (created_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| match_format_presets_pkey | PRIMARY KEY (id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_match_format_presets_active_order | CREATE INDEX idx_match_format_presets_active_order ON public.match_format_presets USING btree (sort_order) WHERE is_active |
| idx_match_format_presets_created_by | CREATE INDEX idx_match_format_presets_created_by ON public.match_format_presets USING btree (created_by) |
| match_format_presets_pkey | CREATE UNIQUE INDEX match_format_presets_pkey ON public.match_format_presets USING btree (id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| match_format_presets_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.
