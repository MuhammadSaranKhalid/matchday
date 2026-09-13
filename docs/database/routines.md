# Functions and compatibility views

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md)

This is the final replayed function set. Source links list declaration sites by name; overloaded signatures and later replacements must be compared against the signature and full definition in [schema-snapshot.json](schema-snapshot.json). EXECUTE permission alone is not business authorization. Trigger-returning functions cannot be invoked like ordinary RPCs.

## View: balls

Options: `['security_invoker=on']`. Source: [20260101000405_match_deliveries.sql](../../supabase/migrations/20260101000405_match_deliveries.sql)

```sql
 SELECT delivery_id,
    innings_id,
    match_id,
    innings_number,
    seq,
    over_number,
    ball_in_over,
    is_legal_delivery,
    delivery_type,
    runs_off_bat,
    extra_runs,
    total_runs,
    is_boundary,
    is_four,
    is_six,
    is_free_hit,
    is_wicket,
    wicket_type,
    striker_id,
    non_striker_id,
    bowler_id,
    fielder_id,
    pitch_x,
    pitch_y,
    shot_angle,
    shot_distance,
    shot_type,
    idempotency_key,
    is_undone,
    commentary,
    recorded_by,
    recorded_at
   FROM match_deliveries;
```

## View: format_presets

Options: `['security_invoker=on']`. Source: [20260101000340_match_format_presets.sql](../../supabase/migrations/20260101000340_match_format_presets.sql)

```sql
 SELECT id,
    label,
    sort_order,
    config,
    is_active,
    is_system,
    created_by,
    default_scoring_mode,
    created_at
   FROM match_format_presets;
```

## _attach_role

```sql
_attach_role(p_membership_id uuid, p_role_key text, p_granted_by uuid DEFAULT NULL::uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## _bowler_credited_wickets

```sql
_bowler_credited_wickets()
RETURNS text[]
```

Language: **sql**; security: **INVOKER**; volatility: **immutable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260905000000_tournament_leaderboards.sql](../../supabase/migrations/20260905000000_tournament_leaderboards.sql)

## _can_score_innings

```sql
_can_score_innings(p_match_id uuid, p_innings_number integer DEFAULT 1)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql), [20260822120000_remove_sql_scoring_engine.sql](../../supabase/migrations/20260822120000_remove_sql_scoring_engine.sql)

## _fill_match_captains

```sql
_fill_match_captains()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql)

## _is_match_captain

```sql
_is_match_captain(p_match_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql), [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql)

## _is_match_creator

```sql
_is_match_creator(p_match_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql)

## _is_match_side_captain

```sql
_is_match_side_captain(p_match_id uuid, p_team_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql)

## _member_rank

```sql
_member_rank(p_membership_id uuid)
RETURNS integer
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## _my_rank

```sql
_my_rank(p_team_id uuid)
RETURNS integer
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## _normalize_match_format

```sql
_normalize_match_format(p_format jsonb)
RETURNS jsonb
```

Language: **sql**; security: **INVOKER**; volatility: **immutable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000400_matches.sql](../../supabase/migrations/20260101000400_matches.sql)

## _notify_deliver

```sql
_notify_deliver(p_notification_ids uuid[], p_queue_name text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000910_notification_delivery_queue.sql](../../supabase/migrations/20260101000910_notification_delivery_queue.sql)

## _notify_vars

```sql
_notify_vars(p_payload jsonb, p_actor_id uuid)
RETURNS jsonb
```

Language: **plpgsql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## _require_match_organizer

```sql
_require_match_organizer(p_match_id uuid)
RETURNS matches
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## _role_grants

```sql
_role_grants(p_team_id uuid, p_scope text, p_role_key text, p_permission text)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## _strip_deleted_profile_from_arrays

```sql
_strip_deleted_profile_from_arrays()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000700_delete_user.sql](../../supabase/migrations/20260101000700_delete_user.sql)

## _team_current_captain

```sql
_team_current_captain(p_team_id uuid)
RETURNS uuid
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql)

## _try_topic_uuid

```sql
_try_topic_uuid(p_topic text, p_pos integer)
RETURNS uuid
```

Language: **sql**; security: **INVOKER**; volatility: **immutable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=True, service_role=True, authenticated=True.

Source declarations: [20260101000810_realtime_authorization.sql](../../supabase/migrations/20260101000810_realtime_authorization.sql)

## _user_team_can

```sql
_user_team_can(p_user_id uuid, p_team_id uuid, p_permission text)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## _validate_match_request_keeper

