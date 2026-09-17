# Enumerations, catalogue data, and platform objects

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md)

## PostgreSQL enums

Enums are declared centrally in shared_helpers. Catalogue keys such as roles and notification types are rows, not enums. An enum defines possible values, not all allowed transitions.

| Enum | Values |
| --- | --- |
| account_status | active, suspended, deleted |
| ball_type | leather, tape, tennis |
| batting_style | right_hand, left_hand |
| bowling_style | right_arm_fast, right_arm_medium, right_arm_spin, left_arm_fast, left_arm_spin, doesnt_bowl |
| chat_role | admin, member |
| chat_type | team, dm, match, group |
| comment_status | active, deleted, reported |
| decline_reason | roster, busy, no_interest, format, venue, other |
| delivery_kind | legal, wide, no_ball, bye, leg_bye, penalty |
| follow_status | active, muted |
| follow_target_type | user, team, tournament |
| ground_surface | turf, matting, concrete, astro, other |
| match_format | t20, odi, test, the_hundred, custom_limited, pairs |
| match_request_status | pending, countered, accepted, declined, cancelled, expired |
| match_role | captain, vice_captain, wicket_keeper, player, substitute |
| match_stage | group, quarter_final, semi_final, final, playoff |
| match_start_phase | toss, lineup, ready, live |
| match_status | scheduled, toss, rescheduled, live, innings_break, super_over, completed, abandoned, tied, no_result, walkover |
| match_type | friendly, tournament, practice, league |
| member_status | active, inactive, removed |
| player_role | batter, bowler, all_rounder, wicket_keeper |
| post_author_context | personal, team_manager, tournament_organizer |
| post_status | active, hidden, deleted, reported |
| post_type | text, photo, match_announcement, recruitment, tournament_update |
| post_visibility | public |
| request_status | pending, approved, rejected, cancelled |
| scoring_mode | live_ball_by_ball, post_match_scorecard |
| team_privacy | public, private |
| team_status | active, disbanded, archived |
| team_type | club, village, casual, corporate, school, university |
| toss_decision | bat, bowl |
| tournament_privacy | public, private |
| tournament_registration_status | pending, approved, rejected, withdrawn |
| tournament_status | draft, registration, upcoming, live, completed, cancelled, abandoned |
| tournament_type | knockout, round_robin, league, group_knockout, double_elimination |
| user_gender | male, female, other, prefer_not_to_say |
| wicket_kind | bowled, caught, caught_and_bowled, lbw, run_out, stumped, hit_wicket, retired_hurt, retired_out, obstructing_the_field, timed_out, handled_the_ball |

## Installed extensions

| Extension | Version on replay | Schema |
| --- | --- | --- |
| pg_cron | 1.6.4 | pg_catalog |
| pg_net | 0.20.3 | extensions |
| pg_stat_statements | 1.11 | extensions |
| pg_trgm | 1.6 | public |
| pgcrypto | 1.3 | extensions |
| pgmq | 1.5.1 | pgmq |
| plpgsql | 1.0 | pg_catalog |
| postgis | 3.3.7 | public |
| supabase_vault | 0.3.1 | vault |
| unaccent | 1.1 | public |
| uuid-ossp | 1.1 | extensions |

## roles

Seeded configuration from the empty replay. These are definitions, not user fixtures.

| key | name | rank | scope | is_system | created_at | is_singleton | display_group | allows_unclaimed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| captain | Captain | 20 | team | True | 2026-09-13T04:24:38.950027+00:00 | True | Match day | False |
| manager | Manager | 30 | team | True | 2026-09-13T04:24:38.950027+00:00 | False | Club | False |
| owner | Owner | 40 | team | True | 2026-09-13T04:24:38.950027+00:00 | True | Club | False |
| player | Player | 10 | team | True | 2026-09-13T04:24:38.950027+00:00 | False | Club | True |

## permissions

