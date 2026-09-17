-- =============================================================================
-- 0803 · channel_role_permissions — role capability mappings
-- =============================================================================

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