```sql
_validate_match_request_keeper()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260603000000_match_request_polymorphic_xi.sql](../../supabase/migrations/20260603000000_match_request_polymorphic_xi.sql)

## _validate_team_xi

```sql
_validate_team_xi(p_team_id uuid, p_xi uuid[])
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql), [20260603000000_match_request_polymorphic_xi.sql](../../supabase/migrations/20260603000000_match_request_polymorphic_xi.sql)

## abandon_stale_matches

```sql
abandon_stale_matches()
RETURNS integer
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000610_match_request_expiry_cron.sql](../../supabase/migrations/20260101000610_match_request_expiry_cron.sql)

## accept_dm_request

```sql
accept_dm_request(p_chat_id uuid)
RETURNS timestamp with time zone
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260816000000_dm_message_requests.sql](../../supabase/migrations/20260816000000_dm_message_requests.sql)

## accept_match_request

```sql
accept_match_request(p_request_id uuid, p_scheduled_start_time timestamp with time zone DEFAULT NULL::timestamp with time zone, p_venue text DEFAULT NULL::text, p_format jsonb DEFAULT NULL::jsonb, p_decision_note text DEFAULT NULL::text, p_to_team_id uuid DEFAULT NULL::uuid, p_to_team_xi uuid[] DEFAULT '{}'::uuid[], p_to_team_keeper_id uuid DEFAULT NULL::uuid)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql), [20260529142241_accept_match_request_defaults_full_roster.sql](../../supabase/migrations/20260529142241_accept_match_request_defaults_full_roster.sql), [20260822110000_match_creation_and_format_fixes.sql](../../supabase/migrations/20260822110000_match_creation_and_format_fixes.sql)

## accept_pool_application

```sql
accept_pool_application(p_application_id uuid, p_decision_note text DEFAULT NULL::text)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260817090000_match_pool_applications.sql](../../supabase/migrations/20260817090000_match_pool_applications.sql), [20260822110000_match_creation_and_format_fixes.sql](../../supabase/migrations/20260822110000_match_creation_and_format_fixes.sql)

## accept_team_invite

```sql
accept_team_invite(p_invite_id uuid)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000240_team_invites.sql](../../supabase/migrations/20260101000240_team_invites.sql)

## accept_team_join_request

```sql
accept_team_join_request(p_request_id uuid, p_jersey_number integer DEFAULT NULL::integer)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260612000000_team_join_requests.sql](../../supabase/migrations/20260612000000_team_join_requests.sql)

## add_team_member

```sql
add_team_member(p_team_id uuid, p_user_id uuid, p_role_key text DEFAULT 'player'::text, p_jersey_number integer DEFAULT NULL::integer, p_in_squad boolean DEFAULT true)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## add_team_member_to_chat

```sql
add_team_member_to_chat()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000801_chat_members.sql](../../supabase/migrations/20260101000801_chat_members.sql)

## add_unclaimed_team_member

```sql
add_unclaimed_team_member(p_team_id uuid, p_display_name text, p_phone_number text DEFAULT NULL::text, p_jersey_number integer DEFAULT NULL::integer, p_player_profile jsonb DEFAULT '{}'::jsonb)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## apply_to_match_pool

```sql
apply_to_match_pool(p_request_id uuid, p_applicant_team_id uuid, p_applicant_xi uuid[] DEFAULT '{}'::uuid[], p_applicant_keeper_id uuid DEFAULT NULL::uuid, p_message text DEFAULT NULL::text)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260817090000_match_pool_applications.sql](../../supabase/migrations/20260817090000_match_pool_applications.sql)

## approve_claim_request

```sql
approve_claim_request(p_request_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000230_claim_requests.sql](../../supabase/migrations/20260101000230_claim_requests.sql)

## approve_tournament_registration

```sql
approve_tournament_registration(p_registration_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000310_tournament_teams.sql](../../supabase/migrations/20260101000310_tournament_teams.sql)

## assign_initial_role