Seeded configuration from the empty replay. These are definitions, not user fixtures.

| action | min_rank | resource | sort_order | description | permission_key | direct_grantable |
| --- | --- | --- | --- | --- | --- | --- |
| lineup | — | match | 130 | Pick the XI, run the toss, start the match | match.lineup.set | False |
| assign | — | match | 150 | Appoint a scorer or umpire | match.official.assign | True |
| score | — | match | 140 | Score an innings | match.score | True |
| create | — | matches | 70 | Send, accept and cancel challenges | team.challenge.send | False |
| read | — | roster | 90 | See an unclaimed player's phone number | team.contact.view | False |
| disband | 40 | team | 110 | Archive or disband the team | team.disband | False |
| invite | — | roster | 40 | Send invites and decide join requests | team.invite | False |
| manage | 40 | permissions | 120 | Edit this team's permission matrix | team.permissions.manage | False |
| write | — | posts | 60 | Post as the team | team.post | False |
| write | — | profile | 50 | Name, crest, colours, ground, privacy | team.profile.write | False |
| role | — | roster | 20 | Change a member's roles | team.roster.role | False |
| write | — | roster | 10 | Add, remove and edit players | team.roster.write | False |
| appoint | 40 | staff | 30 | Create and remove managers | team.staff.appoint | False |
| enter | — | tournaments | 80 | Register the team for a tournament | team.tournament.enter | False |
| transfer | 40 | team | 100 | Hand over ownership | team.transfer | False |

## permission_scopes

Seeded configuration from the empty replay. These are definitions, not user fixtures.

| scope | permission_key |
| --- | --- |
| team | match.lineup.set |
| match | match.official.assign |
| team | match.official.assign |
| match | match.score |
| team | match.score |
| team | team.challenge.send |
| team | team.contact.view |
| team | team.disband |
| team | team.invite |
| team | team.permissions.manage |
| team | team.post |
| team | team.profile.write |
| team | team.roster.role |
| team | team.roster.write |
| team | team.staff.appoint |
| team | team.tournament.enter |
| team | team.transfer |

## notification_icons

Seeded configuration from the empty replay. These are definitions, not user fixtures.

| key | sha256 | license | storage_path | source_library | source_version |
| --- | --- | --- | --- | --- | --- |
| at | d35ec9665080ced80faeecfc99c3d28ac13275f211a36a10898951cdab641e2e | MIT | v1/at.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| bat | 7b319a3f7f327d3522aeafd9b6e26788293ad58012feffcea7bcca6121bb0202 | MIT | v1/cricket.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| bell | 470d39082cfbf44f0b4b0588d8f9f1fd2c211b09dc60d0304e91a24a3aeef32e | MIT | v1/bell.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| calendar | 63ea485308307c968964cd6f5d9b80f91418efd3f15a2cc4f04535e7aa322076 | MIT | v1/calendar-event.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| check | 60bb8534e78f5db10f1425170cfe03245ae369a1a3e788414319528f6d06cf76 | MIT | v1/circle-check.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| comment | 9aa5a223a418736c972ff2f6759dceed9f4c73830d20e504a8c7228d74995a3d | MIT | v1/message-circle.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| group | 2d196e620662a694bf579893db6a4d3b42557a2a6484174fe46029f2bcbae731 | MIT | v1/users-group.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| heart | f9f42a4d4ae0aca8f01dde4a7a255eff7af26ed0ee133b1458e9d3ff257464d6 | MIT | v1/heart.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| message | 950a6f078776c767cf6094f194fa53bc576bcb207c0a817a7a77b3353c20cdee | MIT | v1/messages.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| person_add | 323581c2b92f94b7b69622bf4a04385405733fdf80e6377ea6b034cc4087e231 | MIT | v1/user-plus.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| shield | 9c3d5fac4793c7df5b3f2418037f16cd2bb7ba217ca5ee619e17b715b2720364 | MIT | v1/shield-check.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| star | 33727ef0a469dbe7147e5cfe5a875a28b97809b0eac99a2e6886679369d43934 | MIT | v1/star.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| trophy | 2e56bd8f0e6f4d2ca4554485acc11717bb05a040d8a296fe2fb029781f4dad21 | MIT | v1/trophy.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |
| x | fa43bcb8692d0ee40ee973ba6251ec6ec9764038ed67eb480efaceff0ee294cf | MIT | v1/circle-x.svg | tabler-outline | 55f87a73f45cf1d9eaf16d7da705065483a9e4f9 |

