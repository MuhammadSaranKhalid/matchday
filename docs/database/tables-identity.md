# Identity and teams: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## profiles

Public-facing account identity linked to auth.users; onboarding, discoverability and account lifecycle.

Canonical declaration: [20260101000100_profiles.sql](../../supabase/migrations/20260101000100_profiles.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| user_id | uuid | False | — |
| username | text | True | — |
| display_name | text | False | — |
| profile_photo_url | text | True | — |
| cover_photo_url | text | True | — |
| date_of_birth | date | True | — |
| gender | user_gender | True | — |
| bio | text | True | — |
| location | jsonb | False | '{}'::jsonb |
| location_point | geography(Point,4326) | True | GENERATED: <br>CASE<br>    WHEN ((location ? 'lat'::text) AND (location ? 'lng'::text)) THEN (st_setsrid(st_makepoint(((location ->> 'lng'::text))::double precision, ((location ->> 'lat'::text))::double precision), 4326))::geography<br>    ELSE NULL::geography<br>END |
| discoverability | jsonb | False | jsonb_build_object('appear_in_rankings', true, 'appear_in_search', true, 'appear_in_suggestions', true, 'show_location_publicly', true) |
| is_verified | boolean | False | false |
| account_status | account_status | False | 'active'::account_status |
| username_changed_at | timestamp with time zone | True | — |
| onboarded_at | timestamp with time zone | True | — |
| last_active_at | timestamp with time zone | False | now() |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |
| search_name | text | True | GENERATED: lower(f_unaccent(((COALESCE(display_name, ''::text) \|\| ' '::text) \|\| COALESCE(username, ''::text)))) |

- **location:** jsonb with keys: country, province, city, area, lat, lng. lat/lng optional.

- **username_changed_at:** Username cannot be changed for 30 days after this timestamp (spec §1.7).

- **onboarded_at:** Stamped when the user finishes onboarding (welcome step). NULL = onboarding incomplete; router will redirect to /onboarding.

- **search_name:** Normalised (lower + accent-folded) "display_name username" for trigram search. Generated — never write to it directly.

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| profiles_bio_check | CHECK (bio IS NULL OR length(bio) <= 200) | False / False |
| profiles_display_name_check | CHECK (length(display_name) >= 1 AND length(display_name) <= 80) | False / False |
| profiles_pkey | PRIMARY KEY (user_id) | False / False |
| profiles_user_id_fkey | FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE | False / False |
| profiles_username_check | CHECK (username IS NULL OR username ~ '^[a-z0-9_]{3,20}$'::text) | False / False |
| profiles_username_key | UNIQUE (username) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| profiles_city | CREATE INDEX profiles_city ON public.profiles USING btree (((location ->> 'city'::text))) |
| profiles_last_active | CREATE INDEX profiles_last_active ON public.profiles USING btree (last_active_at DESC) |
| profiles_location_point | CREATE INDEX profiles_location_point ON public.profiles USING gist (location_point) |
| profiles_pkey | CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (user_id) |
| profiles_search_trgm | CREATE INDEX profiles_search_trgm ON public.profiles USING gin (search_name gin_trgm_ops) WHERE ((account_status = 'active'::account_status) AND COALESCE(((discoverability ->> 'appear_in_search'::text))::boolean, true)) |
| profiles_username_key | CREATE UNIQUE INDEX profiles_username_key ON public.profiles USING btree (username) |
| profiles_username_trgm | CREATE INDEX profiles_username_trgm ON public.profiles USING gin (username gin_trgm_ops) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| profiles_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| profiles_read_public | SELECT | ["anon", "authenticated"] | (account_status = 'active'::account_status) | — |
| profiles_update_self | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | (( SELECT auth.uid() AS uid) = user_id) |

### Triggers

| Name | Definition |
| --- | --- |
| profiles_cleanup_follows | CREATE TRIGGER profiles_cleanup_follows AFTER DELETE ON profiles FOR EACH ROW EXECUTE FUNCTION cleanup_follows_on_entity_delete() |
| profiles_enforce_username_cooldown | CREATE TRIGGER profiles_enforce_username_cooldown BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION enforce_username_cooldown() |
| profiles_set_updated_at | CREATE TRIGGER profiles_set_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at() |
| profiles_strip_from_arrays | CREATE TRIGGER profiles_strip_from_arrays BEFORE DELETE ON profiles FOR EACH ROW EXECUTE FUNCTION _strip_deleted_profile_from_arrays() |

## player_profiles

Cricket-specific profile information attached to an account.

Canonical declaration: [20260101000110_player_profiles.sql](../../supabase/migrations/20260101000110_player_profiles.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| user_id | uuid | False | — |
| batting_style | batting_style | True | — |
| bowling_style | bowling_style | True | — |
| player_role | player_role | True | — |
| preferred_ball_types | ball_type[] | False | '{}'::ball_type[] |
| years_playing | integer | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| player_profiles_pkey | PRIMARY KEY (user_id) | False / False |
| player_profiles_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| player_profiles_years_playing_check | CHECK (years_playing IS NULL OR years_playing >= 0 AND years_playing <= 80) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| player_profiles_pkey | CREATE UNIQUE INDEX player_profiles_pkey ON public.player_profiles USING btree (user_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| player_profiles_read_public | SELECT | ["anon", "authenticated"] | true | — |
| player_profiles_write_self | ALL | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | (( SELECT auth.uid() AS uid) = user_id) |

### Triggers

| Name | Definition |
| --- | --- |
| player_profiles_set_updated_at | CREATE TRIGGER player_profiles_set_updated_at BEFORE UPDATE ON player_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## unclaimed_players

Players represented before they have an account; claiming links them to a registered identity.

Canonical declaration: [20260101000120_unclaimed_players.sql](../../supabase/migrations/20260101000120_unclaimed_players.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| unclaimed_id | uuid | False | gen_random_uuid() |
| display_name | text | False | — |
| phone_number | text | True | — |
| email | text | True | — |
| player_profile | jsonb | False | '{}'::jsonb |
| added_by | uuid | True | — |
| claimed_by_user_id | uuid | True | — |
| claimed_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |
| search_name | text | True | GENERATED: lower(f_unaccent(COALESCE(display_name, ''::text))) |

- **search_name:** Normalised display_name for trigram search. Generated — never write directly.

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| claim_consistency | CHECK (claimed_by_user_id IS NULL AND claimed_at IS NULL OR claimed_by_user_id IS NOT NULL AND claimed_at IS NOT NULL) | False / False |
| unclaimed_players_added_by_fkey | FOREIGN KEY (added_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| unclaimed_players_claimed_by_user_id_fkey | FOREIGN KEY (claimed_by_user_id) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| unclaimed_players_display_name_check | CHECK (length(display_name) >= 1 AND length(display_name) <= 80) | False / False |
| unclaimed_players_pkey | PRIMARY KEY (unclaimed_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| unclaimed_players_added_by | CREATE INDEX unclaimed_players_added_by ON public.unclaimed_players USING btree (added_by) |
| unclaimed_players_claimed | CREATE INDEX unclaimed_players_claimed ON public.unclaimed_players USING btree (claimed_by_user_id) WHERE (claimed_by_user_id IS NOT NULL) |
| unclaimed_players_email | CREATE INDEX unclaimed_players_email ON public.unclaimed_players USING btree (email) WHERE (email IS NOT NULL) |
| unclaimed_players_one_claim | CREATE UNIQUE INDEX unclaimed_players_one_claim ON public.unclaimed_players USING btree (unclaimed_id) WHERE (claimed_by_user_id IS NOT NULL) |
| unclaimed_players_phone | CREATE INDEX unclaimed_players_phone ON public.unclaimed_players USING btree (phone_number) WHERE (phone_number IS NOT NULL) |
| unclaimed_players_pkey | CREATE UNIQUE INDEX unclaimed_players_pkey ON public.unclaimed_players USING btree (unclaimed_id) |
| unclaimed_players_search_trgm | CREATE INDEX unclaimed_players_search_trgm ON public.unclaimed_players USING gin (search_name gin_trgm_ops) WHERE (claimed_by_user_id IS NULL) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | False | False | False | False | True | True | True |
| authenticated | False | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

Column-only grants (not implied by table-wide access):

| Role | Column | Privilege |
| --- | --- | --- |
| anon | added_by | SELECT |
| anon | claimed_at | SELECT |
| anon | claimed_by_user_id | SELECT |
| anon | created_at | SELECT |
| anon | display_name | SELECT |
| anon | player_profile | SELECT |
| anon | search_name | SELECT |
| anon | unclaimed_id | SELECT |
| anon | updated_at | SELECT |
| authenticated | added_by | SELECT |
| authenticated | claimed_at | SELECT |
| authenticated | claimed_by_user_id | SELECT |
| authenticated | created_at | SELECT |
| authenticated | display_name | SELECT |
| authenticated | player_profile | SELECT |
| authenticated | search_name | SELECT |
| authenticated | unclaimed_id | SELECT |
| authenticated | updated_at | SELECT |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| unclaimed_players_delete_owner | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = added_by) | — |
| unclaimed_players_insert_authed | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = added_by) |
| unclaimed_players_read_public | SELECT | ["anon", "authenticated"] | true | — |
| unclaimed_players_update_owner | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = added_by) | (( SELECT auth.uid() AS uid) = added_by) |

### Triggers

| Name | Definition |
| --- | --- |
| unclaimed_players_normalize_claim | CREATE TRIGGER unclaimed_players_normalize_claim BEFORE UPDATE ON unclaimed_players FOR EACH ROW EXECUTE FUNCTION normalize_unclaimed_claim_timestamp() |
| unclaimed_players_set_updated_at | CREATE TRIGGER unclaimed_players_set_updated_at BEFORE UPDATE ON unclaimed_players FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## teams

Team identity, presentation and configuration. created_by records history; ownership is a role assignment.

Canonical declaration: [20260101000200_teams.sql](../../supabase/migrations/20260101000200_teams.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| team_id | uuid | False | gen_random_uuid() |
| team_name | text | False | — |
| team_type | team_type | False | — |
| tagline | text | True | — |
| logo_url | text | True | — |
| logo_monogram | text | True | — |
| team_colors | jsonb | True | — |
| description | text | True | — |
| home_ground | text | True | — |
| location | jsonb | False | '{}'::jsonb |
| location_point | geography(Point,4326) | True | GENERATED: <br>CASE<br>    WHEN ((location ? 'lat'::text) AND (location ? 'lng'::text)) THEN (st_setsrid(st_makepoint(((location ->> 'lng'::text))::double precision, ((location ->> 'lat'::text))::double precision), 4326))::geography<br>    ELSE NULL::geography<br>END |
| founded_year | integer | True | — |
| created_by | uuid | True | — |
| is_verified | boolean | False | false |
| privacy | team_privacy | False | 'public'::team_privacy |
| status | team_status | False | 'active'::team_status |
| max_squad_size | integer | False | 25 |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |
| search_name | text | True | GENERATED: lower(f_unaccent(team_name)) |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| teams_created_by_fkey | FOREIGN KEY (created_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| teams_description_check | CHECK (description IS NULL OR length(description) <= 500) | False / False |
| teams_founded_year_check | CHECK (founded_year IS NULL OR founded_year >= 1700 AND founded_year <= (date_part('year'::text, now())::integer + 1)) | False / False |
| teams_logo_monogram_check | CHECK (logo_monogram IS NULL OR length(logo_monogram) >= 1 AND length(logo_monogram) <= 3) | False / False |
| teams_max_squad_size_check | CHECK (max_squad_size >= 11 AND max_squad_size <= 50) | False / False |
| teams_pkey | PRIMARY KEY (team_id) | False / False |
| teams_tagline_check | CHECK (tagline IS NULL OR length(tagline) <= 60) | False / False |
| teams_team_name_check | CHECK (length(team_name) >= 3 AND length(team_name) <= 50) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| teams_city | CREATE INDEX teams_city ON public.teams USING btree (((location ->> 'city'::text))) |
| teams_created_by | CREATE INDEX teams_created_by ON public.teams USING btree (created_by) |
| teams_location_point | CREATE INDEX teams_location_point ON public.teams USING gist (location_point) |
| teams_name_trgm | CREATE INDEX teams_name_trgm ON public.teams USING gin (team_name gin_trgm_ops) |
| teams_pkey | CREATE UNIQUE INDEX teams_pkey ON public.teams USING btree (team_id) |
| teams_search_trgm | CREATE INDEX teams_search_trgm ON public.teams USING gin (search_name gin_trgm_ops) WHERE ((status = 'active'::team_status) AND (privacy = 'public'::team_privacy)) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| teams_delete_owner | DELETE | ["authenticated"] | ( SELECT team_can(teams.team_id, 'team.disband'::text) AS team_can) | — |
| teams_insert_self_owner | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = created_by) |
| teams_read_public | SELECT | ["anon", "authenticated"] | true | — |
| teams_update_managers | UPDATE | ["authenticated"] | ( SELECT team_can(teams.team_id, 'team.profile.write'::text) AS team_can) | ( SELECT team_can(teams.team_id, 'team.profile.write'::text) AS team_can) |

### Triggers

| Name | Definition |
| --- | --- |
| teams_after_insert_create_chat | CREATE TRIGGER teams_after_insert_create_chat AFTER INSERT ON teams FOR EACH ROW EXECUTE FUNCTION create_team_chat() |
| teams_cleanup_follows | CREATE TRIGGER teams_cleanup_follows AFTER DELETE ON teams FOR EACH ROW EXECUTE FUNCTION cleanup_follows_on_entity_delete() |
| teams_create_owner_membership | CREATE TRIGGER teams_create_owner_membership AFTER INSERT ON teams FOR EACH ROW EXECUTE FUNCTION create_owner_membership() |
| teams_set_updated_at | CREATE TRIGGER teams_set_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## team_members

A person’s membership in a team, pointing to a registered or unclaimed player.

Canonical declaration: [20260101000210_team_members.sql](../../supabase/migrations/20260101000210_team_members.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| membership_id | uuid | False | gen_random_uuid() |
| team_id | uuid | False | — |
| user_id | uuid | True | — |
| unclaimed_id | uuid | True | — |
| jersey_number | integer | True | — |
| in_squad | boolean | False | true |
| joined_at | timestamp with time zone | False | now() |
| left_at | timestamp with time zone | True | — |
| status | member_status | False | 'active'::member_status |
| is_primary | boolean | False | false |
| added_by | uuid | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| left_at_for_inactive | CHECK (status = 'active'::member_status AND left_at IS NULL OR (status = ANY (ARRAY['inactive'::member_status, 'removed'::member_status])) AND left_at IS NOT NULL) | False / False |
| player_ref_xor | CHECK (num_nonnulls(user_id, unclaimed_id) = 1) | False / False |
| team_members_added_by_fkey | FOREIGN KEY (added_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| team_members_jersey_number_check | CHECK (jersey_number IS NULL OR jersey_number >= 0 AND jersey_number <= 999) | False / False |
| team_members_membership_id_team_id_key | UNIQUE (membership_id, team_id) | False / False |
| team_members_pkey | PRIMARY KEY (membership_id) | False / False |
| team_members_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| team_members_unclaimed_id_fkey | FOREIGN KEY (unclaimed_id) REFERENCES unclaimed_players(unclaimed_id) ON DELETE CASCADE | False / False |
| team_members_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| unclaimed_plays | CHECK (unclaimed_id IS NULL OR in_squad) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_team_members_added_by | CREATE INDEX idx_team_members_added_by ON public.team_members USING btree (added_by) |
| team_members_membership_id_team_id_key | CREATE UNIQUE INDEX team_members_membership_id_team_id_key ON public.team_members USING btree (membership_id, team_id) |
| team_members_pkey | CREATE UNIQUE INDEX team_members_pkey ON public.team_members USING btree (membership_id) |
| team_members_team | CREATE INDEX team_members_team ON public.team_members USING btree (team_id) |
| team_members_unclaimed | CREATE INDEX team_members_unclaimed ON public.team_members USING btree (unclaimed_id) WHERE (unclaimed_id IS NOT NULL) |
| team_members_unique_active_unclaimed | CREATE UNIQUE INDEX team_members_unique_active_unclaimed ON public.team_members USING btree (team_id, unclaimed_id) WHERE ((status = 'active'::member_status) AND (unclaimed_id IS NOT NULL)) |
| team_members_unique_active_user | CREATE UNIQUE INDEX team_members_unique_active_user ON public.team_members USING btree (team_id, user_id) WHERE ((status = 'active'::member_status) AND (user_id IS NOT NULL)) |
| team_members_unique_jersey | CREATE UNIQUE INDEX team_members_unique_jersey ON public.team_members USING btree (team_id, jersey_number) WHERE ((status = 'active'::member_status) AND (jersey_number IS NOT NULL)) |
| team_members_unique_primary_per_user | CREATE UNIQUE INDEX team_members_unique_primary_per_user ON public.team_members USING btree (user_id) WHERE ((is_primary = true) AND (status = 'active'::member_status) AND (user_id IS NOT NULL)) |
| team_members_user | CREATE INDEX team_members_user ON public.team_members USING btree (user_id) WHERE (user_id IS NOT NULL) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| team_members_delete_managers | DELETE | ["authenticated"] | ( SELECT team_can(team_members.team_id, 'team.roster.write'::text) AS team_can) | — |
| team_members_insert_rpc_only | INSERT | ["authenticated"] | — | false |
| team_members_read_anon | SELECT | ["anon"] | (EXISTS ( SELECT 1<br>   FROM teams t<br>  WHERE ((t.team_id = team_members.team_id) AND (t.privacy = 'public'::team_privacy)))) | — |
| team_members_read_public | SELECT | ["authenticated"] | ((EXISTS ( SELECT 1<br>   FROM teams t<br>  WHERE ((t.team_id = team_members.team_id) AND (t.privacy = 'public'::team_privacy)))) OR ( SELECT is_team_member(team_members.team_id) AS is_team_member)) | — |
| team_members_update_managers | UPDATE | ["authenticated"] | ( SELECT team_can(team_members.team_id, 'team.roster.write'::text) AS team_can) | ( SELECT team_can(team_members.team_id, 'team.roster.write'::text) AS team_can) |

### Triggers

| Name | Definition |
| --- | --- |
| team_members_after_insert_add_to_chat | CREATE TRIGGER team_members_after_insert_add_to_chat AFTER INSERT ON team_members FOR EACH ROW EXECUTE FUNCTION add_team_member_to_chat() |
| team_members_after_update_sync_chat | CREATE TRIGGER team_members_after_update_sync_chat AFTER UPDATE ON team_members FOR EACH ROW EXECUTE FUNCTION sync_team_member_chat() |
| team_members_assign_initial_role | CREATE TRIGGER team_members_assign_initial_role AFTER INSERT ON team_members FOR EACH ROW EXECUTE FUNCTION assign_initial_role() |
| team_members_set_updated_at | CREATE TRIGGER team_members_set_updated_at BEFORE UPDATE ON team_members FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## team_member_roles

Many-to-many assignments: one team member can hold multiple compatible roles.

Canonical declaration: [20260101000211_team_member_roles.sql](../../supabase/migrations/20260101000211_team_member_roles.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| membership_id | uuid | False | — |
| scope | text | False | 'team'::text |
| role_key | text | False | — |
| team_id | uuid | False | — |
| is_singleton | boolean | False | — |
| granted_by | uuid | True | — |
| granted_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| team_member_roles_at_least_one | TRIGGER DEFERRABLE INITIALLY DEFERRED | True / True |
| team_member_roles_exclusion | TRIGGER | False / False |
| team_member_roles_granted_by_fkey | FOREIGN KEY (granted_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| team_member_roles_membership_fk | FOREIGN KEY (membership_id, team_id) REFERENCES team_members(membership_id, team_id) ON DELETE CASCADE | False / False |
| team_member_roles_pkey | PRIMARY KEY (membership_id, scope, role_key) | False / False |
| team_member_roles_scope_check | CHECK (scope = 'team'::text) | False / False |
| team_member_roles_scope_role_key_is_singleton_fkey | FOREIGN KEY (scope, role_key, is_singleton) REFERENCES roles(scope, key, is_singleton) ON UPDATE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| team_member_roles_granted_by | CREATE INDEX team_member_roles_granted_by ON public.team_member_roles USING btree (granted_by) |
| team_member_roles_membership | CREATE INDEX team_member_roles_membership ON public.team_member_roles USING btree (membership_id) |
| team_member_roles_pkey | CREATE UNIQUE INDEX team_member_roles_pkey ON public.team_member_roles USING btree (membership_id, scope, role_key) |
| team_member_roles_singleton_per_team | CREATE UNIQUE INDEX team_member_roles_singleton_per_team ON public.team_member_roles USING btree (team_id, scope, role_key) WHERE is_singleton |
| team_member_roles_team_role | CREATE INDEX team_member_roles_team_role ON public.team_member_roles USING btree (team_id, scope, role_key) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| team_member_roles_read | SELECT | ["authenticated"] | ((EXISTS ( SELECT 1<br>   FROM teams t<br>  WHERE ((t.team_id = team_member_roles.team_id) AND (t.privacy = 'public'::team_privacy)))) OR ( SELECT is_team_member(team_member_roles.team_id) AS is_team_member)) | — |
| team_member_roles_read_anon | SELECT | ["anon"] | (EXISTS ( SELECT 1<br>   FROM teams t<br>  WHERE ((t.team_id = team_member_roles.team_id) AND (t.privacy = 'public'::team_privacy)))) | — |
| team_member_roles_write_rpc_only | ALL | ["authenticated"] | false | false |

### Triggers

| Name | Definition |
| --- | --- |
| team_member_roles_at_least_one | CREATE CONSTRAINT TRIGGER team_member_roles_at_least_one AFTER INSERT OR DELETE OR UPDATE ON team_member_roles DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION guard_member_has_role() |
| team_member_roles_exclusion | CREATE CONSTRAINT TRIGGER team_member_roles_exclusion AFTER INSERT OR UPDATE ON team_member_roles NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION guard_role_exclusion() |
| team_member_roles_needs_account | CREATE TRIGGER team_member_roles_needs_account BEFORE INSERT OR UPDATE ON team_member_roles FOR EACH ROW EXECUTE FUNCTION guard_role_needs_account() |

## team_invites

Invitations issued to registered users to join a team.

Canonical declaration: [20260101000240_team_invites.sql](../../supabase/migrations/20260101000240_team_invites.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| invite_id | uuid | False | gen_random_uuid() |
| team_id | uuid | False | — |
| invitee_id | uuid | False | — |
| invited_by | uuid | False | — |
| message | text | True | — |
| role | text | True | 'player'::text |
| jersey_number | integer | True | — |
| status | request_status | False | 'pending'::request_status |
| decided_by | uuid | True | — |
| decided_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| invite_decision_consistency | CHECK (status = 'pending'::request_status AND decided_by IS NULL AND decided_at IS NULL OR (status = ANY (ARRAY['approved'::request_status, 'rejected'::request_status])) AND decided_at IS NOT NULL OR status = 'cancelled'::request_status) | False / False |
| team_invites_decided_by_fkey | FOREIGN KEY (decided_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| team_invites_invited_by_fkey | FOREIGN KEY (invited_by) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| team_invites_invitee_id_fkey | FOREIGN KEY (invitee_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| team_invites_message_check | CHECK (message IS NULL OR length(message) <= 500) | False / False |
| team_invites_pkey | PRIMARY KEY (invite_id) | False / False |
| team_invites_role_check | CHECK (role IS NULL OR (role = ANY (ARRAY['player'::text, 'captain'::text]))) | False / False |
| team_invites_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_team_invites_decided_by | CREATE INDEX idx_team_invites_decided_by ON public.team_invites USING btree (decided_by) |
| idx_team_invites_invited_by | CREATE INDEX idx_team_invites_invited_by ON public.team_invites USING btree (invited_by) |
| team_invites_invitee | CREATE INDEX team_invites_invitee ON public.team_invites USING btree (invitee_id) |
| team_invites_one_pending | CREATE UNIQUE INDEX team_invites_one_pending ON public.team_invites USING btree (team_id, invitee_id) WHERE (status = 'pending'::request_status) |
| team_invites_pkey | CREATE UNIQUE INDEX team_invites_pkey ON public.team_invites USING btree (invite_id) |
| team_invites_team | CREATE INDEX team_invites_team ON public.team_invites USING btree (team_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| team_invites_insert_manager | INSERT | ["authenticated"] | — | (is_team_manager(team_id) AND (( SELECT auth.uid() AS uid) = invited_by)) |
| team_invites_read_self_or_manager | SELECT | ["authenticated"] | ((( SELECT auth.uid() AS uid) = invitee_id) OR is_team_manager(team_id)) | — |
| team_invites_update_self_or_manager | UPDATE | ["authenticated"] | ((( SELECT auth.uid() AS uid) = invitee_id) OR is_team_manager(team_id)) | ((( SELECT auth.uid() AS uid) = invitee_id) OR is_team_manager(team_id)) |

### Triggers

| Name | Definition |
| --- | --- |
| team_invites_notify | CREATE TRIGGER team_invites_notify AFTER INSERT ON team_invites FOR EACH ROW EXECUTE FUNCTION notify_on_team_invite() |
| team_invites_set_updated_at | CREATE TRIGGER team_invites_set_updated_at BEFORE UPDATE ON team_invites FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## team_join_requests

Requests initiated by players to join a team; decision workflow is handled by RPCs.

Canonical declaration: [20260612000000_team_join_requests.sql](../../supabase/migrations/20260612000000_team_join_requests.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| request_id | uuid | False | gen_random_uuid() |
| team_id | uuid | False | — |
| player_id | uuid | False | — |
| role | text | False | 'player'::text |
| message | text | True | — |
| status | request_status | False | 'pending'::request_status |
| decided_by | uuid | True | — |
| decided_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| join_request_decision_consistency | CHECK (status = 'pending'::request_status AND decided_by IS NULL AND decided_at IS NULL OR (status = ANY (ARRAY['approved'::request_status, 'rejected'::request_status])) AND decided_at IS NOT NULL OR status = 'cancelled'::request_status) | False / False |
| team_join_requests_decided_by_fkey | FOREIGN KEY (decided_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| team_join_requests_message_check | CHECK (message IS NULL OR length(message) <= 500) | False / False |
| team_join_requests_pkey | PRIMARY KEY (request_id) | False / False |
| team_join_requests_player_id_fkey | FOREIGN KEY (player_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| team_join_requests_role_check | CHECK (role = ANY (ARRAY['player'::text, 'captain'::text])) | False / False |
| team_join_requests_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_team_join_requests_decided_by | CREATE INDEX idx_team_join_requests_decided_by ON public.team_join_requests USING btree (decided_by) |
| team_join_requests_one_pending | CREATE UNIQUE INDEX team_join_requests_one_pending ON public.team_join_requests USING btree (team_id, player_id) WHERE (status = 'pending'::request_status) |
| team_join_requests_pkey | CREATE UNIQUE INDEX team_join_requests_pkey ON public.team_join_requests USING btree (request_id) |
| team_join_requests_player | CREATE INDEX team_join_requests_player ON public.team_join_requests USING btree (player_id) |
| team_join_requests_team | CREATE INDEX team_join_requests_team ON public.team_join_requests USING btree (team_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| team_join_requests_insert | INSERT | ["authenticated"] | — | (player_id = ( SELECT auth.uid() AS uid)) |
| team_join_requests_read | SELECT | ["authenticated"] | ((player_id = ( SELECT auth.uid() AS uid)) OR ( SELECT is_team_manager(team_join_requests.team_id) AS is_team_manager)) | — |
| team_join_requests_update | UPDATE | ["authenticated"] | ((player_id = ( SELECT auth.uid() AS uid)) OR ( SELECT is_team_manager(team_join_requests.team_id) AS is_team_manager)) | ((player_id = ( SELECT auth.uid() AS uid)) OR ( SELECT is_team_manager(team_join_requests.team_id) AS is_team_manager)) |

### Triggers

| Name | Definition |
| --- | --- |
| team_join_requests_set_updated_at | CREATE TRIGGER team_join_requests_set_updated_at BEFORE UPDATE ON team_join_requests FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## claim_requests

Requests to claim an unregistered player identity and the resulting decision.

Canonical declaration: [20260101000230_claim_requests.sql](../../supabase/migrations/20260101000230_claim_requests.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| request_id | uuid | False | gen_random_uuid() |
| unclaimed_id | uuid | False | — |
| requester_id | uuid | False | — |
| message | text | True | — |
| status | request_status | False | 'pending'::request_status |
| decided_by | uuid | True | — |
| decided_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| claim_request_decision_consistency | CHECK (status = 'pending'::request_status AND decided_by IS NULL AND decided_at IS NULL OR (status = ANY (ARRAY['approved'::request_status, 'rejected'::request_status])) AND decided_at IS NOT NULL OR status = 'cancelled'::request_status) | False / False |
| claim_requests_decided_by_fkey | FOREIGN KEY (decided_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| claim_requests_message_check | CHECK (message IS NULL OR length(message) <= 500) | False / False |
| claim_requests_pkey | PRIMARY KEY (request_id) | False / False |
| claim_requests_requester_id_fkey | FOREIGN KEY (requester_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| claim_requests_unclaimed_id_fkey | FOREIGN KEY (unclaimed_id) REFERENCES unclaimed_players(unclaimed_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| claim_requests_one_pending | CREATE UNIQUE INDEX claim_requests_one_pending ON public.claim_requests USING btree (unclaimed_id, requester_id) WHERE (status = 'pending'::request_status) |
| claim_requests_pkey | CREATE UNIQUE INDEX claim_requests_pkey ON public.claim_requests USING btree (request_id) |
| claim_requests_requester | CREATE INDEX claim_requests_requester ON public.claim_requests USING btree (requester_id) |
| claim_requests_unclaimed | CREATE INDEX claim_requests_unclaimed ON public.claim_requests USING btree (unclaimed_id) |
| idx_claim_requests_decided_by | CREATE INDEX idx_claim_requests_decided_by ON public.claim_requests USING btree (decided_by) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| claim_requests_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = requester_id) |
| claim_requests_read_self_or_owner | SELECT | ["authenticated"] | ((( SELECT auth.uid() AS uid) = requester_id) OR is_unclaimed_owner(unclaimed_id)) | — |
| claim_requests_update_self_or_owner | UPDATE | ["authenticated"] | ((( SELECT auth.uid() AS uid) = requester_id) OR is_unclaimed_owner(unclaimed_id)) | ((( SELECT auth.uid() AS uid) = requester_id) OR is_unclaimed_owner(unclaimed_id)) |

### Triggers

| Name | Definition |
| --- | --- |
| claim_requests_set_updated_at | CREATE TRIGGER claim_requests_set_updated_at BEFORE UPDATE ON claim_requests FOR EACH ROW EXECUTE FUNCTION set_updated_at() |