```sql
assign_initial_role()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## audience_followers

```sql
audience_followers(p_target_type follow_target_type, p_target_id uuid)
RETURNS SETOF uuid
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## audience_match_sides

```sql
audience_match_sides(p_match_id uuid)
RETURNS SETOF uuid
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## audience_team_members

```sql
audience_team_members(p_team_id uuid)
RETURNS SETOF uuid
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## broadcast_comment_deleted

```sql
broadcast_comment_deleted()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

## broadcast_comment_updated

```sql
broadcast_comment_updated()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

## broadcast_delivery_deleted

```sql
broadcast_delivery_deleted()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000820_match_realtime_and_security.sql](../../supabase/migrations/20260101000820_match_realtime_and_security.sql)

## broadcast_innings_state_updated

```sql
broadcast_innings_state_updated()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000820_match_realtime_and_security.sql](../../supabase/migrations/20260101000820_match_realtime_and_security.sql)

## broadcast_match_state_updated

```sql
broadcast_match_state_updated()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000820_match_realtime_and_security.sql](../../supabase/migrations/20260101000820_match_realtime_and_security.sql)

## broadcast_new_comment

```sql
broadcast_new_comment()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

## broadcast_new_delivery

```sql
broadcast_new_delivery()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000820_match_realtime_and_security.sql](../../supabase/migrations/20260101000820_match_realtime_and_security.sql)

## broadcast_new_notification

```sql
broadcast_new_notification()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000500_notifications.sql](../../supabase/migrations/20260101000500_notifications.sql)

## broadcast_notification_deleted

```sql
broadcast_notification_deleted()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000500_notifications.sql](../../supabase/migrations/20260101000500_notifications.sql)

## broadcast_notification_updated

```sql
broadcast_notification_updated()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000500_notifications.sql](../../supabase/migrations/20260101000500_notifications.sql)

## broadcast_standings_change

```sql
broadcast_standings_change()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000320_tournament_standings.sql](../../supabase/migrations/20260101000320_tournament_standings.sql)

## bump_chat_last_message_at

```sql
bump_chat_last_message_at()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000802_messages.sql](../../supabase/migrations/20260101000802_messages.sql)

## bump_comment_likes_count

```sql
bump_comment_likes_count()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000540_comment_likes.sql](../../supabase/migrations/20260101000540_comment_likes.sql)

## bump_post_comments_count

```sql
bump_post_comments_count()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

## bump_post_likes_count

```sql
bump_post_likes_count()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000530_post_likes.sql](../../supabase/migrations/20260101000530_post_likes.sql)

## can

```sql
can(p_scope text, p_entity_id uuid, p_permission text)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## can_act_for_post_context

```sql
can_act_for_post_context(p_author_context post_author_context, p_entity_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000510_posts.sql](../../supabase/migrations/20260101000510_posts.sql)

## can_score_innings

```sql
can_score_innings(p_match_id uuid, p_innings_number integer DEFAULT 1)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql), [20260822120000_remove_sql_scoring_engine.sql](../../supabase/migrations/20260822120000_remove_sql_scoring_engine.sql)

## cancel_match_request

```sql
cancel_match_request(p_request_id uuid, p_decision_note text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql)

## claim_unclaimed_by_phone

```sql
claim_unclaimed_by_phone()
RETURNS integer
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000120_unclaimed_players.sql](../../supabase/migrations/20260101000120_unclaimed_players.sql)

## cleanup_follows_on_entity_delete

```sql
cleanup_follows_on_entity_delete()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000560_follows.sql](../../supabase/migrations/20260101000560_follows.sql)

## confirm_tournament_awards

```sql
confirm_tournament_awards(p_tournament_id uuid, p_awards jsonb)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260825000000_tournament_advancement_and_standings.sql](../../supabase/migrations/20260825000000_tournament_advancement_and_standings.sql)

## counter_match_request

```sql
counter_match_request(p_request_id uuid, p_countered_start_time timestamp with time zone DEFAULT NULL::timestamp with time zone, p_countered_venue text DEFAULT NULL::text, p_countered_format jsonb DEFAULT NULL::jsonb, p_countered_players_per_side integer DEFAULT NULL::integer, p_decision_note text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql)

## create_owner_membership

```sql
create_owner_membership()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## create_team_chat