## notification_types

Seeded configuration from the empty replay. These are definitions, not user fixtures.

| key | icon | tier | tone | category | is_active | importance | queue_name | body_template | route_template | title_template | collapse_window | default_channels | collapse_template | user_configurable | body_template_grouped |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chat.message.received | message | now | neutral | chat | True | high | notifications_push | {{actor_name}}: {{message_preview}} | /messages/{{chat_id}} | {{chat_name}} | 01:00:00 | ["inapp", "push"] | chat.message:{{chat_id}} | True | {{count}} new messages |
| chat.request.received | message | now | neutral | chat | True | normal | notifications_push | {{actor_name}} wants to message you | /messages | Message request | — | ["inapp", "push"] | — | True | — |
| match.application.accepted | check | now | success | match | True | high | notifications_push | {{opponent_name}} accepted your application | /matches/{{match_id}} | You got the match | — | ["inapp", "push"] | — | True | — |
| match.application.received | bat | now | brand | match | True | high | notifications_push | Tap to review and pick your opponent | /challenges/{{request_id}} | {{opponent_name}} applied to your open match | 12:00:00 | ["inapp", "push"] | match.application:{{request_id}} | True | {{count}} teams applied to your open match |
| match.challenge.accepted | check | now | success | match | True | high | notifications_push | {{opponent_name}} accepted your match | /challenges/{{request_id}} | Challenge accepted | — | ["inapp", "push"] | — | True | — |
| match.challenge.cancelled | x | week | neutral | match | True | normal | notifications_push | Your match against {{opponent_name}} was cancelled | /challenges/{{request_id}} | Match cancelled | — | ["inapp", "push"] | — | True | — |
| match.challenge.countered | bat | now | brand | match | True | high | notifications_push | {{opponent_name}} proposed new terms — tap to review | /challenges/{{request_id}} | Counter-offer | — | ["inapp", "push"] | — | True | — |
| match.challenge.declined | x | week | neutral | match | True | normal | notifications_push | {{opponent_name}} declined your challenge | /challenges/{{request_id}} | Challenge declined | — | ["inapp", "push"] | — | True | — |
| match.challenge.expired | x | week | neutral | match | True | low | notifications_push | Your challenge expired with no reply | /challenges/{{request_id}} | Challenge expired | — | ["inapp", "push"] | — | True | — |
| match.challenge.received | bat | now | brand | match | True | high | notifications_push | Tap to accept, counter or decline | /challenges/{{request_id}} | {{opponent_name}} challenged you | — | ["inapp", "push"] | — | True | — |
| match.completed | trophy | fyi | achievement | match | True | low | notifications_push | {{team_name}} vs {{opponent_name}} has finished | /matches/{{match_id}}/summary | Result is in | — | ["inapp", "push"] | — | True | — |
| match.official.assigned | shield | week | neutral | match | True | normal | notifications_push | You were appointed {{role_name}} for an upcoming match | /matches/{{match_id}} | You have been appointed | — | ["inapp", "push"] | — | True | — |
| match.scorer.assigned | bat | now | brand | match | True | high | notifications_push | You were assigned as scorer for {{team_name}} vs {{opponent_name}} | /matches/{{match_id}} | You are scoring this match | — | ["inapp", "push"] | — | True | — |
| match.starting | bat | now | brand | match | True | high | notifications_push | {{team_name}} vs {{opponent_name}} is about to begin | /matches/{{match_id}} | Your match is starting | — | ["inapp", "push"] | — | True | — |
| match.upcoming | calendar | week | neutral | match | True | normal | notifications_push | {{team_name}} vs {{opponent_name}} is scheduled soon | /matches/{{match_id}} | Match coming up | — | ["inapp", "push"] | — | True | — |
| social.comment.replied | comment | week | neutral | social | True | normal | notifications_push | {{actor_name}} replied to your comment | — | New reply | — | ["inapp", "push"] | — | True | — |
| social.follow | person_add | fyi | neutral | social | True | low | notifications_push | {{actor_name}} started following you | /u/{{actor_username}} | New follower | 24:00:00 | ["inapp", "push"] | social.follow | True | {{count}} people started following you |
| social.mention | at | week | neutral | social | True | normal | notifications_push | {{actor_name}} mentioned you | — | You were mentioned | — | ["inapp", "push"] | — | True | — |
| social.post.commented | comment | week | neutral | social | True | normal | notifications_push | {{actor_name}} commented on your post | — | New comment | 12:00:00 | ["inapp", "push"] | social.post.commented:{{post_id}} | True | {{count}} people commented on your post |
| social.post.liked | heart | fyi | brand | social | True | low | notifications_push | {{actor_name}} liked your post | — | New like | 24:00:00 | ["inapp", "push"] | social.post.liked:{{post_id}} | True | {{count}} people liked your post |
| system.stat.milestone | star | fyi | achievement | system | True | low | notifications_push | {{milestone_text}} | /profile | Career milestone | — | ["inapp", "push"] | — | True | — |
| team.claim.approved | check | now | success | team | True | high | notifications_push | Your claim on a player profile in {{team_name}} was approved | /teams/{{team_id}} | Claim approved | — | ["inapp", "push"] | — | True | — |
| team.claim.declined | x | now | neutral | team | True | normal | notifications_push | Your claim on a player profile in {{team_name}} was declined | /teams/{{team_id}} | Claim declined | — | ["inapp", "push"] | — | True | — |
| team.invitation.received | group | week | neutral | team | True | high | notifications_push | {{actor_name}} invited you to join {{team_name}} | /teams/{{team_id}} | You were invited to a team | — | ["inapp", "push"] | — | True | — |
| team.join.approved | check | week | success | team | True | high | notifications_push | {{team_name}} accepted your request to join | /teams/{{team_id}} | You are in | — | ["inapp", "push"] | — | True | — |
| team.join.declined | x | week | neutral | team | True | normal | notifications_push | {{team_name}} declined your request to join | /teams | Request declined | — | ["inapp", "push"] | — | True | — |
| team.join.requested | person_add | now | neutral | team | True | normal | notifications_push | {{actor_name}} wants to join {{team_name}} | /teams/{{team_id}}/manage | New join request | 24:00:00 | ["inapp", "push"] | team.join.requested:{{team_id}} | True | {{count}} people want to join {{team_name}} |
| team.post.published | group | fyi | neutral | team | True | low | notifications_push_bulk | {{team_name}} posted an update | — | New team post | — | ["inapp", "push"] | — | True | — |
| team.role.granted | shield | week | neutral | team | True | high | notifications_push | You are now {{role_name}} of {{team_name}} | /teams/{{team_id}} | New role | — | ["inapp", "push"] | — | True | — |
| tournament.fixture.published | calendar | week | neutral | tournament | True | normal | notifications_push_bulk | The draw for {{tournament_name}} has been published | /tournaments/{{tournament_id}} | Fixtures are out | — | ["inapp", "push"] | — | True | — |
| tournament.organizer.added | shield | now | neutral | tournament | True | high | notifications_push | You were added as an organizer of {{tournament_name}} | /tournaments/{{tournament_id}}/console | You are now an organizer | — | ["inapp", "push"] | — | True | — |
| tournament.post.published | trophy | fyi | achievement | tournament | True | low | notifications_push_bulk | {{tournament_name}} posted an announcement | /tournaments/{{tournament_id}} | Tournament update | — | ["inapp", "push"] | — | True | — |
| tournament.registration.approved | check | week | success | tournament | True | high | notifications_push | {{team_name}} was accepted into {{tournament_name}} | /tournaments/{{tournament_id}}/register/status | You are in the draw | — | ["inapp", "push"] | — | True | — |
| tournament.registration.declined | x | week | neutral | tournament | True | normal | notifications_push | {{tournament_name}} declined {{team_name}} | /tournaments/{{tournament_id}}/register/status | Registration declined | — | ["inapp", "push"] | — | True | — |
| tournament.registration.requested | trophy | now | achievement | tournament | True | normal | notifications_push | {{team_name}} registered for {{tournament_name}} | /tournaments/{{tournament_id}}/requests | New registration | 12:00:00 | ["inapp", "push"] | tournament.registration:{{tournament_id}} | True | {{count}} teams registered for {{tournament_name}} |

