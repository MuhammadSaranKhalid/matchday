# Foreign-key relationship diagrams

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md)

Each arrow is an actual foreign key in the replayed schema. Arrow direction is child → referenced parent. Labels identify child columns. These are dependency graphs, not claims that every parent has children or that every relationship is mandatory. Exact nullability, uniqueness, composite keys and ON DELETE actions are in the table reference. Dashed-looking logical relations are deliberately not invented for polymorphic UUIDs or UUID arrays. External/domain-crossing tables appear as reference nodes.

## Identity and teams

```mermaid
flowchart LR
  auth_users["auth.users"]
  claim_requests["claim_requests"]
  player_profiles["player_profiles"]
  profiles["profiles"]
  roles["roles"]
  team_invites["team_invites"]
  team_join_requests["team_join_requests"]
  team_member_roles["team_member_roles"]
  team_members["team_members"]
  teams["teams"]
  unclaimed_players["unclaimed_players"]
  profiles -->|"user_id"| auth_users
  player_profiles -->|"user_id"| profiles
  unclaimed_players -->|"added_by"| profiles
  unclaimed_players -->|"claimed_by_user_id"| profiles
  teams -->|"created_by"| profiles
  team_members -->|"added_by"| profiles
  team_members -->|"team_id"| teams
  team_members -->|"unclaimed_id"| unclaimed_players
  team_members -->|"user_id"| profiles
  team_member_roles -->|"granted_by"| profiles
  team_member_roles -->|"membership_id, team_id"| team_members
  team_member_roles -->|"scope, role_key, is_singleton"| roles
  team_invites -->|"decided_by"| profiles
  team_invites -->|"invited_by"| profiles
  team_invites -->|"invitee_id"| profiles
  team_invites -->|"team_id"| teams
  team_join_requests -->|"decided_by"| profiles
  team_join_requests -->|"player_id"| profiles
  team_join_requests -->|"team_id"| teams
  claim_requests -->|"decided_by"| profiles
  claim_requests -->|"requester_id"| profiles
  claim_requests -->|"unclaimed_id"| unclaimed_players
```

## Authorization catalogue

```mermaid
flowchart LR
  grants["grants"]
  permission_scopes["permission_scopes"]
  permissions["permissions"]
  profiles["profiles"]
  role_exclusion_members["role_exclusion_members"]
  role_exclusion_sets["role_exclusion_sets"]
  role_permissions["role_permissions"]
  roles["roles"]
  teams["teams"]
  role_exclusion_members -->|"scope, role_key"| roles
  role_exclusion_members -->|"set_id"| role_exclusion_sets
  permission_scopes -->|"permission_key"| permissions
  role_permissions -->|"permission_key, scope"| permission_scopes
  role_permissions -->|"scope, role_key"| roles
  role_permissions -->|"team_id"| teams
  grants -->|"granted_by"| profiles
  grants -->|"permission_key, scope"| permission_scopes
  grants -->|"subject_id"| profiles
```

## Tournaments and venues

```mermaid
flowchart LR
  grounds["grounds"]
  match_format_presets["match_format_presets"]
  profiles["profiles"]
  teams["teams"]
  tournament_grounds["tournament_grounds"]
  tournament_standings["tournament_standings"]
  tournament_teams["tournament_teams"]
  tournaments["tournaments"]
  grounds -->|"created_by"| profiles
  tournaments -->|"created_by"| profiles
  tournament_grounds -->|"ground_id"| grounds
  tournament_grounds -->|"tournament_id"| tournaments
  tournament_teams -->|"decided_by"| profiles
  tournament_teams -->|"payment_recorded_by"| profiles
  tournament_teams -->|"registered_by"| profiles
  tournament_teams -->|"team_id"| teams
  tournament_teams -->|"tournament_id"| tournaments
  tournament_standings -->|"team_id"| teams
  tournament_standings -->|"tournament_id"| tournaments
  match_format_presets -->|"created_by"| profiles
```

## Matches and scoring