```sql
create_team_chat()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000804_chat_lifecycle.sql](../../supabase/migrations/20260101000804_chat_lifecycle.sql)

## decline_dm_request

```sql
decline_dm_request(p_chat_id uuid)
RETURNS boolean
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260816000000_dm_message_requests.sql](../../supabase/migrations/20260816000000_dm_message_requests.sql)

## decline_match_request

```sql
decline_match_request(p_request_id uuid, p_decision_note text DEFAULT NULL::text, p_decision_reason decline_reason DEFAULT NULL::decline_reason)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql)

## decline_team_join_request

```sql
decline_team_join_request(p_request_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260612000000_team_join_requests.sql](../../supabase/migrations/20260612000000_team_join_requests.sql)

## delete_user

```sql
delete_user()
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000700_delete_user.sql](../../supabase/migrations/20260101000700_delete_user.sql)

## enforce_comment_single_level

```sql
enforce_comment_single_level()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

## enforce_username_cooldown

```sql
enforce_username_cooldown()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000100_profiles.sql](../../supabase/migrations/20260101000100_profiles.sql)

## expire_stale_match_requests

```sql
expire_stale_match_requests()
RETURNS integer
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000610_match_request_expiry_cron.sql](../../supabase/migrations/20260101000610_match_request_expiry_cron.sql)

## f_unaccent

```sql
f_unaccent(text)
RETURNS text
```

Language: **sql**; security: **INVOKER**; volatility: **immutable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000000_shared_helpers.sql](../../supabase/migrations/20260101000000_shared_helpers.sql)

## find_match_request_by_code

```sql
find_match_request_by_code(p_code text)
RETURNS SETOF match_challenges
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql)

## finish_notification_job

```sql
finish_notification_job(p_queue text, p_id bigint)
RETURNS boolean
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000910_notification_delivery_queue.sql](../../supabase/migrations/20260101000910_notification_delivery_queue.sql)

## get_follow_list

```sql
get_follow_list(p_user_id uuid, p_direction text, p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
RETURNS TABLE(user_id uuid, display_name text, username text, avatar_url text, you_follow boolean, they_follow_you boolean)
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=True, service_role=True, authenticated=True.

Source declarations: [20260101000561_get_follow_list_rpc.sql](../../supabase/migrations/20260101000561_get_follow_list_rpc.sql)

## get_or_create_dm_chat

```sql
get_or_create_dm_chat(p_target_user_id uuid)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000803_dm_channels.sql](../../supabase/migrations/20260101000803_dm_channels.sql)

## grant_team_role

```sql
grant_team_role(p_membership_id uuid, p_role_key text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## guard_chat_members_role_change

```sql
guard_chat_members_role_change()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000801_chat_members.sql](../../supabase/migrations/20260101000801_chat_members.sql)

## guard_dm_message_request_limit

```sql
guard_dm_message_request_limit()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260816000000_dm_message_requests.sql](../../supabase/migrations/20260816000000_dm_message_requests.sql)

## guard_exclusion_set_sane

```sql
guard_exclusion_set_sane()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000203_role_exclusion_members.sql](../../supabase/migrations/20260101000203_role_exclusion_members.sql)

## guard_grant_is_grantable

```sql
guard_grant_is_grantable()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000207_grants.sql](../../supabase/migrations/20260101000207_grants.sql)

## guard_member_has_role

```sql
guard_member_has_role()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000211_team_member_roles.sql](../../supabase/migrations/20260101000211_team_member_roles.sql)

## guard_permission_min_rank

```sql
guard_permission_min_rank()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000206_role_permissions.sql](../../supabase/migrations/20260101000206_role_permissions.sql)

## guard_role_exclusion

```sql
guard_role_exclusion()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000211_team_member_roles.sql](../../supabase/migrations/20260101000211_team_member_roles.sql)

## guard_role_needs_account

```sql
guard_role_needs_account()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000211_team_member_roles.sql](../../supabase/migrations/20260101000211_team_member_roles.sql)

## handle_new_auth_user

```sql
handle_new_auth_user()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000100_profiles.sql](../../supabase/migrations/20260101000100_profiles.sql)

## is_chat_member