## notification_categories

Seeded configuration from the empty replay. These are definitions, not user fixtures.

| key | name | sort_order | description |
| --- | --- | --- | --- |
| match | Matches | 10 | Challenges, toss, start and results |
| team | Teams | 20 | Invites, join requests, roles and posts |
| tournament | Tournaments | 30 | Registrations, fixtures and announcements |
| chat | Messages | 40 | Direct messages and team chat |
| social | Social | 50 | Follows, likes, comments and mentions |
| system | System | 60 | Milestones and account notices |

## Storage buckets

| Bucket | Public | Maximum bytes | Allowed MIME types |
| --- | --- | --- | --- |
| avatars | True | 5242880 | ["image/jpeg", "image/png", "image/webp"] |
| notification-icons | True | 32768 | ["image/svg+xml"] |
| post-media | True | 10485760 | ["image/jpeg", "image/png", "image/webp"] |
| team-logos | True | 5242880 | ["image/jpeg", "image/png", "image/webp"] |
| tournament-banners | True | 10485760 | ["image/jpeg", "image/png", "image/webp"] |
| tournament-logos | True | 5242880 | ["image/jpeg", "image/png", "image/webp"] |

## Storage policies

| Table | Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- | --- |
| objects | avatars_delete_own_folder | DELETE | ["authenticated"] | ((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)) | — |
| objects | avatars_insert_own_folder | INSERT | ["authenticated"] | — | ((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)) |
| objects | avatars_read_public | SELECT | ["public"] | (bucket_id = 'avatars'::text) | — |
| objects | avatars_update_own_folder | UPDATE | ["authenticated"] | ((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)) | ((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)) |
| objects | post_media_delete_author | DELETE | ["authenticated"] | ((bucket_id = 'post-media'::text) AND is_post_author(((storage.foldername(name))[1])::uuid)) | — |
| objects | post_media_insert_author | INSERT | ["authenticated"] | — | ((bucket_id = 'post-media'::text) AND is_post_author(((storage.foldername(name))[1])::uuid)) |
| objects | post_media_read_public | SELECT | ["public"] | (bucket_id = 'post-media'::text) | — |
| objects | post_media_update_author | UPDATE | ["authenticated"] | ((bucket_id = 'post-media'::text) AND is_post_author(((storage.foldername(name))[1])::uuid)) | ((bucket_id = 'post-media'::text) AND is_post_author(((storage.foldername(name))[1])::uuid)) |
| objects | team_logos_delete_manager | DELETE | ["authenticated"] | ((bucket_id = 'team-logos'::text) AND ( SELECT team_can(((storage.foldername(objects.name))[1])::uuid, 'team.profile.write'::text) AS team_can)) | — |
| objects | team_logos_insert_manager | INSERT | ["authenticated"] | — | ((bucket_id = 'team-logos'::text) AND ( SELECT team_can(((storage.foldername(objects.name))[1])::uuid, 'team.profile.write'::text) AS team_can)) |
| objects | team_logos_read_public | SELECT | ["public"] | (bucket_id = 'team-logos'::text) | — |
| objects | team_logos_update_manager | UPDATE | ["authenticated"] | ((bucket_id = 'team-logos'::text) AND ( SELECT team_can(((storage.foldername(objects.name))[1])::uuid, 'team.profile.write'::text) AS team_can)) | ((bucket_id = 'team-logos'::text) AND ( SELECT team_can(((storage.foldername(objects.name))[1])::uuid, 'team.profile.write'::text) AS team_can)) |
| objects | tournament_banners_read_public | SELECT | ["public"] | (bucket_id = 'tournament-banners'::text) | — |
| objects | tournament_banners_write_organizer | ALL | ["authenticated"] | ((bucket_id = 'tournament-banners'::text) AND is_tournament_organizer(((storage.foldername(name))[1])::uuid)) | ((bucket_id = 'tournament-banners'::text) AND is_tournament_organizer(((storage.foldername(name))[1])::uuid)) |
| objects | tournament_logos_read_public | SELECT | ["public"] | (bucket_id = 'tournament-logos'::text) | — |
| objects | tournament_logos_write_organizer | ALL | ["authenticated"] | ((bucket_id = 'tournament-logos'::text) AND is_tournament_organizer(((storage.foldername(name))[1])::uuid)) | ((bucket_id = 'tournament-logos'::text) AND is_tournament_organizer(((storage.foldername(name))[1])::uuid)) |

