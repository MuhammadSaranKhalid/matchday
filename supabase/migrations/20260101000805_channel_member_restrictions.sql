-- =============================================================================
-- 0805 · channel_member_restrictions — moderation mutes and bans
-- =============================================================================

create table public.channel_member_restrictions (
  restriction_id             uuid primary key default gen_random_uuid(),
  channel_id                 uuid not null,
  user_id                    uuid not null,
  permission                 public.chat_permission not null,
  imposed_by                 uuid not null references public.profiles(user_id),
  reason                     text,
  starts_at                  timestamptz not null default now(),
  expires_at                 timestamptz,
  revoked_at                 timestamptz,
  revoked_by                 uuid references public.profiles(user_id),
  created_at                 timestamptz not null default now(),
  foreign key (channel_id, user_id)
    references public.channel_members(channel_id, user_id)
    on delete cascade
);

create index channel_member_restrictions_lookup_idx
  on public.channel_member_restrictions(channel_id, user_id, permission)
  where revoked_at is null;

alter table public.channel_member_restrictions enable row level security;