```sql
is_chat_member(p_chat_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000801_chat_members.sql](../../supabase/migrations/20260101000801_chat_members.sql)

## is_post_author

```sql
is_post_author(p_post_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000510_posts.sql](../../supabase/migrations/20260101000510_posts.sql)

## is_team_captain

```sql
is_team_captain(p_team_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## is_team_manager

```sql
is_team_manager(p_team_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## is_team_member

```sql
is_team_member(p_team_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## is_tournament_organizer

```sql
is_tournament_organizer(p_tournament_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000300_tournaments.sql](../../supabase/migrations/20260101000300_tournaments.sql)

## is_unclaimed_owner

```sql
is_unclaimed_owner(p_unclaimed_id uuid)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000120_unclaimed_players.sql](../../supabase/migrations/20260101000120_unclaimed_players.sql)

## leave_team

```sql
leave_team(p_membership_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## list_my_chats

```sql
list_my_chats()
RETURNS TABLE(chat_id uuid, type chat_type, team_id uuid, last_message_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, team_name text, team_logo_url text, team_logo_monogram text, team_primary_color text, dm_other_user_id uuid, dm_other_user_name text, dm_other_user_username text, dm_other_user_avatar_url text, you_follow boolean, they_follow_you boolean, last_message_body text, last_message_sender_id uuid, last_message_from_me boolean, unread_count integer, is_accepted boolean)
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000802_messages.sql](../../supabase/migrations/20260101000802_messages.sql), [20260816000000_dm_message_requests.sql](../../supabase/migrations/20260816000000_dm_message_requests.sql)

## list_my_matches

```sql
list_my_matches()
RETURNS SETOF matches
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql), [20260816120000_list_my_matches_rpc.sql](../../supabase/migrations/20260816120000_list_my_matches_rpc.sql)

## list_notifications

```sql
list_notifications(p_before_created timestamp with time zone DEFAULT NULL::timestamp with time zone, p_before_id uuid DEFAULT NULL::uuid, p_limit integer DEFAULT 40)
RETURNS SETOF notifications
```

Language: **sql**; security: **INVOKER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000920_notification_api.sql](../../supabase/migrations/20260101000920_notification_api.sql)

## mark_chat_read

```sql
mark_chat_read(p_chat_id uuid)
RETURNS timestamp with time zone
```

Language: **sql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000802_messages.sql](../../supabase/migrations/20260101000802_messages.sql)

## migrate_player_stats

```sql
migrate_player_stats(p_unclaimed_id uuid, p_user_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000120_unclaimed_players.sql](../../supabase/migrations/20260101000120_unclaimed_players.sql)

## mirror_scorer_grant

```sql
mirror_scorer_grant()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000410_match_officials.sql](../../supabase/migrations/20260101000410_match_officials.sql)

## normalize_unclaimed_claim_timestamp

```sql
normalize_unclaimed_claim_timestamp()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000120_unclaimed_players.sql](../../supabase/migrations/20260101000120_unclaimed_players.sql)

## notification_push_status

```sql
notification_push_status(p_id uuid, p_revision integer)
RETURNS text
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000910_notification_delivery_queue.sql](../../supabase/migrations/20260101000910_notification_delivery_queue.sql)

## notification_settings

```sql
notification_settings()
RETURNS jsonb
```

Language: **sql**; security: **INVOKER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000920_notification_api.sql](../../supabase/migrations/20260101000920_notification_api.sql)

## notify

```sql
notify(p_recipients uuid[], p_type_key text, p_payload jsonb DEFAULT '{}'::jsonb, p_actor_id uuid DEFAULT NULL::uuid, p_scope text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid)
RETURNS SETOF uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## notify_on_comment

```sql
notify_on_comment()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql)

## notify_on_follow

```sql
notify_on_follow()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql)

## notify_on_match_request_decision

```sql
notify_on_match_request_decision()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql)

## notify_on_match_request_insert

```sql
notify_on_match_request_insert()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql)

## notify_on_post_like

```sql
notify_on_post_like()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql)

## notify_on_team_invite