## Realtime authorization policies

| Table | Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- | --- |
| messages | realtime_join_authorized | SELECT | ["authenticated"] | ((extension = 'broadcast'::text) AND (((split_part(( SELECT realtime.topic() AS topic), ':'::text, 1) = 'user'::text) AND (split_part(( SELECT realtime.topic() AS topic), ':'::text, 2) = (( SELECT auth.uid() AS uid))::text)) OR (split_part(( SELECT realtime.topic() AS topic), ':'::text, 1) = 'match'::text) OR (split_part(( SELECT realtime.topic() AS topic), ':'::text, 1) = 'tournament'::text) OR (split_part(( SELECT realtime.topic() AS topic), ':'::text, 1) = 'post'::text) OR ((split_part(( SELECT realtime.topic() AS topic), ':'::text, 1) = 'chat'::text) AND is_chat_member(_try_topic_uuid(( SELECT realtime.topic() AS topic), 2))))) | — |
| messages | realtime_send_typing_self | INSERT | ["authenticated"] | — | ((extension = 'broadcast'::text) AND (split_part(( SELECT realtime.topic() AS topic), ':'::text, 1) = 'chat'::text) AND (split_part(( SELECT realtime.topic() AS topic), ':'::text, 3) = 'typing'::text) AND is_chat_member(_try_topic_uuid(( SELECT realtime.topic() AS topic), 2))) |

## Scheduled jobs

| Name | Schedule | Active | Command |
| --- | --- | --- | --- |
| abandon_stale_matches | 7 * * * * | True | select public.abandon_stale_matches(); |
| expire_stale_match_requests | */15 * * * * | True | select public.expire_stale_match_requests(); |
| notification-push-worker | * * * * * | True | select public.wake_notification_worker(); |

## Publication membership

| Publication | Table | Row filter |
| --- | --- | --- |
| supabase_realtime | match_deliveries | — |
| supabase_realtime | match_innings_state | — |
| supabase_realtime | match_wickets | — |
| supabase_realtime | matches | — |
| supabase_realtime | posts | — |
| supabase_realtime | team_members | — |
| supabase_realtime | teams | — |
| supabase_realtime | unclaimed_players | — |