```mermaid
flowchart LR
  grounds["grounds"]
  match_challenges["match_challenges"]
  match_deliveries["match_deliveries"]
  match_innings["match_innings"]
  match_innings_state["match_innings_state"]
  match_officials["match_officials"]
  match_players["match_players"]
  match_pool_applications["match_pool_applications"]
  match_result_history["match_result_history"]
  match_scorer_leases["match_scorer_leases"]
  match_teams["match_teams"]
  match_wickets["match_wickets"]
  matches["matches"]
  profiles["profiles"]
  teams["teams"]
  tournaments["tournaments"]
  unclaimed_players["unclaimed_players"]
  matches -->|"created_by"| profiles
  matches -->|"ground_id"| grounds
  matches -->|"openers_submitted_by"| profiles
  matches -->|"player_of_the_match_id"| match_players
  matches -->|"prev_match_a_id"| matches
  matches -->|"prev_match_b_id"| matches
  matches -->|"team_a_captain"| profiles
  matches -->|"team_a_id"| teams
  matches -->|"team_b_captain"| profiles
  matches -->|"team_b_id"| teams
  matches -->|"toss_won_by"| teams
  matches -->|"tournament_id"| tournaments
  matches -->|"winner_id"| teams
  match_teams -->|"captain_player_id"| match_players
  match_teams -->|"keeper_player_id"| match_players
  match_teams -->|"match_id"| matches
  match_teams -->|"team_id"| teams
  match_players -->|"match_id"| matches
  match_players -->|"unclaimed_id"| unclaimed_players
  match_players -->|"user_id"| profiles
  match_innings -->|"match_id"| matches
  match_innings_state -->|"bowler_id"| match_players
  match_innings_state -->|"innings_id"| match_innings
  match_innings_state -->|"match_id"| matches
  match_innings_state -->|"non_striker_id"| match_players
  match_innings_state -->|"innings_id, match_id, innings_number"| match_innings
  match_innings_state -->|"striker_id"| match_players
  match_deliveries -->|"bowler_id"| match_players
  match_deliveries -->|"fielder_id"| match_players
  match_deliveries -->|"innings_id"| match_innings
  match_deliveries -->|"match_id"| matches
  match_deliveries -->|"non_striker_id"| match_players
  match_deliveries -->|"recorded_by"| profiles
  match_deliveries -->|"striker_id"| match_players
  match_wickets -->|"assisted_fielder_id"| match_players
  match_wickets -->|"credited_bowler_id"| match_players
  match_wickets -->|"delivery_id"| match_deliveries
  match_wickets -->|"innings_id"| match_innings
  match_wickets -->|"player_out_id"| match_players
  match_wickets -->|"primary_fielder_id"| match_players
  match_officials -->|"assigned_by"| profiles
  match_officials -->|"match_id"| matches
  match_officials -->|"user_id"| profiles
  match_scorer_leases -->|"active_scorer_id"| profiles
  match_scorer_leases -->|"match_id"| matches
  match_result_history -->|"match_id"| matches
  match_result_history -->|"recorded_by"| profiles
  match_challenges -->|"decided_by"| profiles
  match_challenges -->|"from_team_id"| teams
  match_challenges -->|"match_id"| matches
  match_challenges -->|"requested_by"| profiles
  match_challenges -->|"to_team_id"| teams
  match_pool_applications -->|"applicant_team_id"| teams
  match_pool_applications -->|"applicant_user_id"| profiles
  match_pool_applications -->|"request_id"| match_challenges
```

## Posts and social activity

```mermaid
flowchart LR
  bookmarks["bookmarks"]
  comment_likes["comment_likes"]
  comments["comments"]
  follows["follows"]
  matches["matches"]
  post_likes["post_likes"]
  posts["posts"]
  profiles["profiles"]
  teams["teams"]
  tournaments["tournaments"]
  posts -->|"author_id"| profiles
  posts -->|"linked_match_id"| matches
  posts -->|"linked_team_id"| teams
  posts -->|"linked_tournament_id"| tournaments
  comments -->|"author_id"| profiles
  comments -->|"parent_comment_id"| comments
  comments -->|"post_id"| posts
  post_likes -->|"post_id"| posts
  post_likes -->|"user_id"| profiles
  comment_likes -->|"comment_id"| comments
  comment_likes -->|"user_id"| profiles
  bookmarks -->|"post_id"| posts
  bookmarks -->|"user_id"| profiles
  follows -->|"follower_id"| profiles
```

## Messaging

```mermaid
flowchart LR
  chat_members["chat_members"]
  chats["chats"]
  dm_channels["dm_channels"]
  matches["matches"]
  messages["messages"]
  profiles["profiles"]
  teams["teams"]
  chats -->|"match_id"| matches
  chats -->|"team_id"| teams
  chat_members -->|"chat_id"| chats
  chat_members -->|"user_id"| profiles
  messages -->|"chat_id"| chats
  messages -->|"reply_to_id"| messages
  messages -->|"sender_id"| profiles
  dm_channels -->|"accepted_by"| profiles
  dm_channels -->|"chat_id"| chats
  dm_channels -->|"user_a"| profiles
  dm_channels -->|"user_b"| profiles
```

## Notifications

```mermaid
flowchart LR
  device_tokens["device_tokens"]
  notification_categories["notification_categories"]
  notification_deliveries["notification_deliveries"]
  notification_icons["notification_icons"]
  notification_mutes["notification_mutes"]
  notification_preferences["notification_preferences"]
  notification_types["notification_types"]
  notifications["notifications"]
  profiles["profiles"]
  notification_types -->|"category"| notification_categories
  notification_types -->|"icon"| notification_icons
  notifications -->|"actor_id"| profiles
  notifications -->|"recipient_id"| profiles
  notifications -->|"type_key"| notification_types
  notification_preferences -->|"category"| notification_categories
  notification_preferences -->|"user_id"| profiles
  notification_mutes -->|"user_id"| profiles
  notification_deliveries -->|"notification_id"| notifications
  device_tokens -->|"user_id"| profiles
```

## Complete graph

[Editable Mermaid source for all foreign keys](diagrams/all-foreign-keys.mmd). Use the focused diagrams above for reading; the full graph is for impact tracing.

## Relationships without foreign keys

`follows(target_type,target_id)`, `notification_mutes(scope,entity_id)`, notification entity references, and scoped grant entity IDs need discriminator-aware reasoning. JSON payloads, arrays and Storage paths are not automatically checked by a foreign key. Their validation/cleanup depends on constraints, triggers and application code; inspect those paths when adding a new scope.
