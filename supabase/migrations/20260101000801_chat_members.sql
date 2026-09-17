-- =============================================================================
-- 0801 · channel_members, policies, permissions, and restrictions
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. channel_members
-- -----------------------------------------------------------------------------
create table public.channel_members (
  channel_id                 uuid not null
                               references public.chat_channels(channel_id) on delete cascade,
  user_id                    uuid not null
                               references public.profiles(user_id) on delete cascade,
  role                       public.chat_member_role not null default 'member',
  status                     public.chat_member_status not null default 'active',

  invited_by                 uuid references public.profiles(user_id) on delete set null,
  invited_at                 timestamptz,
  responded_at               timestamptz,
  joined_at                  timestamptz,
  left_at                    timestamptz,
  request_retry_after        timestamptz,

  last_delivered_message_seq bigint,
  last_delivered_at          timestamptz,
  last_read_message_seq      bigint,
  last_read_at               timestamptz,

  notifications_muted_until  timestamptz,
  archived_at                timestamptz,
  pinned_at                  timestamptz,

  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now(),

  primary key (channel_id, user_id)
);

create index channel_members_user_inbox_idx
  on public.channel_members(user_id, status, archived_at, pinned_at);

create index channel_members_channel_status_idx
  on public.channel_members(channel_id, status);

create trigger channel_members_set_updated_at
  before update on public.channel_members
  for each row execute function public.set_updated_at();

alter table public.channel_members enable row level security;

-- -----------------------------------------------------------------------------
-- 2. channel_membership_periods
-- -----------------------------------------------------------------------------
create table public.channel_membership_periods (
  period_id                  uuid primary key default gen_random_uuid(),
  channel_id                 uuid not null
                               references public.chat_channels(channel_id) on delete cascade,
  user_id                    uuid not null
                               references public.profiles(user_id) on delete cascade,
  joined_at                  timestamptz not null,
  left_at                    timestamptz,
  end_reason                 text,
  created_at                 timestamptz not null default now()
);

create unique index channel_membership_period_active_unique
  on public.channel_membership_periods(channel_id, user_id)
  where left_at is null;

create index channel_membership_period_history_idx
  on public.channel_membership_periods(channel_id, joined_at, left_at);

alter table public.channel_membership_periods enable row level security;

-- -----------------------------------------------------------------------------
-- 3. channel_role_permissions
-- -----------------------------------------------------------------------------
create table public.channel_role_permissions (
  role                       public.chat_member_role not null,
  permission                 public.chat_permission not null,
  primary key (role, permission)
);

alter table public.channel_role_permissions enable row level security;

insert into public.channel_role_permissions (role, permission) values
  -- Owner
  ('owner', 'view_channel'),
  ('owner', 'send_messages'),
  ('owner', 'send_media'),
  ('owner', 'add_reactions'),
  ('owner', 'reply_to_messages'),
  ('owner', 'edit_own_messages'),
  ('owner', 'delete_own_messages'),
  ('owner', 'delete_any_message'),
  ('owner', 'pin_messages'),
  ('owner', 'invite_members'),
  ('owner', 'remove_members'),
  ('owner', 'restrict_members'),
  ('owner', 'manage_roles'),
  ('owner', 'manage_channel'),
  ('owner', 'delete_channel'),
  ('owner', 'view_member_receipts'),

  -- Admin
  ('admin', 'view_channel'),
  ('admin', 'send_messages'),
  ('admin', 'send_media'),
  ('admin', 'add_reactions'),
  ('admin', 'reply_to_messages'),
  ('admin', 'edit_own_messages'),
  ('admin', 'delete_own_messages'),
  ('admin', 'delete_any_message'),
  ('admin', 'pin_messages'),
  ('admin', 'invite_members'),
  ('admin', 'remove_members'),
  ('admin', 'restrict_members'),
  ('admin', 'manage_roles'),
  ('admin', 'manage_channel'),
  ('admin', 'view_member_receipts'),

  -- Moderator
  ('moderator', 'view_channel'),
  ('moderator', 'send_messages'),
  ('moderator', 'send_media'),
  ('moderator', 'add_reactions'),
  ('moderator', 'reply_to_messages'),
  ('moderator', 'edit_own_messages'),
  ('moderator', 'delete_own_messages'),
  ('moderator', 'delete_any_message'),
  ('moderator', 'pin_messages'),
  ('moderator', 'restrict_members'),
  ('moderator', 'view_member_receipts'),

  -- Member
  ('member', 'view_channel'),
  ('member', 'send_messages'),
  ('member', 'send_media'),
  ('member', 'add_reactions'),
  ('member', 'reply_to_messages'),
  ('member', 'edit_own_messages'),
  ('member', 'delete_own_messages'),
  ('member', 'view_member_receipts')
on conflict do nothing;

-- -----------------------------------------------------------------------------
-- 4. channel_policies
-- -----------------------------------------------------------------------------
create table public.channel_policies (
  channel_id                 uuid primary key
                               references public.chat_channels(channel_id) on delete cascade,
  posting_mode               public.chat_posting_mode not null default 'members',
  reactions_enabled          boolean not null default true,
  replies_enabled            boolean not null default true,
  media_enabled              boolean not null default true,
  read_receipts_enabled      boolean not null default true,
  delivery_receipts_enabled  boolean not null default true,
  max_message_length         integer not null default 4000,
  slow_mode_seconds          integer not null default 0,
  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now(),
  constraint channel_policy_lengths check (
    max_message_length between 1 and 20000
    and slow_mode_seconds between 0 and 86400
  )
);

