-- Migration file: 20260101000510_posts.sql

-- 0510 · posts
-- Spec §6.5, §6.11, §6.18, §8.2.6. Feature 6 (Posts, Feed, Following).
--
-- Author context (§6.5):
--   author_id is always the human who wrote the post. author_context tells
--   us whose voice the post speaks in:
--     personal              — first-person; context_entity_id is null.
--     team_manager          — speaks for a team; context_entity_id = team_id.
--     tournament_organizer  — speaks for a tournament; context_entity_id =
--                              tournament_id.
--   The polymorphic context_entity_id can't be a real FK (two possible
--   targets); RLS uses can_act_for_post_context() instead to authorize the
--   write. Cleanup of dangling posts when a team/tournament is deleted is a
--   v1.1 task (today such posts just stop resolving in the UI).
--
-- Counts:
--   likes_count / comments_count / shares_count are denormalized. The
--   bump_post_likes_count + bump_post_comments_count triggers (declared in
--   0530 / 0520 with the source tables) keep them in sync. Reads must
--   never compute these on the fly.
--
-- Storage: post-media bucket lives here. Folder convention <post_id>/. RLS
-- requires the post row to exist with author_id=auth.uid() before media
-- upload — clients must INSERT first, upload second.
-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.
-- §6.5 author context.
-- §6.6 MVP types only — auto types (match_result, milestone_achievement,
-- team_roster_change) ship in v1.1 with the auto-generation Edge Function.
-- §6.5 visibility. FollowersOnly is v1.2 (private accounts).
-- §6.5 status — soft-delete posture mirrors balls (preserve audit trail).
-- posts table.

-- Section: Tables and constraints

create table public.posts(
  post_id              uuid primary key default gen_random_uuid(),
  author_id            uuid not null references public.profiles(user_id) on delete cascade,
  author_context       public.post_author_context not null default 'personal',
  -- For team_manager / tournament_organizer this is team_id / tournament_id.
  -- Polymorphic so no real FK; consistency enforced via CHECK + RLS predicate.
  context_entity_id    uuid,
  post_type            public.post_type not null,
  text                 text check (text is null or length(text) <= 2000),
  -- Up to 4 media URLs per spec §6.5. Legacy "URLs only" column; kept in
  -- sync with `media` below for clients that haven't migrated to the
  -- richer shape.
  media_urls           text[] not null default '{}' check (cardinality(media_urls) <= 4),
  -- Per-image metadata for instant blur placeholders and reserved layout
  -- space before the image loads. One object per image:
  --   [{ "url": "...", "blurhash": "LEHV6n...", "width": 1080, "height": 1350 }]
  -- The client computes blurhash + width/height locally (from the
  -- resized image) and writes BOTH `media` (rich) and `media_urls`
  -- (URLs) at insert. Cap at 4 to match media_urls.
  media                jsonb not null default '[]'::jsonb constraint posts_media_shape check (jsonb_typeof(media) = 'array' and jsonb_array_length(media) <= 4),
  linked_match_id      uuid references public.matches(match_id) on delete set null,
  linked_tournament_id uuid references public.tournaments(tournament_id) on delete set null,
  linked_team_id       uuid references public.teams(team_id) on delete set null,
  -- Tagged players (§6.12). Claimed users only for MVP.
  linked_player_ids    uuid[] not null default '{}',
  auto_generated       boolean not null default false,
  visibility           public.post_visibility not null default 'public',
  is_pinned            boolean not null default false, -- §6.17
  -- Denormalized counters maintained by triggers in 0520 / 0530.
  likes_count          integer not null default 0 check (likes_count >= 0),
  comments_count       integer not null default 0 check (comments_count >= 0),
  shares_count         integer not null default 0 check (shares_count >= 0),
  status               public.post_status not null default 'active',
  created_at           timestamptz not null default now(),
  edited_at            timestamptz,
  updated_at           timestamptz not null default now(),
  -- Personal posts have no context entity; entity-context posts must point
  -- at one. The matching FK existence is enforced by RLS + application code.
  constraint post_author_context_consistency check ((author_context = 'personal' and context_entity_id is null) or (author_context = 'team_manager' and context_entity_id is not null) or (author_context = 'tournament_organizer' and context_entity_id is not null)),
  -- Photo posts must carry at least one media entry (in EITHER column —
  -- supports clients that only write media_urls and clients that write
  -- the richer `media` jsonb). Otherwise non-empty text is required.
  constraint post_has_content check ((post_type = 'photo' and (cardinality(media_urls) >= 1 or jsonb_array_length(media) >= 1)) or (text is not null and length(trim(text)) > 0))
);

comment on column public.posts.media is 'Per-image metadata [{url, blurhash, width, height}], max 4. Supersedes media_urls (kept in sync for compatibility).';

-- Section: Indexes

create index posts_author_created on public.posts(author_id, created_at desc);

