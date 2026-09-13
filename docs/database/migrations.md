# Migration inventory

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Rules and change workflow](migration-guide.md)

Files are ordered lexically by their unique numeric prefix. A later CREATE OR REPLACE can supersede an earlier routine. The final hardening sweep must remain last. Hashes pin this inventory to the reviewed checkout.

| Migration | Table declaration | Function declarations / replacements | SHA-256 prefix |
| --- | --- | --- | --- |
| [20260101000000_shared_helpers.sql](../../supabase/migrations/20260101000000_shared_helpers.sql) | Integration / helpers | f_unaccent, set_updated_at | 21c1926c7eef |
| [20260101000010_default_grants.sql](../../supabase/migrations/20260101000010_default_grants.sql) | Integration / helpers | — | e70ea06104bd |
| [20260101000100_profiles.sql](../../supabase/migrations/20260101000100_profiles.sql) | profiles | enforce_username_cooldown, handle_new_auth_user | 9c91c439d314 |
| [20260101000110_player_profiles.sql](../../supabase/migrations/20260101000110_player_profiles.sql) | player_profiles | — | e4f2b1eec063 |
| [20260101000120_unclaimed_players.sql](../../supabase/migrations/20260101000120_unclaimed_players.sql) | unclaimed_players | claim_unclaimed_by_phone, is_unclaimed_owner, migrate_player_stats, normalize_unclaimed_claim_timestamp | 776208836cbe |
| [20260101000200_teams.sql](../../supabase/migrations/20260101000200_teams.sql) | teams | — | 624222b2b815 |
| [20260101000201_roles.sql](../../supabase/migrations/20260101000201_roles.sql) | roles | — | 113244f48016 |
| [20260101000202_role_exclusion_sets.sql](../../supabase/migrations/20260101000202_role_exclusion_sets.sql) | role_exclusion_sets | — | afaf7aba8c57 |
| [20260101000203_role_exclusion_members.sql](../../supabase/migrations/20260101000203_role_exclusion_members.sql) | role_exclusion_members | guard_exclusion_set_sane | 271fccbd874b |
| [20260101000204_permissions.sql](../../supabase/migrations/20260101000204_permissions.sql) | permissions | — | 817aad8af35f |
| [20260101000205_permission_scopes.sql](../../supabase/migrations/20260101000205_permission_scopes.sql) | permission_scopes | — | 2355b9d8d58b |
| [20260101000206_role_permissions.sql](../../supabase/migrations/20260101000206_role_permissions.sql) | role_permissions | guard_permission_min_rank | ee658d61d217 |
| [20260101000207_grants.sql](../../supabase/migrations/20260101000207_grants.sql) | grants | guard_grant_is_grantable | e3bb13d201ca |
| [20260101000210_team_members.sql](../../supabase/migrations/20260101000210_team_members.sql) | team_members | — | 75ef20ae414e |
| [20260101000211_team_member_roles.sql](../../supabase/migrations/20260101000211_team_member_roles.sql) | team_member_roles | guard_member_has_role, guard_role_exclusion, guard_role_needs_account | c6d9f5b19491 |
| [20260101000212_team_authorization.sql](../../supabase/migrations/20260101000212_team_authorization.sql) | Integration / helpers | _attach_role, _member_rank, _my_rank, _role_grants, _user_team_can, add_team_member, add_unclaimed_team_member, assign_initial_role, can, create_owner_membership, grant_team_role, is_team_captain, is_team_manager, is_team_member, leave_team, revoke_team_role, team_can, team_members_with, team_staff_ids, transfer_team_ownership, unclaimed_player_contact_for_manager | 7ba30007a1f5 |
| [20260101000230_claim_requests.sql](../../supabase/migrations/20260101000230_claim_requests.sql) | claim_requests | approve_claim_request | 7cdb89a28b41 |
| [20260101000240_team_invites.sql](../../supabase/migrations/20260101000240_team_invites.sql) | team_invites | accept_team_invite | c828dae0d7bb |
| [20260101000300_tournaments.sql](../../supabase/migrations/20260101000300_tournaments.sql) | tournaments | is_tournament_organizer | 4585537f5109 |
| [20260101000310_tournament_teams.sql](../../supabase/migrations/20260101000310_tournament_teams.sql) | tournament_teams | approve_tournament_registration, reject_tournament_registration | ac7eb693782d |
| [20260101000320_tournament_standings.sql](../../supabase/migrations/20260101000320_tournament_standings.sql) | tournament_standings | broadcast_standings_change | 4ff965e52b91 |
| [20260101000330_grounds.sql](../../supabase/migrations/20260101000330_grounds.sql) | grounds | search_grounds | a3c2843f400e |
| [20260101000331_tournament_grounds.sql](../../supabase/migrations/20260101000331_tournament_grounds.sql) | tournament_grounds | — | a9d16c06467d |
| [20260101000340_match_format_presets.sql](../../supabase/migrations/20260101000340_match_format_presets.sql) | match_format_presets | — | 33ba67f84115 |
| [20260101000400_matches.sql](../../supabase/migrations/20260101000400_matches.sql) | matches | _normalize_match_format | 5d150b256376 |
| [20260101000401_match_players.sql](../../supabase/migrations/20260101000401_match_players.sql) | match_players | — | 1454bac5901f |
| [20260101000402_match_teams.sql](../../supabase/migrations/20260101000402_match_teams.sql) | match_teams | — | a94ca3e2fff9 |
| [20260101000403_match_innings.sql](../../supabase/migrations/20260101000403_match_innings.sql) | match_innings | — | aefea22d704f |
| [20260101000404_match_innings_state.sql](../../supabase/migrations/20260101000404_match_innings_state.sql) | match_innings_state | — | 858fbe88b62f |
| [20260101000405_match_deliveries.sql](../../supabase/migrations/20260101000405_match_deliveries.sql) | match_deliveries | — | 70c82a11d5b6 |
| [20260101000406_match_wickets.sql](../../supabase/migrations/20260101000406_match_wickets.sql) | match_wickets | — | f54f9d7c2743 |
| [20260101000407_match_scorer_leases.sql](../../supabase/migrations/20260101000407_match_scorer_leases.sql) | match_scorer_leases | — | a73a17967db8 |
| [20260101000408_match_result_history.sql](../../supabase/migrations/20260101000408_match_result_history.sql) | match_result_history | — | db50be4d66ca |
| [20260101000409_match_helpers.sql](../../supabase/migrations/20260101000409_match_helpers.sql) | Integration / helpers | _can_score_innings, _is_match_captain, can_score_innings, list_my_matches, record_match_toss, start_innings, start_match_now, submit_match_openers | 3b0b0bbe3a86 |
| [20260101000410_match_officials.sql](../../supabase/migrations/20260101000410_match_officials.sql) | match_officials | mirror_scorer_grant | bd83e95746d6 |
| [20260101000489_notification_icons.sql](../../supabase/migrations/20260101000489_notification_icons.sql) | notification_icons | — | 045aa0c11888 |
| [20260101000490_notification_categories.sql](../../supabase/migrations/20260101000490_notification_categories.sql) | notification_categories | — | fc6f7912eda7 |
| [20260101000491_notification_types.sql](../../supabase/migrations/20260101000491_notification_types.sql) | notification_types | — | f889ba0dc999 |
| [20260101000500_notifications.sql](../../supabase/migrations/20260101000500_notifications.sql) | notifications | broadcast_new_notification, broadcast_notification_deleted, broadcast_notification_updated | 39ff5d2bd5aa |
| [20260101000501_notification_preferences.sql](../../supabase/migrations/20260101000501_notification_preferences.sql) | notification_preferences | — | 2f25bd37f25c |
| [20260101000502_notification_mutes.sql](../../supabase/migrations/20260101000502_notification_mutes.sql) | notification_mutes | — | e41c66e1e631 |
| [20260101000503_notification_deliveries.sql](../../supabase/migrations/20260101000503_notification_deliveries.sql) | notification_deliveries | — | 6bf621990a66 |
| [20260101000510_posts.sql](../../supabase/migrations/20260101000510_posts.sql) | posts | can_act_for_post_context, is_post_author, stamp_post_edited_at | 8ffc2b055ede |
| [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql) | comments | broadcast_comment_deleted, broadcast_comment_updated, broadcast_new_comment, bump_post_comments_count, enforce_comment_single_level, stamp_comment_edited_at | adc4bcc7e068 |
| [20260101000530_post_likes.sql](../../supabase/migrations/20260101000530_post_likes.sql) | post_likes | bump_post_likes_count | b3529a8642d6 |
| [20260101000540_comment_likes.sql](../../supabase/migrations/20260101000540_comment_likes.sql) | comment_likes | bump_comment_likes_count | f4faa09e6401 |
| [20260101000550_bookmarks.sql](../../supabase/migrations/20260101000550_bookmarks.sql) | bookmarks | — | 8ace6c3c032c |
| [20260101000560_follows.sql](../../supabase/migrations/20260101000560_follows.sql) | follows | cleanup_follows_on_entity_delete | 75a38c29a281 |
| [20260101000561_get_follow_list_rpc.sql](../../supabase/migrations/20260101000561_get_follow_list_rpc.sql) | Integration / helpers | get_follow_list | 7d1fdb6b2d2d |
| [20260101000570_notification_engine.sql](../../supabase/migrations/20260101000570_notification_engine.sql) | Integration / helpers | _notify_vars, audience_followers, audience_match_sides, audience_team_members, notify, notify_one, render_template | de8a6ebd04f7 |
| [20260101000600_match_challenges.sql](../../supabase/migrations/20260101000600_match_challenges.sql) | match_challenges | _team_current_captain, _validate_team_xi, accept_match_request, cancel_match_request, counter_match_request, decline_match_request, find_match_request_by_code, send_match_request | 17e8e3908585 |
| [20260101000610_match_request_expiry_cron.sql](../../supabase/migrations/20260101000610_match_request_expiry_cron.sql) | Integration / helpers | abandon_stale_matches, expire_stale_match_requests | 16a8e4f02c08 |
| [20260101000620_notification_triggers.sql](../../supabase/migrations/20260101000620_notification_triggers.sql) | Integration / helpers | notify_on_comment, notify_on_follow, notify_on_match_request_decision, notify_on_match_request_insert, notify_on_post_like, notify_on_team_invite | ad34179aafbf |
| [20260101000700_delete_user.sql](../../supabase/migrations/20260101000700_delete_user.sql) | Integration / helpers | _strip_deleted_profile_from_arrays, delete_user | c315c7398216 |
| [20260101000800_chats.sql](../../supabase/migrations/20260101000800_chats.sql) | chats | — | 87a9ccfe2851 |
| [20260101000801_chat_members.sql](../../supabase/migrations/20260101000801_chat_members.sql) | chat_members | add_team_member_to_chat, guard_chat_members_role_change, is_chat_member, sync_team_member_chat | ca98dbf377e3 |
| [20260101000802_messages.sql](../../supabase/migrations/20260101000802_messages.sql) | messages | bump_chat_last_message_at, list_my_chats, mark_chat_read | 6cc380c05dc8 |
| [20260101000803_dm_channels.sql](../../supabase/migrations/20260101000803_dm_channels.sql) | dm_channels | get_or_create_dm_chat | 41d7cce07147 |
| [20260101000804_chat_lifecycle.sql](../../supabase/migrations/20260101000804_chat_lifecycle.sql) | Integration / helpers | create_team_chat | 00d2fe1bedb1 |
| [20260101000810_realtime_authorization.sql](../../supabase/migrations/20260101000810_realtime_authorization.sql) | Integration / helpers | _try_topic_uuid | 824d71ee41ed |
| [20260101000820_match_realtime_and_security.sql](../../supabase/migrations/20260101000820_match_realtime_and_security.sql) | Integration / helpers | broadcast_delivery_deleted, broadcast_innings_state_updated, broadcast_match_state_updated, broadcast_new_delivery, undo_last_ball | ce8266cdd35e |
| [20260101000900_device_tokens.sql](../../supabase/migrations/20260101000900_device_tokens.sql) | device_tokens | — | 661edacd0d93 |
| [20260101000910_notification_delivery_queue.sql](../../supabase/migrations/20260101000910_notification_delivery_queue.sql) | Integration / helpers | _notify_deliver, finish_notification_job, notification_push_status, read_notification_jobs, wake_notification_worker | 02d65b6b2cb7 |
| [20260101000920_notification_api.sql](../../supabase/migrations/20260101000920_notification_api.sql) | Integration / helpers | list_notifications, notification_settings, set_follow_notifications | c48bd654d556 |
| [20260529142241_accept_match_request_defaults_full_roster.sql](../../supabase/migrations/20260529142241_accept_match_request_defaults_full_roster.sql) | Integration / helpers | accept_match_request | e03e83605dc9 |
| [20260603000000_match_request_polymorphic_xi.sql](../../supabase/migrations/20260603000000_match_request_polymorphic_xi.sql) | Integration / helpers | _validate_match_request_keeper, _validate_team_xi | 7d9bcfbffbc7 |
| [20260604120100_match_requests_pps_single_source.sql](../../supabase/migrations/20260604120100_match_requests_pps_single_source.sql) | Integration / helpers | send_match_request | 90c541f10b97 |
| [20260611000000_teams_search.sql](../../supabase/migrations/20260611000000_teams_search.sql) | Integration / helpers | — | a76f5a32bbb4 |
| [20260612000000_team_join_requests.sql](../../supabase/migrations/20260612000000_team_join_requests.sql) | team_join_requests | accept_team_join_request, decline_team_join_request, request_to_join_team | c25c16c41cea |
| [20260816000000_dm_message_requests.sql](../../supabase/migrations/20260816000000_dm_message_requests.sql) | Integration / helpers | accept_dm_request, decline_dm_request, guard_dm_message_request_limit, list_my_chats | 033f4630a5a5 |
| [20260816120000_list_my_matches_rpc.sql](../../supabase/migrations/20260816120000_list_my_matches_rpc.sql) | Integration / helpers | list_my_matches | 010f7df631ed |
| [20260817090000_match_pool_applications.sql](../../supabase/migrations/20260817090000_match_pool_applications.sql) | match_pool_applications | accept_pool_application, apply_to_match_pool, reject_pool_application | 7b6a84ab12b9 |
| [20260821000000_explore_search.sql](../../supabase/migrations/20260821000000_explore_search.sql) | Integration / helpers | — | 3584566eceb1 |
| [20260822110000_match_creation_and_format_fixes.sql](../../supabase/migrations/20260822110000_match_creation_and_format_fixes.sql) | Integration / helpers | accept_match_request, accept_pool_application, start_innings | 2d203e272363 |
| [20260822120000_remove_sql_scoring_engine.sql](../../supabase/migrations/20260822120000_remove_sql_scoring_engine.sql) | Integration / helpers | _can_score_innings, can_score_innings | ded9a316142c |
| [20260822130000_repair_scoring_rpcs.sql](../../supabase/migrations/20260822130000_repair_scoring_rpcs.sql) | Integration / helpers | start_innings, undo_last_ball | d8b540272146 |
| [20260825000000_tournament_advancement_and_standings.sql](../../supabase/migrations/20260825000000_tournament_advancement_and_standings.sql) | Integration / helpers | confirm_tournament_awards, recalculate_tournament_standings, trg_advance_tournament_bracket | 90b4c702532c |
| [20260830000000_tournament_live_ops.sql](../../supabase/migrations/20260830000000_tournament_live_ops.sql) | Integration / helpers | _require_match_organizer, recalculate_tournament_standings, tournament_abandon_match, tournament_announce, tournament_assign_scorer, tournament_cancel, tournament_declare_walkover, tournament_ground_clashes, tournament_live_board, tournament_override_result, tournament_reschedule_match, tournament_scorer_candidates, tournament_set_coorganizer, trg_advance_tournament_bracket, trg_sync_match_winner_id | 1acd18fd0753 |
| [20260901000000_tournament_fixtures_and_decline_reason.sql](../../supabase/migrations/20260901000000_tournament_fixtures_and_decline_reason.sql) | Integration / helpers | reject_tournament_registration, tournament_generate_fixtures | 471829166be4 |
| [20260903000000_tournament_full_draw.sql](../../supabase/migrations/20260903000000_tournament_full_draw.sql) | Integration / helpers | tournament_generate_fixtures | 2895316c6be9 |
| [20260904000000_console_ledger_officials_ops.sql](../../supabase/migrations/20260904000000_console_ledger_officials_ops.sql) | Integration / helpers | tournament_assign_official, tournament_auto_assign_scorers, tournament_fee_ledger, tournament_match_officials, tournament_official_candidates, tournament_record_payment, tournament_remove_official, tournament_revise_match_conditions, tournament_trigger_super_over | 5cbd935dfd13 |
| [20260905000000_tournament_leaderboards.sql](../../supabase/migrations/20260905000000_tournament_leaderboards.sql) | Integration / helpers | _bowler_credited_wickets, tournament_batting_leaderboard, tournament_bowling_leaderboard, tournament_organizer_profile | ba179425267a |
| [20260906100000_match_toss_authority.sql](../../supabase/migrations/20260906100000_match_toss_authority.sql) | Integration / helpers | _fill_match_captains, _is_match_captain, _is_match_creator, _is_match_side_captain, record_toss_decision, record_toss_winner | 7e094e80b7c4 |
| [20260906120000_function_grants_hardening.sql](../../supabase/migrations/20260906120000_function_grants_hardening.sql) | Integration / helpers | — | 00f7b61f6c88 |