create trigger channel_policies_set_updated_at
  before update on public.channel_policies
  for each row execute function public.set_updated_at();

alter table public.channel_policies enable row level security;

-- -----------------------------------------------------------------------------
-- 5. channel_member_restrictions
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 6. Central Predicate Functions
-- -----------------------------------------------------------------------------
create or replace function public.is_chat_member(p_channel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from public.channel_members cm
     where cm.channel_id = p_channel_id
       and cm.user_id = (select auth.uid())
       and cm.status in ('active', 'pending')
  );
$$;

revoke all on function public.is_chat_member(uuid) from public;
grant execute on function public.is_chat_member(uuid) to authenticated;

create or replace function private.has_channel_permission(
  p_user_id uuid,
  p_channel_id uuid,
  p_permission public.chat_permission
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.chat_member_role;
  v_status public.chat_member_status;
  v_context public.chat_channel_context;
  v_team_id uuid;
  v_match_id uuid;
  v_posting_mode public.chat_posting_mode;
  v_has_role_perm boolean := false;
  v_is_restricted boolean := false;
begin
  if p_user_id is null or p_channel_id is null then
    return false;
  end if;

  -- 1. Check channel membership
  select cm.role, cm.status, cc.context_type, cc.team_id, cc.match_id, cp.posting_mode
    into v_role, v_status, v_context, v_team_id, v_match_id, v_posting_mode
    from public.channel_members cm
    join public.chat_channels cc on cc.channel_id = cm.channel_id
    left join public.channel_policies cp on cp.channel_id = cc.channel_id
   where cm.channel_id = p_channel_id
     and cm.user_id = p_user_id;

  if v_status is null or v_status not in ('active', 'pending') then
    return false;
  end if;

  -- Pending members can only view_channel (e.g. preview DM request)
  if v_status = 'pending' then
    return (p_permission = 'view_channel');
  end if;

  -- 2. Base channel-role capability
  select exists (
    select 1 from public.channel_role_permissions crp
     where crp.role = v_role
       and crp.permission = p_permission
  ) into v_has_role_perm;

  -- 3. Check domain authority if entity-owned
  if not v_has_role_perm and v_context = 'team' and v_team_id is not null then
    if exists (
      select 1 from public.team_members tm
       where tm.team_id = v_team_id
         and tm.user_id = p_user_id
         and tm.status = 'active'
    ) then
      if p_permission in ('view_channel', 'send_messages', 'send_media', 'add_reactions', 'reply_to_messages', 'edit_own_messages', 'delete_own_messages', 'view_member_receipts') then
        v_has_role_perm := true;
      end if;
    end if;
  end if;

  if not v_has_role_perm then
    return false;
  end if;

  -- 4. Channel-wide policy check for send_messages
  if p_permission in ('send_messages', 'send_media') and v_posting_mode is not null then
    if v_posting_mode = 'owner' and v_role <> 'owner' then
      return false;
    elsif v_posting_mode = 'admins' and v_role not in ('owner', 'admin') then
      return false;
    elsif v_posting_mode = 'moderators' and v_role not in ('owner', 'admin', 'moderator') then
      return false;
    end if;
  end if;

  -- 5. Active member restriction (deny)
  select exists (
    select 1 from public.channel_member_restrictions cmr
     where cmr.channel_id = p_channel_id
       and cmr.user_id = p_user_id
       and cmr.permission = p_permission
       and cmr.starts_at <= now()
       and cmr.revoked_at is null
       and (cmr.expires_at is null or cmr.expires_at > now())
  ) into v_is_restricted;

  if v_is_restricted then
    return false;
  end if;

  return true;
end;
$$;

revoke all on function private.has_channel_permission(uuid, uuid, public.chat_permission) from public;
grant execute on function private.has_channel_permission(uuid, uuid, public.chat_permission) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 7. RLS Policies
-- -----------------------------------------------------------------------------
-- chat_channels RLS
create policy "chat_channels_read_members_or_public"
  on public.chat_channels for select
  to authenticated
  using (
    visibility = 'public'
    or public.is_chat_member(channel_id)
  );

-- channel_members RLS
create policy "channel_members_read_self_or_channel"
  on public.channel_members for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_chat_member(channel_id)
  );

-- channel_policies RLS
create policy "channel_policies_read_members"
  on public.channel_policies for select
  to authenticated
  using (
    public.is_chat_member(channel_id)
    or exists (
      select 1 from public.chat_channels cc
       where cc.channel_id = channel_policies.channel_id
         and cc.visibility = 'public'
    )
  );

-- channel_role_permissions RLS
create policy "channel_role_permissions_read_all"
  on public.channel_role_permissions for select
  to authenticated
  using (true);

-- channel_member_restrictions RLS
create policy "channel_member_restrictions_read_members"
  on public.channel_member_restrictions for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_chat_member(channel_id)
  );

-- channel_membership_periods RLS
create policy "channel_membership_periods_read_members"
  on public.channel_membership_periods for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_chat_member(channel_id)
  );
