-- =============================================================================
-- Migration: 20260101000489_notification_icons.sql
-- =============================================================================

-- Admin-owned presentation assets. Paths are immutable within a version.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.notification_icons (
  key            text primary key check (key ~ '^[a-z_]+$'),
  storage_path   text not null unique
    check (storage_path ~ '^v[0-9]+/[a-z0-9-]+[.]svg$'),
  source_library text not null,
  source_version text not null,
  license        text not null,
  sha256         text not null check (sha256 ~ '^[0-9a-f]{64}$')
);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.notification_icons enable row level security;

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on public.notification_icons from anon, authenticated;

grant select on public.notification_icons to anon, authenticated;

grant all on public.notification_icons to service_role;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy notification_icons_read_all
  on public.notification_icons
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Data changes
-- -----------------------------------------------------------------------------

insert into public.notification_icons
  (key, storage_path, source_library, source_version, license, sha256)
values
  (
    'bat',
    'v1/cricket.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '7b319a3f7f327d3522aeafd9b6e26788293ad58012feffcea7bcca6121bb0202'
  ),
  (
    'trophy',
    'v1/trophy.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '2e56bd8f0e6f4d2ca4554485acc11717bb05a040d8a296fe2fb029781f4dad21'
  ),
  (
    'calendar',
    'v1/calendar-event.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '63ea485308307c968964cd6f5d9b80f91418efd3f15a2cc4f04535e7aa322076'
  ),
  (
    'check',
    'v1/circle-check.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '60bb8534e78f5db10f1425170cfe03245ae369a1a3e788414319528f6d06cf76'
  ),
  (
    'x',
    'v1/circle-x.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    'fa43bcb8692d0ee40ee973ba6251ec6ec9764038ed67eb480efaceff0ee294cf'
  ),
  (
    'shield',
    'v1/shield-check.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '9c3d5fac4793c7df5b3f2418037f16cd2bb7ba217ca5ee619e17b715b2720364'
  ),
  (
    'group',
    'v1/users-group.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '2d196e620662a694bf579893db6a4d3b42557a2a6484174fe46029f2bcbae731'
  ),
  (
    'person_add',
    'v1/user-plus.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '323581c2b92f94b7b69622bf4a04385405733fdf80e6377ea6b034cc4087e231'
  ),
  (
    'heart',
    'v1/heart.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    'f9f42a4d4ae0aca8f01dde4a7a255eff7af26ed0ee133b1458e9d3ff257464d6'
  ),
  (
    'comment',
    'v1/message-circle.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '9aa5a223a418736c972ff2f6759dceed9f4c73830d20e504a8c7228d74995a3d'
  ),
  (
    'at',
    'v1/at.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    'd35ec9665080ced80faeecfc99c3d28ac13275f211a36a10898951cdab641e2e'
  ),
  (
    'message',
    'v1/messages.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '950a6f078776c767cf6094f194fa53bc576bcb207c0a817a7a77b3353c20cdee'
  ),
  (
    'star',
    'v1/star.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '33727ef0a469dbe7147e5cfe5a875a28b97809b0eac99a2e6886679369d43934'
  ),
  (
    'bell',
    'v1/bell.svg',
    'tabler-outline',
    '55f87a73f45cf1d9eaf16d7da705065483a9e4f9',
    'MIT',
    '470d39082cfbf44f0b4b0588d8f9f1fd2c211b09dc60d0304e91a24a3aeef32e'
  );

-- -----------------------------------------------------------------------------
-- Integrations
-- -----------------------------------------------------------------------------

-- Public artwork, no client uploads. Upload through the trusted asset script.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('notification-icons', 'notification-icons', true, 32768, array['image/svg+xml'])
on conflict (id) do nothing;