```sql
notify_on_team_invite()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql)

## notify_one

```sql
notify_one(p_recipient uuid, p_type_key text, p_payload jsonb DEFAULT '{}'::jsonb, p_actor_id uuid DEFAULT NULL::uuid, p_scope text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid)
RETURNS uuid
```

Language: **sql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## read_notification_jobs

```sql
read_notification_jobs(p_queue text)
RETURNS jsonb
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000910_notification_delivery_queue.sql](../../supabase/migrations/20260101000910_notification_delivery_queue.sql)

## recalculate_tournament_standings

```sql
recalculate_tournament_standings(p_tournament_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260825000000_tournament_advancement_and_standings.sql](../../supabase/migrations/20260825000000_tournament_advancement_and_standings.sql), [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## record_toss_decision

```sql
record_toss_decision(p_match_id uuid, p_decision toss_decision)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql)

## record_toss_winner

```sql
record_toss_winner(p_match_id uuid, p_won_by uuid, p_face character DEFAULT NULL::bpchar)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql)

## reject_pool_application

```sql
reject_pool_application(p_application_id uuid, p_reason text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260817090000_match_pool_applications.sql](../../supabase/migrations/20260817090000_match_pool_applications.sql)

## reject_tournament_registration

```sql
reject_tournament_registration(p_registration_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000310_tournament_teams.sql](../../supabase/migrations/20260101000310_tournament_teams.sql), [20260901000000_tournament_fixtures_and_decline_reason.sql](../../supabase/migrations/20260901000000_tournament_fixtures_and_decline_reason.sql)

## reject_tournament_registration

```sql
reject_tournament_registration(p_registration_id uuid, p_reason text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000310_tournament_teams.sql](../../supabase/migrations/20260101000310_tournament_teams.sql), [20260901000000_tournament_fixtures_and_decline_reason.sql](../../supabase/migrations/20260901000000_tournament_fixtures_and_decline_reason.sql)

## render_template

```sql
render_template(p_tmpl text, p_vars jsonb)
RETURNS text
```

Language: **plpgsql**; security: **INVOKER**; volatility: **immutable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql)

## request_to_join_team

```sql
request_to_join_team(p_team_id uuid, p_role text DEFAULT 'player'::text, p_message text DEFAULT NULL::text)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260612000000_team_join_requests.sql](../../supabase/migrations/20260612000000_team_join_requests.sql)

## revoke_team_role

```sql
revoke_team_role(p_membership_id uuid, p_role_key text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## search_grounds

```sql
search_grounds(p_query text DEFAULT NULL::text, p_lat double precision DEFAULT NULL::double precision, p_lng double precision DEFAULT NULL::double precision, p_limit integer DEFAULT 12)
RETURNS TABLE(ground_id uuid, name text, city text, surface text, has_floodlights boolean, distance_km double precision, match_score real)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000330_grounds.sql](../../supabase/migrations/20260101000330_grounds.sql)

## send_match_request

```sql
send_match_request(p_from_team_id uuid, p_to_team_id uuid DEFAULT NULL::uuid, p_proposed_start_time timestamp with time zone DEFAULT NULL::timestamp with time zone, p_proposed_venue text DEFAULT NULL::text, p_proposed_format jsonb DEFAULT '{}'::jsonb, p_message text DEFAULT NULL::text, p_players_per_side integer DEFAULT 11, p_from_team_xi uuid[] DEFAULT '{}'::uuid[], p_from_team_keeper_id uuid DEFAULT NULL::uuid)
RETURNS uuid
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql), [20260604120100_match_requests_pps_single_source.sql](../../supabase/migrations/20260604120100_match_requests_pps_single_source.sql)

## set_follow_notifications

```sql
set_follow_notifications(p_scope text, p_entity_id uuid, p_enabled boolean)
RETURNS void
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000920_notification_api.sql](../../supabase/migrations/20260101000920_notification_api.sql)

## set_updated_at

```sql
set_updated_at()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=False, authenticated=False.

Source declarations: [20260101000000_shared_helpers.sql](../../supabase/migrations/20260101000000_shared_helpers.sql)

## stamp_comment_edited_at

```sql
stamp_comment_edited_at()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

## stamp_post_edited_at

```sql
stamp_post_edited_at()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000510_posts.sql](../../supabase/migrations/20260101000510_posts.sql)

## start_innings