create index posts_status_created on public.posts(status, created_at desc)
where
  status = 'active';

create index posts_linked_match on public.posts(linked_match_id)
where
  linked_match_id is not null;

create index posts_linked_tournament on public.posts(linked_tournament_id)
where
  linked_tournament_id is not null;

create index posts_linked_team on public.posts(linked_team_id)
where
  linked_team_id is not null;

create index posts_linked_players_gin on public.posts using gin(linked_player_ids);

create index posts_context_entity on public.posts(context_entity_id)
where
  context_entity_id is not null;

-- Section: Triggers

create trigger posts_set_updated_at
  before update on public.posts for each row
  execute function public.set_updated_at();

-- Section: Functions

-- stamp_post_edited_at — sets edited_at when a user edits text/media.
-- (Counter triggers should NOT bump edited_at, so we look only at human-
-- editable columns.)
create or replace function public.stamp_post_edited_at()
  returns trigger
  language plpgsql
  set search_path = public, pg_temp
  as $$
begin
  if new.text is distinct from old.text or new.media_urls is distinct from old.media_urls or new.linked_player_ids is distinct from old.linked_player_ids then
    new.edited_at = now();
  end if;
  return new;
end;
$$;

-- Section: Triggers (continued)

create trigger posts_stamp_edited_at
  before update on public.posts for each row
  execute function public.stamp_post_edited_at();

-- Section: Functions (continued)

-- is_post_author — used by post-media storage RLS + comments policies.
create or replace function public.is_post_author(
  p_post_id uuid
)
  returns boolean
  language sql
  stable
  security definer
  set search_path = public, pg_temp
  as $$
  select
    exists(
      select
        1
      from
        public.posts p
      where
        p.post_id = p_post_id
        and p.author_id = auth.uid());
$$;

revoke all on function public.is_post_author(uuid) from public;

grant execute on function public.is_post_author(uuid) to authenticated;

-- can_act_for_post_context — combines is_team_manager / is_tournament_organizer
-- so the posts INSERT/UPDATE policy can authorize "post as <entity>" cleanly.
create or replace function public.can_act_for_post_context(
  p_author_context public.post_author_context,
  p_entity_id uuid
)
  returns boolean
  language sql
  stable
  security definer
  set search_path = public, pg_temp
  as $$
  select
    case p_author_context
    when 'personal' then
      true
    when 'team_manager' then
      public.is_team_manager(p_entity_id)
    when 'tournament_organizer' then
      public.is_tournament_organizer(p_entity_id)
    end;
$$;

revoke all on function public.can_act_for_post_context(public.post_author_context, uuid) from public;

grant execute on function public.can_act_for_post_context(public.post_author_context, uuid) to authenticated;

-- Section: Enable row-level security

-- RLS — public read of active posts; author or context-manager writes.
alter table public.posts enable row level security;

-- Section: Policies

create policy "posts_read_public" on public.posts
  for select to anon, authenticated
  using (status = 'active'
    or (
      select
        auth.uid()) = author_id);

create policy "posts_insert_self_or_manager" on public.posts
  for insert to authenticated
  with check ((
    select
      auth.uid()) = author_id
      and public.can_act_for_post_context(author_context, context_entity_id));

create policy "posts_update_author_or_manager" on public.posts
  for update to authenticated
  using ((
    select
      auth.uid()) = author_id
      or public.can_act_for_post_context(author_context, context_entity_id))
  with check ((
    select
      auth.uid()) = author_id
      or public.can_act_for_post_context(author_context, context_entity_id));

create policy "posts_delete_author_or_manager" on public.posts
  for delete to authenticated
  using ((
    select
      auth.uid()) = author_id
      or public.can_act_for_post_context(author_context, context_entity_id));

-- Section: Integrations

-- Storage: post-media bucket (10 MB cap, photos only in MVP).
-- Public read; insert/update/delete restricted to the post's author.
-- The composer must INSERT the post row BEFORE uploading media so
-- is_post_author() resolves true.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
  values ('post-media', 'post-media', true, 10 * 1024 * 1024, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id)
  do nothing;

-- Section: Policies (continued)

create policy "post_media_read_public" on storage.objects
  for select
  using (bucket_id = 'post-media');

create policy "post_media_insert_author" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'post-media'
  and public.is_post_author(((storage.foldername(name))[1])::uuid));

create policy "post_media_update_author" on storage.objects
  for update to authenticated
  using (bucket_id = 'post-media'
    and public.is_post_author(((storage.foldername(name))[1])::uuid))
  with check (bucket_id = 'post-media'
  and public.is_post_author(((storage.foldername(name))[1])::uuid));

create policy "post_media_delete_author" on storage.objects
  for delete to authenticated
  using (bucket_id = 'post-media'
    and public.is_post_author(((storage.foldername(name))[1])::uuid));