```sql
start_innings(p_match_id uuid, p_innings_number integer, p_striker_id uuid, p_non_striker_id uuid, p_bowler_id uuid, p_target integer DEFAULT NULL::integer)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql), [20260822110000_match_creation_and_format_fixes.sql](../../supabase/migrations/20260822110000_match_creation_and_format_fixes.sql), [20260822130000_repair_scoring_rpcs.sql](../../supabase/migrations/20260822130000_repair_scoring_rpcs.sql)

## start_match_now

```sql
start_match_now(p_match_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql)

## submit_match_openers

```sql
submit_match_openers(p_match_id uuid, p_striker_id uuid, p_non_striker_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql)

## sync_team_member_chat

```sql
sync_team_member_chat()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, auth, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000801_chat_members.sql](../../supabase/migrations/20260101000801_chat_members.sql)

## team_can

```sql
team_can(p_team_id uuid, p_permission text)
RETURNS boolean
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## team_members_with

```sql
team_members_with(p_team_id uuid, p_permission text)
RETURNS SETOF uuid
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## team_staff_ids

```sql
team_staff_ids(p_team_id uuid)
RETURNS SETOF uuid
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## tournament_abandon_match

```sql
tournament_abandon_match(p_match_id uuid, p_mode text, p_reschedule_to timestamp with time zone DEFAULT NULL::timestamp with time zone, p_reason text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_announce

```sql
tournament_announce(p_tournament_id uuid, p_message text)
RETURNS integer
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_assign_official

```sql
tournament_assign_official(p_match_id uuid, p_user_id uuid, p_role text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_assign_scorer

```sql
tournament_assign_scorer(p_match_id uuid, p_user_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_auto_assign_scorers

```sql
tournament_auto_assign_scorers(p_tournament_id uuid)
RETURNS integer
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_batting_leaderboard

```sql
tournament_batting_leaderboard(p_tournament_id uuid, p_limit integer DEFAULT 5)
RETURNS TABLE(player_key text, display_name text, team_name text, team_monogram text, is_unclaimed boolean, runs integer, balls_faced integer, fours integer, sixes integer, strike_rate numeric, innings integer, high_score integer)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260905000000_tournament_leaderboards.sql](../../supabase/migrations/20260905000000_tournament_leaderboards.sql)

## tournament_bowling_leaderboard

```sql
tournament_bowling_leaderboard(p_tournament_id uuid, p_limit integer DEFAULT 5)
RETURNS TABLE(player_key text, display_name text, team_name text, team_monogram text, is_unclaimed boolean, wickets integer, runs_conceded integer, legal_balls integer, economy numeric, innings integer, best_wickets integer, best_runs integer)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260905000000_tournament_leaderboards.sql](../../supabase/migrations/20260905000000_tournament_leaderboards.sql)

## tournament_cancel

```sql
tournament_cancel(p_tournament_id uuid, p_reason text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_declare_walkover

```sql
tournament_declare_walkover(p_match_id uuid, p_winner_team_id uuid, p_reason text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_fee_ledger

```sql
tournament_fee_ledger(p_tournament_id uuid)
RETURNS TABLE(registration_id uuid, team_id uuid, team_name text, team_monogram text, team_logo_url text, entry_fee numeric, amount_paid numeric, payment_channel text, payment_reference text, payment_recorded_at timestamp with time zone, recorded_by_name text, status text)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_generate_fixtures

```sql
tournament_generate_fixtures(p_tournament_id uuid, p_slots jsonb, p_seed_order uuid[])
RETURNS integer
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260901000000_tournament_fixtures_and_decline_reason.sql](../../supabase/migrations/20260901000000_tournament_fixtures_and_decline_reason.sql), [20260903000000_tournament_full_draw.sql](../../supabase/migrations/20260903000000_tournament_full_draw.sql)

Locks a tournament draw: inserts every fixture in every round (later rounds unresolved, linked by prev_match_a_id/prev_match_b_id), records the seed order, moves the tournament to `upcoming` and seeds the standings table. Pairing is computed client-side by buildDraw — do not reimplement it here.

## tournament_ground_clashes

```sql
tournament_ground_clashes(p_tournament_id uuid, p_window interval DEFAULT '03:00:00'::interval)
RETURNS TABLE(ground_id uuid, ground_name text, match_a_id uuid, match_a_start timestamp with time zone, match_b_id uuid, match_b_start timestamp with time zone, gap interval)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_live_board

```sql
tournament_live_board(p_tournament_id uuid)
RETURNS TABLE(match_id uuid, venue text, status text, scheduled_start_time timestamp with time zone, round text, team_a_id uuid, team_a_name text, team_b_id uuid, team_b_name text, winner_id uuid, result jsonb, scorer_id uuid, scorer_name text, last_ball_at timestamp with time zone, innings_lines jsonb)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_match_officials

```sql
tournament_match_officials(p_match_id uuid)
RETURNS TABLE(user_id uuid, display_name text, username text, avatar_url text, role text, assigned_at timestamp with time zone, club_name text, is_neutral boolean)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_official_candidates

```sql
tournament_official_candidates(p_tournament_id uuid, p_match_id uuid)
RETURNS TABLE(user_id uuid, display_name text, username text, avatar_url text, club_name text, is_neutral boolean, matches_officiated integer, busy_on text)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_organizer_profile

```sql
tournament_organizer_profile(p_tournament_id uuid)
RETURNS TABLE(user_id uuid, display_name text, username text, avatar_url text, city text, cups_run integer, first_cup_year integer, completed_cups integer)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260905000000_tournament_leaderboards.sql](../../supabase/migrations/20260905000000_tournament_leaderboards.sql)

## tournament_override_result

```sql
tournament_override_result(p_match_id uuid, p_winner_team_id uuid, p_reason text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_record_payment

```sql
tournament_record_payment(p_registration_id uuid, p_amount_paid numeric, p_channel text DEFAULT NULL::text, p_reference text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_remove_official

```sql
tournament_remove_official(p_match_id uuid, p_role text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_reschedule_match

```sql
tournament_reschedule_match(p_match_id uuid, p_start timestamp with time zone, p_venue text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_revise_match_conditions

```sql
tournament_revise_match_conditions(p_match_id uuid, p_revised_overs integer, p_bowler_quota integer, p_revised_target integer DEFAULT NULL::integer, p_method text DEFAULT 'run_rate'::text, p_reason text DEFAULT NULL::text)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## tournament_scorer_candidates

```sql
tournament_scorer_candidates(p_tournament_id uuid)
RETURNS TABLE(user_id uuid, display_name text, username text, role_label text)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_set_coorganizer

```sql
tournament_set_coorganizer(p_tournament_id uuid, p_user_id uuid, p_add boolean)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## tournament_trigger_super_over

```sql
tournament_trigger_super_over(p_match_id uuid, p_bats_first_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql)

## transfer_team_ownership

```sql
transfer_team_ownership(p_team_id uuid, p_new_owner_id uuid)
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## trg_advance_tournament_bracket

```sql
trg_advance_tournament_bracket()
RETURNS trigger
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260825000000_tournament_advancement_and_standings.sql](../../supabase/migrations/20260825000000_tournament_advancement_and_standings.sql), [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## trg_sync_match_winner_id

```sql
trg_sync_match_winner_id()
RETURNS trigger
```

Language: **plpgsql**; security: **INVOKER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql)

## unclaimed_player_contact_for_manager

```sql
unclaimed_player_contact_for_manager(p_unclaimed_id uuid)
RETURNS TABLE(phone_number text, email text)
```

Language: **sql**; security: **DEFINER**; volatility: **stable**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql)

## undo_last_ball

```sql
undo_last_ball(p_match_id uuid, p_innings_number integer)
RETURNS boolean
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=True.

Source declarations: [20260101000820_match_realtime_and_security.sql](../../supabase/migrations/20260101000820_match_realtime_and_security.sql), [20260822130000_repair_scoring_rpcs.sql](../../supabase/migrations/20260822130000_repair_scoring_rpcs.sql)

## wake_notification_worker

```sql
wake_notification_worker()
RETURNS void
```

Language: **plpgsql**; security: **DEFINER**; volatility: **volatile**; configuration: `['search_path=public, pg_temp']`.

EXECUTE: anon=False, service_role=True, authenticated=False.

Source declarations: [20260101000910_notification_delivery_queue.sql](../../supabase/migrations/20260101000910_notification_delivery_queue.sql)
